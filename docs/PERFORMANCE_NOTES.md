# Hiệu năng app & database

## Đã tối ưu

1. **`GET /dashboard/summary`** — Chỉ currency + `COUNT` bài đã xong. Màn **Profile** dùng endpoint này thay vì `/dashboard` (trước đây load **toàn bộ** `learning_nodes`).
2. **`GET /dashboard`** — Vẫn nặng (subjects + mọi node + quests). Chỉ nên gọi ở **Dashboard** khi thật sự cần `subjects`, `activeLearning`, `currentLearningNodes`.
3. **Contributor mind map** — Tải topics theo từng domain **song song** (`Future.wait`), không còn N lần await tuần tự.
4. **Index DB (TypeORM `synchronize` hoặc migration thủ công)**  
   - `learning_nodes(subjectId)`  
   - `user_progress(userId, isCompleted)` — hỗ trợ đếm bài đã hoàn thành.

## Gợi ý thêm (chưa làm)

| Khu vực | Ý tưởng |
|--------|---------|
| `/dashboard` đầy đủ | Tính tổng/ nhóm bằng SQL (`GROUP BY subjectId`) thay vì `find()` hết node vào RAM. |
| Contributor mind map | Giảm **pre-fetch** lesson type cho mọi node cùng lúc; chỉ fetch khi mở nhánh hoặc giới hạn concurrency. |
| Mobile | Cache nhẹ `role` / profile sau khi đăng nhập để màn chỉ cần `role` không gọi lại `/auth/me`. |
| Ảnh | `CachedNetworkImage` + kích thước thumbnail phía server nếu có CDN. |

## SQL index (production không bật sync)

```sql
CREATE INDEX IF NOT EXISTS "IDX_learning_nodes_subjectId"
  ON learning_nodes ("subjectId");
CREATE INDEX IF NOT EXISTS "IDX_user_progress_userId_isCompleted"
  ON user_progress ("userId", "isCompleted");
```
