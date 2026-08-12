-- 1. Create events table
create table public.events (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  image text,
  venue_id uuid references public.venues(id) on delete set null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  registration_start timestamp with time zone not null,
  registration_end timestamp with time zone not null,
  max_participants integer,
  registration_type text default 'individual' check (registration_type in ('individual', 'team')),
  status text default 'draft' check (status in ('draft', 'published', 'cancelled', 'completed')),
  cost text default 'Free',
  points integer default 0,
  tags text[] default '{}',
  perks jsonb default '[]',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Create event_registrations table
create table public.event_registrations (
  id uuid default gen_random_uuid() primary key,
  event_id uuid references public.events(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  status text default 'registered' check (status in ('registered', 'attended', 'cancelled')),
  registered_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(event_id, user_id) -- Prevent duplicate registration
);

-- 3. Enable RLS
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;

-- 4. RLS Policies
create policy "Anyone can view published events"
  on public.events for select
  using (status = 'published');

create policy "Users can view their own registrations"
  on public.event_registrations for select
  using (auth.uid() = user_id);

-- 5. Secure Event Registration RPC
create or replace function public.register_for_event(p_event_id uuid)
returns uuid as $$
declare
  v_event record;
  v_registration_id uuid;
  v_current_enrollments integer;
begin
  -- 1. Authentication
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- 2. Lock event and check status/eligibility
  select * into v_event
  from public.events
  where id = p_event_id
  for update;

  if v_event is null then
    raise exception 'Event not found';
  end if;

  if v_event.status != 'published' then
    raise exception 'Registration is not available for this event';
  end if;

  -- 3. Check registration window
  if now() < v_event.registration_start then
    raise exception 'Registration has not opened yet';
  end if;

  if now() > v_event.registration_end then
    raise exception 'Registration has closed';
  end if;

  -- 4. Check capacity
  if v_event.max_participants is not null then
    select count(*) into v_current_enrollments
    from public.event_registrations
    where event_id = p_event_id
      and status = 'registered';

    if v_current_enrollments >= v_event.max_participants then
      raise exception 'Event is full';
    end if;
  end if;

  -- 5. Check for duplicate registration
  if exists (
    select 1 from public.event_registrations
    where event_id = p_event_id
      and user_id = auth.uid()
  ) then
    raise exception 'You are already registered for this event';
  end if;

  -- 6. Create registration
  insert into public.event_registrations (event_id, user_id)
  values (p_event_id, auth.uid())
  returning id into v_registration_id;

  return v_registration_id;
end;
$$ language plpgsql security definer set search_path = public;

-- 6. Permissions
revoke all on function public.register_for_event(uuid) from public;
grant execute on function public.register_for_event(uuid) to authenticated;

-- 7. Add index for performance
create index idx_event_registrations_event_id on public.event_registrations(event_id);
create index idx_event_registrations_user_id on public.event_registrations(user_id);
