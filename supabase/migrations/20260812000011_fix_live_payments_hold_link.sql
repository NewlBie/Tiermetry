-- Migration 20260812000011: Fix live payments table missing hold_id column.
-- This is a forward patch for a running development database.

-- 1. Patch payments table schema
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'payments'
          AND column_name = 'hold_id'
    ) THEN
        ALTER TABLE public.payments
        ADD COLUMN hold_id uuid REFERENCES public.reservation_holds(id);
    END IF;
END $$;

-- 2. Secure RLS Policies for payments
-- Ensure users can only interact with payments related to their own holds/bookings.

DROP POLICY IF EXISTS "Users can view their own payments" ON public.payments;
CREATE POLICY "Users can view their own payments"
  ON public.payments FOR SELECT
  USING (
    (hold_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.reservation_holds
      WHERE public.reservation_holds.id = payments.hold_id
      AND public.reservation_holds.user_id = auth.uid()
    ))
    OR
    (booking_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.bookings
      WHERE public.bookings.id = payments.booking_id
      AND public.bookings.user_id = auth.uid()
    ))
  );

DROP POLICY IF EXISTS "Users can initiate their own payments" ON public.payments;
CREATE POLICY "Users can initiate their own payments"
  ON public.payments FOR INSERT
  WITH CHECK (
    -- Link to own active and unexpired hold
    EXISTS (
      SELECT 1 FROM public.reservation_holds
      WHERE public.reservation_holds.id = hold_id
      AND public.reservation_holds.user_id = auth.uid()
      AND public.reservation_holds.status = 'active'
      AND public.reservation_holds.expires_at > now()
      -- Authoritative amount enforcement
      AND public.reservation_holds.total_amount = amount
    )
    AND status = 'created'
    AND booking_id IS NULL
  );

-- 3. Patch process_successful_payment RPC
-- Redefine the RPC to include ownership validation, amount authority, and atomic hold conversion.
CREATE OR REPLACE FUNCTION public.process_successful_payment(p_order_id text)
RETURNS void AS $$
DECLARE
  v_hold_id uuid;
  v_user_id uuid;
  v_payment_status text;
  v_payment_amount numeric;
  v_hold_amount numeric;
  v_hold_status text;
  v_hold_expires_at timestamp with time zone;
  v_booking_id uuid;
BEGIN
  -- 1. Lock payment and related hold
  SELECT
    p.hold_id, p.status, p.amount, rh.user_id, rh.total_amount, rh.status, rh.expires_at
  INTO
    v_hold_id, v_payment_status, v_payment_amount, v_user_id, v_hold_amount, v_hold_status, v_hold_expires_at
  FROM public.payments p
  JOIN public.reservation_holds rh ON p.hold_id = rh.id
  WHERE p.order_id = p_order_id
  FOR UPDATE;

  IF v_hold_id IS NULL THEN
    RAISE EXCEPTION 'Order ID % or associated hold not found', p_order_id;
  END IF;

  -- 2. SECURITY: Ownership & Environment Validation
  IF auth.role() <> 'service_role' THEN
    IF auth.uid() IS NULL OR auth.uid() <> v_user_id THEN
      RAISE EXCEPTION 'Unauthorized: Payments can only be processed by the owner of the reservation hold.';
    END IF;
  END IF;

  -- 3. Idempotency Check
  IF v_payment_status = 'paid' THEN
    RETURN;
  END IF;

  -- 4. Authoritative Validation
  IF v_payment_amount != v_hold_amount THEN
    RAISE EXCEPTION 'Amount mismatch: Payment initiated for % but hold requires %', v_payment_amount, v_hold_amount;
  END IF;

  IF v_hold_status != 'active' OR v_hold_expires_at < now() THEN
    RAISE EXCEPTION 'Reservation hold is no longer valid or has expired.';
  END IF;

  -- 5. Atomically transition payment status
  UPDATE public.payments
  SET status = 'paid', updated_at = now()
  WHERE order_id = p_order_id;

  -- 6. Authoritatively convert hold to booking
  -- This calls the private, trusted function from migration 09
  v_booking_id := public._convert_hold_to_booking_internal(v_hold_id);

  -- 7. Link booking to payment for historical reference
  UPDATE public.payments
  SET booking_id = v_booking_id
  WHERE order_id = p_order_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Permissions
REVOKE ALL ON FUNCTION public.process_successful_payment(text) FROM public;
GRANT EXECUTE ON FUNCTION public.process_successful_payment(text) TO authenticated, service_role;
