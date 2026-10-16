-- Function to cancel a booking with lifecycle enforcement
create or replace function public.cancel_booking(p_booking_id uuid)
returns void as $$
declare
  v_status text;
  v_user_id uuid;
begin
  -- 1. Get current status and owner
  select status, user_id into v_status, v_user_id
  from public.bookings
  where id = p_booking_id;

  -- 2. Validate existence
  if v_user_id is null then
    raise exception 'Booking not found.';
  end if;

  -- 3. Validate ownership
  if v_user_id != auth.uid() then
    raise exception 'Unauthorized.';
  end if;

  -- 4. Enforce state machine transitions
  if v_status = 'cancelled' then
    raise exception 'This booking is already cancelled.';
  end if;

  if v_status = 'completed' then
    raise exception 'Cannot cancel a completed booking.';
  end if;

  -- 5. Perform transition
  update public.bookings
  set
    status = 'cancelled',
    updated_at = now()
  where id = p_booking_id;
end;
$$ language plpgsql security definer;

-- Function to complete a booking (transition confirmed -> completed)
create or replace function public.complete_booking(p_booking_id uuid)
returns void as $$
declare
  v_status text;
  v_user_id uuid;
begin
  select status, user_id into v_status, v_user_id
  from public.bookings
  where id = p_booking_id;

  if v_user_id is null then
    raise exception 'Booking not found.';
  end if;

  if v_user_id != auth.uid() then
    raise exception 'Unauthorized.';
  end if;

  if v_status != 'confirmed' then
    raise exception 'Only confirmed bookings can be marked as completed. Current status: %', v_status;
  end if;

  update public.bookings
  set
    status = 'completed',
    updated_at = now()
  where id = p_booking_id;
end;
$$ language plpgsql security definer;

-- Function to confirm a booking (transition pending -> confirmed)
create or replace function public.confirm_booking(p_booking_id uuid)
returns void as $$
declare
  v_status text;
  v_user_id uuid;
begin
  select status, user_id into v_status, v_user_id
  from public.bookings
  where id = p_booking_id;

  if v_user_id is null then
    raise exception 'Booking not found.';
  end if;

  if v_user_id != auth.uid() then
    raise exception 'Unauthorized.';
  end if;

  if v_status != 'pending' then
    raise exception 'Only pending bookings can be confirmed. Current status: %', v_status;
  end if;

  update public.bookings
  set
    status = 'confirmed',
    updated_at = now()
  where id = p_booking_id;
end;
$$ language plpgsql security definer;
