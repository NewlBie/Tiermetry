-- Enable pg_cron extension if not already enabled
-- Note: This requires superuser privileges or being run in a Supabase environment that supports it.
create extension if not exists pg_cron;

-- 1. Update status constraint to include 'expired'
alter table public.bookings
drop constraint if exists bookings_status_check;

alter table public.bookings
add constraint bookings_status_check
check (status in ('pending', 'confirmed', 'cancelled', 'completed', 'expired'));

-- 2. Add expired_at column
alter table public.bookings
add column if not exists expired_at timestamp with time zone;

-- 3. Function to expire abandoned pending bookings
create or replace function public.expire_pending_bookings()
returns void as $$
begin
  update public.bookings
  set
    status = 'expired',
    expired_at = now(),
    updated_at = now()
  where status = 'pending'
    and pending_at < (now() - interval '15 minutes');
end;
$$ language plpgsql security definer;

-- 4. Schedule the expiration job to run every minute
-- We use a unique name so it doesn't duplicate if the migration runs multiple times
select cron.schedule(
  'expire-pending-bookings-job',
  '* * * * *', -- every minute
  'select public.expire_pending_bookings()'
);
