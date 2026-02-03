#!/bin/bash
# Script to insert all data in correct order

echo "Inserting schema..."
psql -U $DB_USER -d $DB_NAME -f table_schema.sql

echo "Inserting data in correct order..."

# Level 1: No dependencies
psql -U $DB_USER -d $DB_NAME -f table_knowledge_nodes.sql
psql -U $DB_USER -d $DB_NAME -f table_quests.sql
psql -U $DB_USER -d $DB_NAME -f table_subjects.sql
psql -U $DB_USER -d $DB_NAME -f table_users.sql

# Level 2: 1 dependency
psql -U $DB_USER -d $DB_NAME -f table_knowledge_edges.sql
psql -U $DB_USER -d $DB_NAME -f table_domains.sql
psql -U $DB_USER -d $DB_NAME -f table_questions.sql
psql -U $DB_USER -d $DB_NAME -f table_payments.sql
psql -U $DB_USER -d $DB_NAME -f table_reward_transactions.sql
psql -U $DB_USER -d $DB_NAME -f table_user_currencies.sql
psql -U $DB_USER -d $DB_NAME -f table_user_premium.sql

# Level 3: 2 dependencies
psql -U $DB_USER -d $DB_NAME -f table_adaptive_tests.sql
psql -U $DB_USER -d $DB_NAME -f table_personal_mind_maps.sql
psql -U $DB_USER -d $DB_NAME -f table_placement_tests.sql
psql -U $DB_USER -d $DB_NAME -f table_skill_trees.sql
psql -U $DB_USER -d $DB_NAME -f table_user_quests.sql
psql -U $DB_USER -d $DB_NAME -f table_learning_nodes.sql
psql -U $DB_USER -d $DB_NAME -f table_content_items.sql  # MUST be before content_versions
psql -U $DB_USER -d $DB_NAME -f table_skill_nodes.sql
psql -U $DB_USER -d $DB_NAME -f table_user_progress.sql
psql -U $DB_USER -d $DB_NAME -f table_content_edits.sql
psql -U $DB_USER -d $DB_NAME -f table_edit_history.sql
psql -U $DB_USER -d $DB_NAME -f table_quizzes.sql
psql -U $DB_USER -d $DB_NAME -f table_user_skill_progress.sql

# Level 4: 3 dependencies
psql -U $DB_USER -d $DB_NAME -f table_content_versions.sql  # MUST be after content_items

echo "Done!"
