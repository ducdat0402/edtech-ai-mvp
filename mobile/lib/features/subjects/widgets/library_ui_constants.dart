/// Slug từ API `libraryCategory` ([Subject.metadata] / dashboard subjects).
typedef LibraryCategorySlug = String;

const String kLibraryCategoryAll = 'all';

const Map<String, String> kLibraryCategoryLabelsVi = {
  'tech': 'Công nghệ',
  'psychology': 'Tâm lý học',
  'skills': 'Kỹ năng',
  'other': 'Khác',
};

/// Thứ tự hiển thị chip (bỏ qua slug không có trong danh sách môn).
const List<String> kLibraryCategoryOrder = [
  'tech',
  'psychology',
  'skills',
  'other',
];
