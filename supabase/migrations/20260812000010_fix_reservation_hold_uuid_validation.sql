-- Patch create_reservation_hold_atomic to fix min(uuid) aggregation error,
-- improve array validation using cardinality(), and reject NULL elements.

create or replace function public.create_reservation_hold_atomic(
  p_venue_id uuid,
  p_start_time timestamp with time zone,
  p_end_time timestamp with time zone,
  p_service_unit_ids uuid[]
) returns uuid as $$
declare
  v_hold_id uuid;
  v_total_amount numeric;
  v_hours numeric;
  v_conflict_count integer;
  v_service_count integer;
  v_unit_count integer;
begin
  -- 1. Authentication
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- 2. Input Validation
  if p_start_time is null or p_end_time is null then
    raise exception 'Start time and end time are required';
  end if;

  if p_end_time <= p_start_time then
    raise exception 'End time must be after start time';
  end if;

  -- Array size and nullability validation
  if p_service_unit_ids is null or cardinality(p_service_unit_ids) = 0 then
    raise exception 'At least one service unit must be selected';
  end if;

  -- Explicitly reject NULL elements inside the array
  if exists (
    select 1
    from unnest(p_service_unit_ids) as id
    where id is null
  ) then
    raise exception 'Service unit IDs cannot contain NULL values';
  end if;

  -- Check for duplicates in input array
  if (select count(distinct id) from unnest(p_service_unit_ids) as id) != cardinality(p_service_unit_ids) then
    raise exception 'Duplicate service unit IDs provided';
  end if;

  v_hours := extract(epoch from (p_end_time - p_start_time)) / 3600;

  -- 3. Resource Validation & Inventory Lock
  -- Lock units and verify existence, venue (via services), and status
  perform 1
  from public.service_units su
  join public.services s on su.service_id = s.id
  where su.id = any(p_service_unit_ids)
    and s.venue_id = p_venue_id
    and su.status = 'available'
  for update;

  -- Ensure all requested units were found, belong to the same venue, and are available
  select
    count(*),
    count(distinct su.service_id)
  into
    v_unit_count,
    v_service_count
  from public.service_units su
  join public.services s on su.service_id = s.id
  where su.id = any(p_service_unit_ids)
    and s.venue_id = p_venue_id
    and su.status = 'available';

  if v_unit_count != cardinality(p_service_unit_ids) then
    raise exception 'One or more units are invalid, belong to another venue, or are not available.';
  end if;

  -- Verify all units belong to exactly one service
  if v_service_count != 1 then
    raise exception 'All units must belong to the same service';
  end if;

  -- 4. Conflict Check (Bookings + Active Holds)
  select count(*) into v_conflict_count
  from (
    select service_unit_id from public.booking_items bi
    join public.bookings b on bi.booking_id = b.id
    where bi.service_unit_id = any(p_service_unit_ids)
      and b.status in ('confirmed', 'pending')
      and b.start_time < p_end_time
      and b.end_time > p_start_time
    union all
    select service_unit_id from public.reservation_hold_items rhi
    join public.reservation_holds rh on rhi.hold_id = rh.id
    where rhi.service_unit_id = any(p_service_unit_ids)
      and rh.status = 'active'
      and rh.expires_at > now()
      and rh.start_time < p_end_time
      and rh.end_time > p_start_time
  ) t;

  if v_conflict_count > 0 then
    raise exception 'One or more selected rigs are no longer available.';
  end if;

  -- 5. Authoritative Pricing (Server-side calculation)
  select sum(price) * v_hours into v_total_amount
  from public.service_units
  where id = any(p_service_unit_ids);

  -- 6. Create Hold
  insert into public.reservation_holds (
    user_id, venue_id, start_time, end_time, total_amount, status, expires_at
  )
  values (
    auth.uid(), p_venue_id, p_start_time, p_end_time, v_total_amount, 'active',
    now() + interval '2 minutes'
  )
  returning id into v_hold_id;

  -- 7. Create Items
  insert into public.reservation_hold_items (hold_id, service_unit_id)
  select v_hold_id, id
  from public.service_units
  where id = any(p_service_unit_ids);

  return v_hold_id;
end;
$$ language plpgsql security definer set search_path = public;
