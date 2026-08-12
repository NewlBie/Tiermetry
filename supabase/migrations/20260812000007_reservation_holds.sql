-- 1. Create reservation_holds table
create table public.reservation_holds (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  venue_id uuid references public.venues on delete cascade not null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  total_amount numeric not null,
  status text default 'active' check (status in ('active', 'released', 'expired', 'converted')),
  expires_at timestamp with time zone not null,
  converted_booking_id uuid references public.bookings(id),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Create reservation_hold_items table
create table public.reservation_hold_items (
  id uuid default gen_random_uuid() primary key,
  hold_id uuid references public.reservation_holds on delete cascade not null,
  service_unit_id uuid references public.service_units on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Enable RLS
alter table public.reservation_holds enable row level security;
alter table public.reservation_hold_items enable row level security;

-- 4. RLS Policies
create policy "Users can view their own holds"
  on public.reservation_holds for select
  using (auth.uid() = user_id);

create policy "Users can view their own hold items"
  on public.reservation_hold_items for select
  using (
    exists (
      select 1 from public.reservation_holds
      where public.reservation_holds.id = hold_id
      and public.reservation_holds.user_id = auth.uid()
    )
  );

-- 5. Updated Availability Function (Accounts for both bookings and active holds)
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
      -- Check active reservation holds (ignoring expired, released, or converted ones)
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

-- 6. Atomic Hold Creation
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
  v_service_id uuid;
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
  -- Lock units and verify existence, venue, and status
  perform 1
  from public.service_units
  where id = any(p_service_unit_ids)
    and venue_id = p_venue_id
    and status = 'available'
  for update;

  -- Ensure all requested units were found and belong to the same venue/service
  select count(*), min(service_id), max(service_id)
  into v_unit_count, v_service_id, v_hold_id -- reusing v_hold_id as temporary check
  from public.service_units
  where id = any(p_service_unit_ids)
    and venue_id = p_venue_id
    and status = 'available';

  if v_unit_count != array_length(p_service_unit_ids, 1) then
    raise exception 'One or more units are invalid, belong to another venue, or are not available.';
  end if;

  if v_service_id != (select service_id from public.service_units where id = p_service_unit_ids[1]) then
    -- Note: This check is redundant if we already verified min(service_id) == max(service_id)
    raise exception 'All units must belong to the same service';
  end if;

  -- Redundant but explicit service consistency check
  if v_service_id is null or (select count(distinct service_id) from public.service_units where id = any(p_service_unit_ids)) > 1 then
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

-- 7. Internal Autoritative Hold Conversion
-- This function is private and skips auth checks (should be called by trusted success handlers).
create or replace function public._convert_hold_to_booking_internal(p_hold_id uuid)
returns uuid as $$
declare
  v_hold record;
  v_booking_id uuid;
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

  -- 2. Lock associated service units to prevent race conditions during conversion
  perform 1
  from public.service_units su
  join public.reservation_hold_items rhi on su.id = rhi.service_unit_id
  where rhi.hold_id = p_hold_id
  for update;

  -- Verify hold items exist
  if not exists (select 1 from public.reservation_hold_items where hold_id = p_hold_id) then
    raise exception 'No items found for this hold.';
  end if;

  -- 3. Create Real Booking
  insert into public.bookings (
    user_id, venue_id, start_time, end_time, total_amount, status, confirmed_at
  )
  values (
    v_hold.user_id, v_hold.venue_id, v_hold.start_time, v_hold.end_time,
    v_hold.total_amount, 'confirmed', now()
  )
  returning id into v_booking_id;

  -- 4. Create Booking Items
  insert into public.booking_items (booking_id, service_unit_id, price_at_booking)
  select v_booking_id, rhi.service_unit_id, su.price
  from public.reservation_hold_items rhi
  join public.service_units su on rhi.service_unit_id = su.id
  where rhi.hold_id = p_hold_id;

  -- 5. Mark Hold as Converted
  update public.reservation_holds
  set
    status = 'converted',
    converted_booking_id = v_booking_id,
    updated_at = now()
  where id = p_hold_id;

  return v_booking_id;
end;
$$ language plpgsql security definer set search_path = public;

-- 8. Manual Release RPC
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

-- 9. Background Expiration Task
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

-- 10. Permission Matrix
revoke all on function public.get_available_units(uuid, timestamptz, timestamptz) from public;
grant execute on function public.get_available_units(uuid, timestamptz, timestamptz) to anon, authenticated;

revoke all on function public.create_reservation_hold_atomic(uuid, timestamptz, timestamptz, uuid[]) from public;
grant execute on function public.create_reservation_hold_atomic(uuid, timestamptz, timestamptz, uuid[]) to authenticated;

revoke all on function public.release_reservation_hold(uuid) from public;
grant execute on function public.release_reservation_hold(uuid) to authenticated;

revoke all on function public._convert_hold_to_booking_internal(uuid) from public;
-- NOT granted to anon or authenticated

revoke all on function public.expire_reservation_holds() from public;
-- NOT granted to anon or authenticated

-- 11. Schedule Expiration (Safe idempotent scheduling)
select cron.unschedule('expire-reservation-holds-job');
select cron.schedule(
  'expire-reservation-holds-job',
  '* * * * *', -- every minute
  'select public.expire_reservation_holds()'
);
