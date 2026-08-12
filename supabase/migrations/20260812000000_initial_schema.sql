-- Profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  name text,
  email text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Venues table
create table public.venues (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  address text,
  latitude double precision,
  longitude double precision,
  rating double precision default 0.0,
  review_count integer default 0,
  cover_image text,
  activity text check (activity in ('gaming', 'arcade', 'recreational')),
  short_address text,
  hours text,
  is_open boolean default true,
  price_tier integer default 1,
  is_verified boolean default false,
  internet text,
  amenity text,
  specs jsonb,
  rules text[],
  contact_phone text,
  has_ac boolean default false,
  has_power_backup boolean default false,
  game_library text[],
  cancellation_policy text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Services table
create table public.services (
  id uuid default gen_random_uuid() primary key,
  venue_id uuid references public.venues on delete cascade not null,
  name text not null,
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Service Units table
create table public.service_units (
  id uuid default gen_random_uuid() primary key,
  service_id uuid references public.services on delete cascade not null,
  name text not null,
  description text,
  price numeric not null,
  image text,
  status text default 'available' check (status in ('available', 'maintenance', 'retired')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Bookings table
create table public.bookings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  venue_id uuid references public.venues on delete cascade not null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  status text default 'pending' check (status in ('pending', 'confirmed', 'cancelled', 'completed')),
  total_amount numeric not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Booking Items table
create table public.booking_items (
  id uuid default gen_random_uuid() primary key,
  booking_id uuid references public.bookings on delete cascade not null,
  service_unit_id uuid references public.service_units on delete cascade not null,
  price_at_booking numeric not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.venues enable row level security;
alter table public.services enable row level security;
alter table public.service_units enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_items enable row level security;

-- Policies
create policy "Public venues are viewable by everyone" on public.venues for select using (true);
create policy "Public services are viewable by everyone" on public.services for select using (true);
create policy "Public service units are viewable by everyone" on public.service_units for select using (true);

create policy "Users can view their own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);

create policy "Users can view their own bookings" on public.bookings for select using (auth.uid() = user_id);
create policy "Users can insert their own bookings" on public.bookings for insert with check (auth.uid() = user_id);

create policy "Users can view their own booking items" on public.booking_items for select using (
  exists (
    select 1 from public.bookings
    where public.bookings.id = booking_id
    and public.bookings.user_id = auth.uid()
  )
);
create policy "Users can insert their own booking items" on public.booking_items for insert with check (
  exists (
    select 1 from public.bookings
    where public.bookings.id = booking_id
    and public.bookings.user_id = auth.uid()
  )
);

-- Triggers for profiles
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, new.raw_user_meta_data->>'name', new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
