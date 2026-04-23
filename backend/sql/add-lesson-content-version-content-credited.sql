-- Ghi nhận nội dung tại thời điểm snapshot (tách với contributorId = người gửi bản chỉnh đã duyệt).
-- Chạy thủ công trên Postgres nếu không bật TypeORM synchronize.

ALTER TABLE lesson_type_content_versions
  ADD COLUMN IF NOT EXISTS "contentCreditedContributorId" uuid NULL;
