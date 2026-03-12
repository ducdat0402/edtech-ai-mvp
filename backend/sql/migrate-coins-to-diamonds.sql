-- Migration: Separate coins and diamonds into two currencies
-- Run this AFTER deploying the new code (so TypeORM creates the diamonds column)
-- Or run the ALTER TABLE first if synchronize is disabled

-- Step 1: Add diamonds column if not exists
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_currencies' AND column_name = 'diamonds'
  ) THEN
    ALTER TABLE user_currencies ADD COLUMN diamonds integer NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Step 2: Copy current coins to diamonds (existing coins were actually diamonds)
UPDATE user_currencies SET diamonds = coins WHERE diamonds = 0 AND coins > 0;

-- Step 3: Reset coins to 0 (coins will be earned fresh through learning)
UPDATE user_currencies SET coins = 0;
