-- Add role column to users table if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR DEFAULT 'user';

-- Update existing users to have 'user' role
UPDATE users SET role = 'user' WHERE role IS NULL;

