# Thứ tự INSERT DATA

## Tổng quan

Thứ tự insert được xác định dựa trên foreign key relationships giữa các bảng. Bảng không có dependencies sẽ được insert trước, sau đó đến các bảng phụ thuộc vào chúng.

## Thứ tự INSERT theo Level

### Level 1: Bảng không có dependencies
Các bảng này có thể được insert đầu tiên vì không phụ thuộc vào bảng nào khác:

1. `table_knowledge_nodes.sql` - Không có dependencies
2. `table_quests.sql` - Không có dependencies  
3. `table_subjects.sql` - Không có dependencies
4. `table_users.sql` - Không có dependencies

### Level 2: Bảng có 1 dependency
Các bảng này phụ thuộc vào 1 bảng đã được insert ở Level 1:

5. `table_knowledge_edges.sql` → depends on: `knowledge_nodes`
6. `table_domains.sql` → depends on: `subjects`
7. `table_questions.sql` → depends on: `subjects`
8. `table_payments.sql` → depends on: `users`
9. `table_reward_transactions.sql` → depends on: `users`
10. `table_user_currencies.sql` → depends on: `users`
11. `table_user_premium.sql` → depends on: `users`

### Level 3: Bảng có 2 dependencies
Các bảng này phụ thuộc vào 2 bảng đã được insert trước đó:

12. `table_adaptive_tests.sql` → depends on: `users`, `subjects`
13. `table_personal_mind_maps.sql` → depends on: `subjects`, `users`
14. `table_placement_tests.sql` → depends on: `users`, `subjects`
15. `table_skill_trees.sql` → depends on: `users`, `subjects`
16. `table_user_quests.sql` → depends on: `quests`, `users`
17. `table_learning_nodes.sql` → depends on: `domains`, `subjects`
18. `table_content_items.sql` → depends on: `learning_nodes`
19. `table_skill_nodes.sql` → depends on: `learning_nodes`, `skill_trees`
20. `table_user_progress.sql` → depends on: `learning_nodes`, `users`
21. `table_content_edits.sql` → depends on: `users`, `content_items`
22. `table_edit_history.sql` → depends on: `users`, `content_items`
23. `table_quizzes.sql` → depends on: `content_items`, `learning_nodes`
24. `table_user_skill_progress.sql` → depends on: `users`, `skill_nodes`

### Level 4: Bảng có 3 dependencies
Bảng này phụ thuộc vào 3 bảng đã được insert trước đó:

25. `table_content_versions.sql` → depends on: `content_items`, `content_edits`, `users`

## Danh sách đầy đủ theo thứ tự

```
 1. table_knowledge_nodes.sql
 2. table_quests.sql
 3. table_subjects.sql
 4. table_users.sql
 5. table_knowledge_edges.sql
 6. table_domains.sql
 7. table_questions.sql
 8. table_adaptive_tests.sql
 9. table_payments.sql
10. table_personal_mind_maps.sql
11. table_placement_tests.sql
12. table_reward_transactions.sql
13. table_skill_trees.sql
14. table_user_currencies.sql
15. table_user_premium.sql
16. table_user_quests.sql
17. table_learning_nodes.sql
18. table_content_items.sql
19. table_skill_nodes.sql
20. table_user_progress.sql
21. table_content_edits.sql
22. table_edit_history.sql
23. table_quizzes.sql
24. table_user_skill_progress.sql
25. table_content_versions.sql
```

## Cách sử dụng

### Trong PostgreSQL (psql):

```sql
-- 1. Chạy schema trước
\i table_schema.sql

-- 2. Chạy data theo thứ tự
\i table_knowledge_nodes.sql
\i table_quests.sql
\i table_subjects.sql
\i table_users.sql
\i table_knowledge_edges.sql
\i table_domains.sql
\i table_questions.sql
\i table_adaptive_tests.sql
\i table_payments.sql
\i table_personal_mind_maps.sql
\i table_placement_tests.sql
\i table_reward_transactions.sql
\i table_skill_trees.sql
\i table_user_currencies.sql
\i table_user_premium.sql
\i table_user_quests.sql
\i table_learning_nodes.sql
\i table_content_items.sql
\i table_skill_nodes.sql
\i table_user_progress.sql
\i table_content_edits.sql
\i table_edit_history.sql
\i table_quizzes.sql
\i table_user_skill_progress.sql
\i table_content_versions.sql
```

### Hoặc sử dụng script tự động:

```bash
cd backend/scripts/backup_plain_tables
psql -U your_user -d your_database -f table_schema.sql
psql -U your_user -d your_database -f table_knowledge_nodes.sql
psql -U your_user -d your_database -f table_quests.sql
# ... (tiếp tục theo thứ tự)
```

## Lưu ý

- **Luôn chạy `table_schema.sql` trước** để tạo cấu trúc bảng và constraints
- Thứ tự insert rất quan trọng để tránh lỗi foreign key constraint violations
- Nếu có lỗi, kiểm tra lại xem bảng dependency đã được insert chưa
