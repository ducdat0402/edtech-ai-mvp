-- Gắn libraryCategory mặc định cho subject chưa có (JSONB merge).
-- Chạy thủ công trên DB production/staging khi triển khai.

UPDATE subjects
SET metadata = jsonb_set(
  COALESCE(metadata, '{}'::jsonb),
  '{libraryCategory}',
  '"other"'::jsonb,
  true
)
WHERE metadata IS NULL
   OR NOT (metadata ? 'libraryCategory');

-- Gợi ý gán nhanh theo từ khóa tên (tùy dữ liệu cục bộ — chỉnh trước khi chạy):
-- UPDATE subjects SET metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{libraryCategory}', '"tech"'::jsonb, true)
-- WHERE LOWER(name) LIKE '%lập trình%' OR LOWER(name) LIKE '%công nghệ%' OR LOWER(name) LIKE '%ic3%';
