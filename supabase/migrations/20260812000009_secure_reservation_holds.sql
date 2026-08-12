-- 1. Secure Availability Function
-- Considers confirmed bookings and active, non-expired holds.
create or replace function public.get_available_units(
  p_service_id uuid,
  p_start_time timestamp with time zone,
  p_end_time timestamp with time zone
) returns setof public.service_units as $$
begin
  return query
  select su.*
  from public.service_units su
  where su.service_id = p_service_id
    and su.status = 'available'
    and not exists (
      -- Check confirmed/pending bookings
      select 1
      from public.booking_items bi
      join public.bookings b on bi.booking_id = b.id
      where bi.service_unit_id = su.id
        and b.status in ('confirmed', 'pending')
        and b.start_time < p_end_time
        and b.end_time > p_start_time
    )
    and not exists (
      -- Check active reservation holds
      select 1
      from public.reservation_hold_items rhi
      join public.reservation_holds rh on rhi.hold_id = rh.id
      where rhi.service_unit_id = su.id
        and rh.status = 'active'
        and rh.expires_at > now()
        and rh.start_time < p_end_time
        and rh.end_time > p_start_time
    );
end;
$$ language plpgsql security definer set search_path = public;

-- 2. Atomic Hold Creation with Strict Resource Validation
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

  if p_service_unit_ids is null or array_length(p_service_unit_ids, 1) = 0 then
    raise exception 'At least one service unit must be selected';
  end if;

  -- Check for duplicates in input
  if (select count(distinct id) from unnest(p_service_unit_ids) as id) != array_length(p_service_unit_ids, 1) then
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

  if v_unit_count != array_length(p_service_unit_ids, 1) then
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

-- 3. Secure Internal Hold Conversion
create or replace function public._convert_hold_to_booking_internal(p_hold_id uuid)
returns uuid as $$
declare
  v_hold record;
  v_booking_id uuid;
  v_conflict_count integer;
begin
  -- 1. Lock and Verify Hold
  select * into v_hold
  from public.reservation_holds
  where id = p_hold_id
  for update;

  if v_hold is null then
    raise exception 'Hold not found.';
  end if;

  if v_hold.status != 'active' then
    raise exception 'Hold is no longer active (Status: %).', v_hold.status;
  end if;

  if v_hold.expires_at < now() then
    raise exception 'Hold has expired.';
  end if;

  -- 2. Lock associated service units
  perform 1
  from public.service_units su
  join public.reservation_hold_items rhi on su.id = rhi.service_unit_id
  where rhi.hold_id = p_hold_id
  for update;

  -- 3. Final Inventory Integrity Re-Check
  -- Even though we had a hold, a confirmed booking might have been created by a legacy RPC (if not revoked)
  -- or a manual intervention.
  select count(*) into v_conflict_count
  from public.booking_items bi
  join public.bookings b on bi.booking_id = b.id
  where bi.service_unit_id in (select service_unit_id from public.reservation_hold_items where hold_id = p_hold_id)
    and b.status = 'confirmed'
    and b.start_time < v_hold.end_time
    and b.end_time > v_hold.start_time;

  if v_conflict_count > 0 then
    raise exception 'Inventory conflict detected during conversion. One or more rigs were booked by another process.';
  end if;

  -- 4. Create Real Booking
  insert into public.bookings (
    user_id, venue_id, start_time, end_time, total_amount, status, confirmed_at
  )
  values (
    v_hold.user_id, v_hold.venue_id, v_hold.start_time, v_hold.end_time,
    v_hold.total_amount, 'confirmed', now()
  )
  returning id into v_booking_id;

  -- 5. Create Booking Items
  insert into public.booking_items (booking_id, service_unit_id, price_at_booking)
  select v_booking_id, rhi.service_unit_id, su.price
  from public.reservation_hold_items rhi
  join public.service_units su on rhi.service_unit_id = su.id
  where rhi.hold_id = p_hold_id;

  -- 6. Mark Hold as Converted
  update public.reservation_holds
  set
    status = 'converted',
    converted_booking_id = v_booking_id,
    updated_at = now()
  where id = p_hold_id;

  return v_booking_id;
end;
$$ language plpgsql security definer set search_path = public;

-- 4. Secure Manual Release
create or replace function public.release_reservation_hold(p_hold_id uuid)
returns void as $$
begin
  update public.reservation_holds
  set
    status = 'released',
    updated_at = now()
  where id = p_hold_id
    and user_id = auth.uid()
    and status = 'active';

  if not found then
    raise exception 'Hold not found, not active, or not owned by user.';
  end if;
end;
$$ language plpgsql security definer set search_path = public;

-- 5. Secure Expiration
create or replace function public.expire_reservation_holds()
returns void as $$
begin
  update public.reservation_holds
  set
    status = 'expired',
    updated_at = now()
  where status = 'active'
    and expires_at < now();
end;
$$ language plpgsql security definer set search_path = public;

-- 6. LEGACY BYPASS PROTECTION
-- Update the old create_booking_atomic to check for reservation holds
create or replace function public.create_booking_atomic(
  p_venue_id uuid,
  p_start_time timestamp with time zone,
  p_end_time timestamp with time zone,
  p_service_unit_ids uuid[]
) returns uuid as $$
declare
  v_booking_id uuid;
  v_total_amount numeric;
  v_hours numeric;
  v_conflict_count integer;
begin
  -- 1. Authentication
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- 2. Lock units
  perform 1 from public.service_units where id = any(p_service_unit_ids) for update;

  -- 3. Check for confirmed bookings AND active reservation holds
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
    raise exception 'One or more rigs are unavailable due to a confirmed booking or active hold.';
  end if;

  -- Calculate duration and amount
  v_hours := extract(epoch from (p_end_time - p_start_time)) / 3600;
  select sum(price) * v_hours into v_total_amount
  from public.service_units
  where id = any(p_service_unit_ids);

  -- 4. Create Booking
  insert into public.bookings (user_id, venue_id, start_time, end_time, total_amount, status)
  values (auth.uid(), p_venue_id, p_start_time, p_end_time, v_total_amount, 'pending')
  returning id into v_booking_id;

  -- 5. Create Items
  insert into public.booking_items (booking_id, service_unit_id, price_at_booking)
  select v_booking_id, id, price
  from public.service_units
  where id = any(p_service_unit_ids);

  return v_booking_id;
end;
$$ language plpgsql security definer set search_path = public;

-- 7. Permission Matrix
-- Revoke all by default
revoke all on function public.get_available_units(uuid, timestamptz, timestamptz) from public;
grant execute on function public.get_available_units(uuid, timestamptz, timestamptz) to anon, authenticated;

revoke all on function public.create_reservation_hold_atomic(uuid, timestamptz, timestamptz, uuid[]) from public;
grant execute on function public.create_reservation_hold_atomic(uuid, timestamptz, timestamptz, uuid[]) to authenticated;

revoke all on function public.release_reservation_hold(uuid) from public;
grant execute on function public.release_reservation_hold(uuid) to authenticated;

revoke all on function public._convert_hold_to_booking_internal(uuid) from public;
-- No public/authenticated access

revoke all on function public.expire_reservation_holds() from public;
-- No public/authenticated access

-- Legacy function: Revoke access to force use of the hold-based flow
revoke all on function public.create_booking_atomic(uuid, timestamptz, timestamptz, uuid[]) from public;
-- Access only via service role if needed by backend migration scripts

-- 8. Cron Safety
select cron.unschedule('expire-reservation-holds-job');
select cron.schedule(
  'expire-reservation-holds-job',
  '* * * * *',
  'select public.expire_reservation_holds()'
);
