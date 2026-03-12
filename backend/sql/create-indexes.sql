-- =====================================================
-- PERFORMANCE INDEXES FOR EDTECH AI MVP
-- Run this on Supabase SQL Editor
-- =====================================================

-- 1. learning_nodes: filter by subject, domain, topic
CREATE INDEX IF NOT EXISTS idx_learning_nodes_subject
    ON learning_nodes("subjectId");
CREATE INDEX IF NOT EXISTS idx_learning_nodes_domain
    ON learning_nodes("domainId");
CREATE INDEX IF NOT EXISTS idx_learning_nodes_topic
    ON learning_nodes("topicId");
CREATE INDEX IF NOT EXISTS idx_learning_nodes_subject_type
    ON learning_nodes("subjectId", "type");

-- 2. domains: filter by subject
CREATE INDEX IF NOT EXISTS idx_domains_subject
    ON domains("subjectId");

-- 3. topics: filter by domain
CREATE INDEX IF NOT EXISTS idx_topics_domain
    ON topics("domainId");

-- 4. user_progress: filter by user + node
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_progress_user_node
    ON user_progress("userId", "nodeId");

-- 5. user_topic_progress: filter by user + topic
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_topic_progress_user_topic
    ON user_topic_progress("userId", "topicId");

-- 6. user_domain_progress: filter by user + domain
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_domain_progress_user_domain
    ON user_domain_progress("userId", "domainId");

-- 7. user_currencies: filter by user
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_currencies_user
    ON user_currencies("userId");

-- 8. reward_transactions: filter by user + date
CREATE INDEX IF NOT EXISTS idx_reward_transactions_user
    ON reward_transactions("userId");
CREATE INDEX IF NOT EXISTS idx_reward_transactions_user_created
    ON reward_transactions("userId", "createdAt" DESC);
CREATE INDEX IF NOT EXISTS idx_reward_transactions_source
    ON reward_transactions("userId", "source");

-- 9. user_unlocks: filter by user + level + subject/domain/topic
CREATE INDEX IF NOT EXISTS idx_user_unlocks_user
    ON user_unlocks("userId");
CREATE INDEX IF NOT EXISTS idx_user_unlocks_user_subject
    ON user_unlocks("userId", "subjectId");
CREATE INDEX IF NOT EXISTS idx_user_unlocks_user_domain
    ON user_unlocks("userId", "domainId");
CREATE INDEX IF NOT EXISTS idx_user_unlocks_user_topic
    ON user_unlocks("userId", "topicId");
CREATE INDEX IF NOT EXISTS idx_user_unlocks_user_level
    ON user_unlocks("userId", "unlockLevel");

-- 10. unlock_transactions: filter by user + status
CREATE INDEX IF NOT EXISTS idx_unlock_transactions_user
    ON unlock_transactions("userId");
CREATE INDEX IF NOT EXISTS idx_unlock_transactions_user_status
    ON unlock_transactions("userId", "status");

-- 11. payments: filter by user + status + paymentCode
CREATE INDEX IF NOT EXISTS idx_payments_user
    ON payments("userId");
CREATE INDEX IF NOT EXISTS idx_payments_user_status
    ON payments("userId", "status");
CREATE INDEX IF NOT EXISTS idx_payments_code
    ON payments("paymentCode");
CREATE INDEX IF NOT EXISTS idx_payments_transaction
    ON payments("transactionId");

-- 12. adaptive_tests: filter by user + subject + status
CREATE INDEX IF NOT EXISTS idx_adaptive_tests_user
    ON adaptive_tests("userId");
CREATE INDEX IF NOT EXISTS idx_adaptive_tests_user_subject
    ON adaptive_tests("userId", "subjectId");
CREATE INDEX IF NOT EXISTS idx_adaptive_tests_user_status
    ON adaptive_tests("userId", "status");

-- 13. personal_mind_maps: filter by user + subject
CREATE UNIQUE INDEX IF NOT EXISTS idx_personal_mind_maps_user_subject
    ON personal_mind_maps("userId", "subjectId");

-- 14. user_quests: filter by user + date
CREATE INDEX IF NOT EXISTS idx_user_quests_user
    ON user_quests("userId");
CREATE INDEX IF NOT EXISTS idx_user_quests_user_date
    ON user_quests("userId", "date");

-- 15. user_achievements: filter by user
CREATE INDEX IF NOT EXISTS idx_user_achievements_user
    ON user_achievements("userId");

-- 16. pending_contributions: filter by contributor + status
CREATE INDEX IF NOT EXISTS idx_pending_contributions_contributor
    ON pending_contributions("contributorId");
CREATE INDEX IF NOT EXISTS idx_pending_contributions_status
    ON pending_contributions("status");
CREATE INDEX IF NOT EXISTS idx_pending_contributions_contributor_status
    ON pending_contributions("contributorId", "status");

-- 17. lesson_type_contents: filter by node + type
CREATE UNIQUE INDEX IF NOT EXISTS idx_lesson_type_contents_node_type
    ON lesson_type_contents("nodeId", "lessonType");

-- 18. lesson_type_content_versions: filter by node + type
CREATE INDEX IF NOT EXISTS idx_lesson_type_versions_node_type
    ON lesson_type_content_versions("nodeId", "lessonType");
CREATE INDEX IF NOT EXISTS idx_lesson_type_versions_contributor
    ON lesson_type_content_versions("contributorId");

-- =====================================================
-- ANALYZE tables to update query planner statistics
-- =====================================================
ANALYZE learning_nodes;
ANALYZE domains;
ANALYZE topics;
ANALYZE user_progress;
ANALYZE user_topic_progress;
ANALYZE user_domain_progress;
ANALYZE user_currencies;
ANALYZE reward_transactions;
ANALYZE user_unlocks;
ANALYZE unlock_transactions;
ANALYZE payments;
ANALYZE adaptive_tests;
ANALYZE personal_mind_maps;
ANALYZE user_quests;
ANALYZE user_achievements;
ANALYZE pending_contributions;
ANALYZE lesson_type_contents;
ANALYZE lesson_type_content_versions;
