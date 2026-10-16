CREATE OR REPLACE FUNCTION public.is_occupied(su public.service_units) RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.booking_items bi
    JOIN public.bookings b ON bi.booking_id = b.id
    WHERE bi.service_unit_id = su.id
      AND b.status IN ('confirmed', 'pending', 'active')
      AND b.start_time <= now()
      AND b.end_time > now()
  ) OR EXISTS (
    SELECT 1
    FROM public.reservation_hold_items rhi
    JOIN public.reservation_holds rh ON rhi.hold_id = rh.id
    WHERE rhi.service_unit_id = su.id
      AND rh.status = 'active'
      AND rh.expires_at > now()
      AND rh.start_time <= now()
      AND rh.end_time > now()
  );
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION public.occupied_till(su public.service_units) RETURNS timestamptz AS $$
DECLARE
  v_end timestamptz;
BEGIN
  WITH all_intervals AS (
    SELECT b.start_time, b.end_time
    FROM public.booking_items bi
    JOIN public.bookings b ON bi.booking_id = b.id
    WHERE bi.service_unit_id = su.id
      AND b.status IN ('confirmed', 'pending', 'active')
      AND b.end_time > now()
    UNION ALL
    SELECT rh.start_time, rh.end_time
    FROM public.reservation_hold_items rhi
    JOIN public.reservation_holds rh ON rhi.hold_id = rh.id
    WHERE rhi.service_unit_id = su.id
      AND rh.status = 'active'
      AND rh.expires_at > now()
      AND rh.end_time > now()
  )
  SELECT i1.end_time INTO v_end
  FROM all_intervals i1
  WHERE i1.end_time >= now()
    -- Ensure the unit is actually occupied right now
    AND EXISTS (
      SELECT 1 FROM all_intervals i_cover 
      WHERE i_cover.start_time <= now() AND i_cover.end_time > now()
    )
    -- Find the earliest end_time that has no succeeding back-to-back booking
    AND NOT EXISTS (
      SELECT 1 
      FROM all_intervals i2 
      WHERE i2.start_time <= i1.end_time 
        AND i2.end_time > i1.end_time
    )
  ORDER BY i1.end_time ASC
  LIMIT 1;

  RETURN v_end;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION public.next_booking_at(su public.service_units) RETURNS timestamptz AS $$
DECLARE
  v_start timestamptz;
BEGIN
  WITH all_intervals AS (
    SELECT b.start_time
    FROM public.booking_items bi
    JOIN public.bookings b ON bi.booking_id = b.id
    WHERE bi.service_unit_id = su.id
      AND b.status IN ('confirmed', 'pending', 'active')
      AND b.start_time > now()
    UNION ALL
    SELECT rh.start_time
    FROM public.reservation_hold_items rhi
    JOIN public.reservation_holds rh ON rhi.hold_id = rh.id
    WHERE rhi.service_unit_id = su.id
      AND rh.status = 'active'
      AND rh.expires_at > now()
      AND rh.start_time > now()
  )
  SELECT start_time INTO v_start
  FROM all_intervals
  ORDER BY start_time ASC
  LIMIT 1;

  RETURN v_start;
END;
$$ LANGUAGE plpgsql STABLE;
