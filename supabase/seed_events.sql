-- Development Seed Data: Events
-- Note: This script assumes at least one venue exists in the database.

DO $$
DECLARE
    v_venue_id uuid;
BEGIN
    -- 1. Fetch an existing venue to link the events
    SELECT id INTO v_venue_id FROM public.venues LIMIT 1;

    IF v_venue_id IS NULL THEN
        RAISE NOTICE 'No venues found. Please seed venues before seeding events.';
        RETURN;
    END IF;

    -- 2. Insert Sample Events
    INSERT INTO public.events (
        title,
        description,
        image,
        venue_id,
        start_time,
        end_time,
        registration_start,
        registration_end,
        max_participants,
        status,
        cost,
        points,
        tags,
        perks
    ) VALUES
    (
        'Valorant Community Clash',
        'Join the local Valorant community for a friendly tournament. All skill levels welcome!',
        'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&q=80&w=800',
        v_venue_id,
        now() + interval '7 days',
        now() + interval '7 days 4 hours',
        now() - interval '1 day',
        now() + interval '6 days',
        32,
        'published',
        '₹200',
        50,
        ARRAY['Valorant', 'Tournament', 'Competitive'],
        '[{"name": "Free Monster", "icon": "fastfood"}, {"name": "Participation Badge", "icon": "stars"}]'::jsonb
    ),
    (
        'Flutter Hackathon 2025',
        'Build the future of gaming apps with Flutter. 24 hours of coding, networking, and swag.',
        'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&q=80&w=800',
        v_venue_id,
        now() + interval '14 days',
        now() + interval '15 days',
        now() - interval '2 days',
        now() + interval '12 days',
        100,
        'published',
        'Free',
        150,
        ARRAY['Flutter', 'Hackathon', 'Development'],
        '[{"name": "Stickers", "icon": "emoji_events"}, {"name": "Certificate", "icon": "verified_user"}]'::jsonb
    ),
    (
        'Apex Legends Pro-Am',
        'Watch pros and amateurs battle it out. Exclusive viewing party and live coaching.',
        'https://images.unsplash.com/photo-1548438296-122f2324dc29?auto=format&fit=crop&q=80&w=800',
        v_venue_id,
        now() + interval '3 days',
        now() + interval '3 days 6 hours',
        now() - interval '5 days',
        now() + interval '2 days',
        50,
        'published',
        '₹500',
        200,
        ARRAY['Apex Legends', 'Pro-Am', 'Event'],
        '[{"name": "VVIP Seating", "icon": "chair"}, {"name": "Meet & Greet", "icon": "people"}]'::jsonb
    );

END $$;
