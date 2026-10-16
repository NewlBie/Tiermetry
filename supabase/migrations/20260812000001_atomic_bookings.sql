-- Function to get available service units for a given service and time range
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
      select 1
      from public.booking_items bi
      join public.bookings b on bi.booking_id = b.id
      where bi.service_unit_id = su.id
        and b.status in ('pending', 'confirmed')
        and b.start_time < p_end_time
        and b.end_time > p_start_time
    );
end;
$$ language plpgsql security definer;

-- Atomic function to create a booking and its items with conflict prevention
create or replace function public.create_booking_atomic(
  p_venue_id uuid,
  p_start_time timestamp with time zone,
  p_end_time timestamp with time zone,
  p_total_amount numeric,
  p_service_unit_ids uuid[]
) returns uuid as $$
declare
  v_booking_id uuid;
  v_unit_id uuid;
  v_conflict_count integer;
begin
  -- 1. Validate authentication
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- 2. Explicitly lock service units to prevent race conditions
  -- FOR UPDATE prevents other transactions from locking or modifying these rows
  perform 1 from public.service_units
  where id = any(p_service_unit_ids)
  for update;

  -- 3. Check for overlapping bookings (Conflict Prevention)
  -- Semantic: [start, end) intersects [p_start, p_end) if (start < p_end) and (end > p_start)
  select count(*) into v_conflict_count
  from public.booking_items bi
  join public.bookings b on bi.booking_id = b.id
  where bi.service_unit_id = any(p_service_unit_ids)
    and b.status in ('pending', 'confirmed')
    and b.start_time < p_end_time
    and b.end_time > p_start_time;

  if v_conflict_count > 0 then
    raise exception 'One or more selected rigs are no longer available for this time period.';
  end if;

  -- 4. Create the booking record
  insert into public.bookings (
    user_id,
    venue_id,
    start_time,
    end_time,
    total_amount,
    status
  )
  values (
    auth.uid(),
    p_venue_id,
    p_start_time,
    p_end_time,
    p_total_amount,
    'pending'
  )
  returning id into v_booking_id;

  -- 5. Create booking items for each unit
  foreach v_unit_id in array p_service_unit_ids loop
    insert into public.booking_items (
      booking_id,
      service_unit_id,
      price_at_booking
    )
    select
      v_booking_id,
      v_unit_id,
      price
    from public.service_units
    where id = v_unit_id;
  end loop;

  return v_booking_id;
end;
$$ language plpgsql security definer;

-- Add index to booking_items for performance
create index if not exists idx_booking_items_unit_id on public.booking_items(service_unit_id);
create index if not exists idx_bookings_time_range on public.bookings(start_time, end_time);
create index if not exists idx_bookings_status on public.bookings(status);
