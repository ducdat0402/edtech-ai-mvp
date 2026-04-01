-- Bảng mở từng bài học (2 suất miễn phí/ngày + 50 kim cương/bài sau đó)
CREATE TABLE IF NOT EXISTS user_opened_nodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "userId" uuid NOT NULL,
  "nodeId" uuid NOT NULL,
  "diamondsPaid" integer NOT NULL DEFAULT 0,
  "coinsPaid" integer NOT NULL DEFAULT 0,
  "openedAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_user_opened_nodes_user_node UNIQUE ("userId", "nodeId")
);

CREATE INDEX IF NOT EXISTS idx_user_opened_nodes_user ON user_opened_nodes ("userId");

-- Backward-compatible patch for older deployments
ALTER TABLE user_opened_nodes
  ADD COLUMN IF NOT EXISTS "coinsPaid" integer NOT NULL DEFAULT 0;
