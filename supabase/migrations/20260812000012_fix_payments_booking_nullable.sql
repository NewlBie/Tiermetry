-- Migration 20260812000012: Fix payments table where booking_id is incorrectly NOT NULL.
-- Handles legacy data where hold_id is missing.

-- 1. Drop NOT NULL constraint on booking_id
-- This allows initiating a payment for a reservation hold BEFORE a booking is created.
ALTER TABLE public.payments
ALTER COLUMN booking_id DROP NOT NULL;

-- 2. Handle hold_id nullability
-- We MUST keep hold_id nullable because legacy payment records exist.
-- New payment attempts are already forced to provide a valid hold_id
-- via the RLS INSERT policy in migration 000011.
ALTER TABLE public.payments
ALTER COLUMN hold_id DROP NOT NULL;

-- 3. Verification of Ownership/Constraint
-- No further changes needed.
-- New Inserts: Forced to have hold_id by RLS.
-- Legacy Records: Preserved with their booking_id links.
