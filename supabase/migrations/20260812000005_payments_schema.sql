-- 1. Create payments table
create table public.payments (
  id uuid default gen_random_uuid() primary key,
  booking_id uuid references public.bookings on delete cascade, -- Nullable for new hold flow
  hold_id uuid references public.reservation_holds on delete cascade, -- Link to the hold
  order_id text unique not null,
  amount numeric not null,
  status text default 'created' check (status in ('created', 'pending', 'paid', 'failed', 'cancelled')),
  provider text not null,
  method text,
  raw_response jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Enable RLS
alter table public.payments enable row level security;

-- 3. RLS Policies for payments
create policy "Users can view their own payments"
  on public.payments for select
  using (
    exists (
      select 1 from public.reservation_holds
      where public.reservation_holds.id = hold_id
      and public.reservation_holds.user_id = auth.uid()
    )
    or
    exists (
      select 1 from public.bookings
      where public.bookings.id = booking_id
      and public.bookings.user_id = auth.uid()
    )
  );

create policy "Users can initiate their own payments"
  on public.payments for insert
  with check (
    exists (
      select 1 from public.reservation_holds
      where public.reservation_holds.id = hold_id
      and public.reservation_holds.user_id = auth.uid()
    )
  );

-- 4. AUTHORITATIVE Payment Verification RPC
-- This is the sole pathway for marking a payment as 'paid' and converting the hold.
create or replace function public.process_successful_payment(p_order_id text)
returns void as $$
declare
  v_hold_id uuid;
  v_user_id uuid;
  v_payment_status text;
  v_provider text;
  v_booking_id uuid;
begin
  -- 1. Lock payment and related hold
  select p.hold_id, p.status, rh.user_id, p.provider
  into v_hold_id, v_payment_status, v_user_id, v_provider
  from public.payments p
  join public.reservation_holds rh on p.hold_id = rh.id
  where p.order_id = p_order_id
  for update;

  if v_hold_id is null then
    raise exception 'Order ID % or associated hold not found', p_order_id;
  end if;

  -- 2. Idempotency Check
  if v_payment_status = 'paid' then
    return;
  end if;

  -- 3. Security: Environment/Provider Validation
  if v_provider = 'development' then
    if auth.uid() is null or auth.uid() != v_user_id then
      raise exception 'Unauthorized: Development payments can only be confirmed by the hold owner.';
    end if;
  end if;

  -- 4. Atomically transition payment status
  update public.payments
  set status = 'paid', updated_at = now()
  where order_id = p_order_id;

  -- 5. Authoritatively convert hold to booking
  v_booking_id := public._convert_hold_to_booking_internal(v_hold_id);

  -- 6. Link booking to payment for historical reference
  update public.payments
  set booking_id = v_booking_id
  where order_id = p_order_id;

end;
$$ language plpgsql security definer set search_path = public;

-- 5. Audit Triggers
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_payment_updated
  before update on public.payments
  for each row execute procedure public.handle_updated_at();

-- 6. Permissions
revoke all on function public.process_successful_payment(text) from public;
grant execute on function public.process_successful_payment(text) to authenticated, service_role;
