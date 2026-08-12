-- Seed data for Tiermetry

-- 1. Insert Venues
insert into public.venues (
  name, description, short_address, address, rating, review_count,
  cover_image, activity, hours, internet, amenity, has_ac, has_power_backup, is_verified
) values
(
  'Nexus Gaming Arena',
  'Premium gaming lounge with the latest hardware and professional atmosphere.',
  'Indiranagar, Bangalore',
  '123, 100 Feet Rd, Indiranagar, Bengaluru, Karnataka 560038',
  4.8, 1250,
  'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&q=80&w=2070',
  'gaming', '10:00 AM - 12:00 AM', '1 Gbps Fiber', 'Cafe, Lounge', true, true, true
),
(
  'The Turf Club',
  'State-of-the-art synthetic turf for football and cricket.',
  'Koramangala, Bangalore',
  '45, 80 Feet Rd, Koramangala, Bengaluru, Karnataka 560034',
  4.5, 850,
  'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&q=80&w=2076',
  'recreational', '06:00 AM - 11:00 PM', 'Free Wifi', 'Showers, Parking', false, true, true
);

-- 2. Insert Services
insert into public.services (venue_id, name, description)
select id, 'High-End PC Gaming', 'RTX 4090 rigs with 360Hz monitors'
from public.venues where name = 'Nexus Gaming Arena';

insert into public.services (venue_id, name, description)
select id, 'Console Lounge', 'PS5 and Xbox Series X with 4K OLED screens'
from public.venues where name = 'Nexus Gaming Arena';

insert into public.services (venue_id, name, description)
select id, '5-a-side Football', 'FIFA certified synthetic turf'
from public.venues where name = 'The Turf Club';

-- 3. Insert Service Units (Rigs/Slots)
-- For Nexus PC Gaming
insert into public.service_units (service_id, name, description, price, image, status)
select id, 'Rig Alpha-1', 'RTX 4090 | i9-14900K', 150, 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&q=80&w=1974', 'available'
from public.services where name = 'High-End PC Gaming';

insert into public.service_units (service_id, name, description, price, image, status)
select id, 'Rig Alpha-2', 'RTX 4090 | i9-14900K', 150, 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&q=80&w=1974', 'available'
from public.services where name = 'High-End PC Gaming';

-- For Nexus Console
insert into public.service_units (service_id, name, description, price, image, status)
select id, 'PS5 Booth 1', 'DualSense Edge | 55" OLED', 120, 'https://images.unsplash.com/photo-1606144042614-b2417e99c4e3?auto=format&fit=crop&q=80&w=2070', 'available'
from public.services where name = 'Console Lounge';

-- For Turf Club
insert into public.service_units (service_id, name, description, price, image, status)
select id, 'Main Pitch', 'Full size 5-a-side pitch', 800, 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?auto=format&fit=crop&q=80&w=2070', 'available'
from public.services where name = '5-a-side Football';
