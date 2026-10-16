-- Redefine create_booking_atomic to calculate total_amount internally
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

  -- 2. Duration Calculation
  v_hours := extract(epoch from (p_end_time - p_start_time)) / 3600;
  if v_hours <= 0 then
    raise exception 'Invalid booking duration';
  end if;

  -- 3. Authoritative Pricing Calculation
  -- Select for update to lock service unit prices during calculation
  perform 1 from public.service_units where id = any(p_service_unit_ids) for update;

  select sum(price) * v_hours into v_total_amount
  from public.service_units
  where id = any(p_service_unit_ids);

  if v_total_amount is null then
    raise exception 'Invalid service units selected';
  end if;

  -- 4. Availability Check
  select count(*) into v_conflict_count
  from public.booking_items bi
  join public.bookings b on bi.booking_id = b.id
  where bi.service_unit_id = any(p_service_unit_ids)
    and b.status in ('pending', 'confirmed')
    and b.start_time < p_end_time
    and b.end_time > p_start_time;

  if v_conflict_count > 0 then
    raise exception 'One or more selected rigs are no longer available.';
  end if;

  -- 5. Create Booking
  insert into public.bookings (
    user_id, venue_id, start_time, end_time, total_amount, status
  )
  values (
    auth.uid(), p_venue_id, p_start_time, p_end_time, v_total_amount, 'pending'
  )
  returning id into v_booking_id;

  -- 6. Create Items
  insert into public.booking_items (booking_id, service_unit_id, price_at_booking)
  select v_booking_id, id, price
  from public.service_units
  where id = any(p_service_unit_ids);

  return v_booking_id;
end;
$$ language plpgsql security definer set search_path = public;
