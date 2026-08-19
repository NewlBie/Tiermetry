-- Add audit timestamps for lifecycle stages
alter table public.bookings
add column if not exists pending_at timestamp with time zone default now(),
add column if not exists confirmed_at timestamp with time zone,
add column if not exists cancelled_at timestamp with time zone,
add column if not exists completed_at timestamp with time zone;

-- Update lifecycle functions to set these timestamps
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
    confirmed_at = now(),
    updated_at = now()
  where id = p_booking_id;
end;
$$ language plpgsql security definer;

create or replace function public.cancel_booking(p_booking_id uuid)
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

  if v_status = 'cancelled' then
    raise exception 'This booking is already cancelled.';
  end if;

  if v_status = 'completed' then
    raise exception 'Cannot cancel a completed booking.';
  end if;

  update public.bookings
  set
    status = 'cancelled',
    cancelled_at = now(),
    updated_at = now()
  where id = p_booking_id;
end;
$$ language plpgsql security definer;

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
    completed_at = now(),
    updated_at = now()
  where id = p_booking_id;
end;
$$ language plpgsql security definer;
