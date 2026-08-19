-- Migration: 20260815000700_fix_owner_manual_booking_conflict.sql
-- Fix double booking when offline owner bookings overlap with online reservation holds

CREATE OR REPLACE FUNCTION public.create_owner_manual_booking_atomic(
  p_venue_id uuid,
  p_start_time timestamptz,
  p_end_time timestamptz,
  p_service_unit_ids uuid[],
  p_customer_name text,
  p_customer_phone text DEFAULT NULL,
  p_source text DEFAULT 'walk_in',
  p_notes text DEFAULT NULL,
  p_party_size integer DEFAULT 1
) RETURNS uuid AS $$
DECLARE
  v_booking_id uuid;
  v_total_amount numeric := 0.0;
  v_hours numeric;
  v_conflict_count integer;
  v_booking_code text;
  v_check_in_code text;
  v_unit_id uuid;
  v_buffer_before interval := interval '0 minutes';
  v_buffer_after interval := interval '0 minutes';
BEGIN
  IF NOT public.is_venue_owner(p_venue_id) THEN
    RAISE EXCEPTION 'Only authorized venue owners can create manual bookings.';
  END IF;

  v_hours := extract(epoch FROM (p_end_time - p_start_time)) / 3600;

  -- Read Venue Settings for Buffers
  SELECT
    (COALESCE(buffer_before_minutes, 0) || ' minutes')::interval,
    (COALESCE(buffer_after_minutes, 0) || ' minutes')::interval
  INTO
    v_buffer_before,
    v_buffer_after
  FROM public.venue_booking_settings
  WHERE venue_id = p_venue_id;

  -- Lock service units
  PERFORM 1
  FROM public.service_units
  WHERE id = ANY(p_service_unit_ids)
  FOR UPDATE;

  -- Check conflicts against both confirmed/active bookings AND active reservation holds
  SELECT count(*) INTO v_conflict_count
  FROM (
    SELECT service_unit_id FROM public.booking_items bi
    JOIN public.bookings b ON bi.booking_id = b.id
    WHERE bi.service_unit_id = ANY(p_service_unit_ids)
      AND b.status IN ('confirmed', 'pending', 'active')
      AND (b.start_time - v_buffer_after) < p_end_time
      AND (b.end_time + v_buffer_before) > p_start_time
    UNION ALL
    SELECT service_unit_id FROM public.reservation_hold_items rhi
    JOIN public.reservation_holds rh ON rhi.hold_id = rh.id
    WHERE rhi.service_unit_id = ANY(p_service_unit_ids)
      AND rh.status = 'active'
      AND rh.expires_at > now()
      AND (rh.start_time - v_buffer_after) < p_end_time
      AND (rh.end_time + v_buffer_before) > p_start_time
  ) t;

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'One or more selected resources are already booked or held for this time period.';
  END IF;

  SELECT sum(price) * v_hours INTO v_total_amount
  FROM public.service_units
  WHERE id = ANY(p_service_unit_ids);

  v_booking_code := 'BK-' || UPPER(SUBSTRING(gen_random_uuid()::text FROM 1 FOR 6));
  v_check_in_code := LPAD((FLOOR(RANDOM() * 9000) + 1000)::text, 4, '0');

  -- Create Booking
  INSERT INTO public.bookings (
    user_id, venue_id, start_time, end_time, total_amount, status, confirmed_at, source,
    booking_code, check_in_code, notes
  )
  VALUES (
    auth.uid(), p_venue_id, p_start_time, p_end_time,
    v_total_amount, 'confirmed', now(), p_source,
    v_booking_code, v_check_in_code, p_notes
  )
  RETURNING id INTO v_booking_id;

  -- Create Booking Items
  INSERT INTO public.booking_items (booking_id, service_unit_id, price_at_booking)
  SELECT v_booking_id, su.id, su.price
  FROM public.service_units su
  WHERE su.id = ANY(p_service_unit_ids);

  -- Create Sessions
  FOR v_unit_id IN
    SELECT unnest(p_service_unit_ids)
  LOOP
    INSERT INTO public.sessions (
      booking_id, venue_id, service_unit_id, status, scheduled_start_at, scheduled_end_at
    )
    VALUES (
      v_booking_id, p_venue_id, v_unit_id, 'not_started', p_start_time, p_end_time
    );
  END LOOP;
  
  -- Create Participant
  INSERT INTO public.booking_participants (
    booking_id, name, phone, is_primary, waiver_signed
  )
  VALUES (
    v_booking_id, p_customer_name, p_customer_phone, true, true
  );

  -- Log Event
  PERFORM public.log_booking_event(
    v_booking_id, NULL, 'OWNER_MANUAL_BOOKING', auth.uid(), 'owner',
    jsonb_build_object('source', p_source, 'booking_code', v_booking_code)
  );

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
