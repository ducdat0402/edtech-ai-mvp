# 🗺️ Feature Roadmap - Kế Hoạch Phát Triển Tính Năng

## 📋 Tổng Quan Các Tính Năng

1. **Content Format Classification** - Chia bài học theo format (video, image, mixed, quiz)
2. **Edit History/Journal** - Lịch sử chỉnh sửa (nhật ký hành trình)
3. **Difficulty Level & Rewards** - Độ khó và phân EXP/Coin
4. **Preview Edit** - Preview đóng góp trước khi submit

---

## 🎯 Thứ Tự Ưu Tiên (Recommended Order)

### **Phase 1: Foundation (Nền tảng)**
**Mục tiêu**: Tạo cấu trúc dữ liệu cơ bản để hỗ trợ các tính năng khác

#### 1.1 Content Format Classification ⭐⭐⭐
**Ưu tiên**: CAO - Cần thiết cho các tính năng khác

**Backend:**
- [ ] Thêm field `format` vào `ContentItem` entity:
  ```typescript
  format: 'video' | 'image' | 'mixed' | 'quiz' | 'text'
  ```
- [ ] Tạo migration để thêm column
- [ ] Logic tự động detect format dựa trên media:
  - `video`: có `videoUrl`, không có `imageUrl`
  - `image`: có `imageUrl`, không có `videoUrl`
  - `mixed`: có cả `videoUrl` và `imageUrl`
  - `quiz`: có `quizData`
  - `text`: chỉ có `content`, không có media
- [ ] API endpoint để filter theo format
- [ ] Update existing content items với format phù hợp

**Frontend:**
- [ ] Hiển thị badge/icon theo format trong content list
- [ ] Filter theo format trong UI
- [ ] Icon khác nhau cho từng format:
  - 🎥 Video
  - 🖼️ Image
  - 🎨 Mixed
  - ❓ Quiz
  - 📝 Text

**Thời gian ước tính**: 2-3 giờ

---

#### 1.2 Difficulty Level & Rewards ⭐⭐⭐
**Ưu tiên**: CAO - Cần thiết cho gamification

**Backend:**
- [ ] Thêm field `difficulty` vào `ContentItem` entity:
  ```typescript
  difficulty: 'easy' | 'medium' | 'hard' | 'expert'
  ```
- [ ] Tạo migration
- [ ] Logic tính toán EXP và Coin dựa trên difficulty:
  ```typescript
  // Easy: 10 EXP, 5 Coin
  // Medium: 25 EXP, 10 Coin
  // Hard: 50 EXP, 20 Coin
  // Expert: 100 EXP, 50 Coin
  ```
- [ ] Auto-update `rewards` khi set difficulty
- [ ] API để set/update difficulty
- [ ] Migration để set difficulty mặc định cho existing items

**Frontend:**
- [ ] Dropdown/Selector để chọn difficulty khi tạo/edit bài học
- [ ] Hiển thị badge difficulty (màu sắc khác nhau)
- [ ] Hiển thị EXP và Coin trong content viewer
- [ ] Preview rewards trước khi complete bài học

**Thời gian ước tính**: 2-3 giờ

---

### **Phase 2: User Experience (Trải nghiệm người dùng)**

#### 2.1 Preview Edit ⭐⭐
**Ưu tiên**: TRUNG BÌNH - Cải thiện UX

**Frontend:**
- [ ] Thêm "Preview" button trong dialog submit edit
- [ ] Preview mode hiển thị:
  - Video/image sẽ trông như thế nào
  - Caption và description
  - Layout tương tự như khi được approve
- [ ] Toggle giữa Edit và Preview mode
- [ ] Validation preview (kiểm tra lỗi trước khi submit)

**Backend:**
- [ ] Không cần thay đổi (chỉ frontend)

**Thời gian ước tính**: 2-3 giờ

---

### **Phase 3: Tracking & History (Theo dõi và lịch sử)**

#### 3.1 Edit History/Journal ⭐
**Ưu tiên**: THẤP - Nice to have

**Backend:**
- [ ] Tạo `EditHistory` entity:
  ```typescript
  {
    id: string;
    contentItemId: string;
    userId: string;
    action: 'create' | 'update' | 'approve' | 'reject' | 'remove';
    changes: JSONB; // Snapshot of changes
    previousState?: JSONB;
    newState?: JSONB;
    createdAt: Date;
  }
  ```
- [ ] Service để log mọi thay đổi:
  - Khi user submit edit
  - Khi admin approve/reject
  - Khi admin remove edit
  - Khi content item được update
- [ ] API để get history của một content item
- [ ] API để get history của một user

**Frontend:**
- [ ] Timeline view trong Admin Panel
- [ ] Hiển thị lịch sử chỉnh sửa của từng bài học
- [ ] Filter theo user, date, action
- [ ] Diff view (so sánh trước/sau)

**Thời gian ước tính**: 4-5 giờ

---

## 📊 Dependency Graph

```
Content Format
    ↓
Difficulty & Rewards (có thể dùng format để suggest difficulty)
    ↓
Preview Edit (cần format để preview đúng)
    ↓
Edit History (track tất cả changes)
```

---

## 🎯 Recommended Implementation Order

### **Week 1: Foundation**
1. ✅ **Content Format Classification** (Day 1-2)
   - Backend: Entity, migration, auto-detect logic
   - Frontend: Badge, filter, icons

2. ✅ **Difficulty Level & Rewards** (Day 3-4)
   - Backend: Entity, migration, reward calculation
   - Frontend: Selector, badges, display rewards

### **Week 2: Enhancement**
3. ✅ **Preview Edit** (Day 1-2)
   - Frontend: Preview mode trong dialog

4. ✅ **Edit History** (Day 3-5)
   - Backend: Entity, service, API
   - Frontend: Timeline view, filters

---

## 🔧 Technical Considerations

### Database Migrations
- Cần migration cho mỗi feature mới
- Set default values cho existing data
- Backward compatibility

### Performance
- Edit History có thể lớn → cần pagination
- Index trên `contentItemId`, `userId`, `createdAt`

### UI/UX
- Consistent design language
- Loading states
- Error handling
- Mobile responsive

---

## 📝 Notes

- **Content Format**: Nên làm đầu tiên vì các tính năng khác có thể dựa vào nó
- **Difficulty**: Quan trọng cho gamification, nên làm sớm
- **Preview**: Cải thiện UX, có thể làm song song với các tính năng khác
- **History**: Nice to have, có thể làm sau cùng

---

## ✅ Success Criteria

- [ ] Tất cả bài học có format rõ ràng
- [ ] Difficulty được set và rewards tự động tính
- [ ] User có thể preview edit trước khi submit
- [ ] Admin có thể xem lịch sử chỉnh sửa đầy đủ

