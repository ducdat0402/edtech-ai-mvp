# Điều Kiện Tạo Roadmap

## Tổng Quan

Roadmap là lộ trình học tập 30 ngày được tạo tự động dựa trên:
- Kết quả Placement Test của user
- Subject (môn học) được chọn
- Learning Nodes có sẵn trong database (hoặc tự động tạo bằng AI nếu chưa có)

## ⚡ Tính Năng Mới: Tự Động Tạo Learning Nodes

**Nếu subject chưa có Learning Nodes**, hệ thống sẽ:
1. Tự động tạo Learning Nodes bằng AI (10-15 nodes)
2. Tự động tạo đầy đủ content (concepts, examples, rewards, quiz)
3. Sau đó mới tạo roadmap dựa trên các nodes đó

**Không cần chuẩn bị gì!** Chỉ cần có Subject trong database.

## Điều Kiện Bắt Buộc

### 1. **User Phải Tồn Tại**
- User phải đã đăng ký và đăng nhập
- `userId` phải hợp lệ trong database
- **Error nếu thiếu**: `NotFoundException('User not found')`

### 2. **Subject Phải Tồn Tại**
- `subjectId` phải là ID của một Subject hợp lệ trong database
- Subject phải được seed trong database trước
- **Error nếu thiếu**: `NotFoundException('Subject not found')`

### 3. **Subject Phải Có Learning Nodes** (Tự Động Tạo Nếu Chưa Có)
- Subject phải có ít nhất 1 Learning Node
- **Nếu chưa có**: Hệ thống tự động tạo bằng AI (không cần làm gì)
- Learning Nodes là các bài học/concept trong subject đó
- **Error chỉ khi**: Không thể tạo nodes (API lỗi, etc.)

## Điều Kiện Tùy Chọn (Có Giá Trị Mặc Định)

### 4. **Placement Test Level** (Optional)
- Nếu user đã làm Placement Test → dùng `user.placementTestLevel`
- Nếu chưa làm → mặc định `'beginner'`
- Các level: `'beginner'`, `'intermediate'`, `'advanced'`
- **Ảnh hưởng**: 
  - Thời gian học ước tính mỗi ngày:
    - Beginner: 15 phút/ngày
    - Intermediate: 20 phút/ngày
    - Advanced: 30 phút/ngày

### 5. **Onboarding Data** (Optional)
- `onboardingData.interests` - Sở thích của user
- `onboardingData.learningGoals` - Mục tiêu học tập
- Nếu không có → dùng giá trị mặc định `[]` hoặc `undefined`
- **Ảnh hưởng**: Được lưu vào `metadata` của roadmap để tham khảo sau này

## Logic Tạo Roadmap

### Bước 1: Kiểm Tra Roadmap Hiện Tại
```typescript
// Nếu user đã có roadmap ACTIVE cho subject này → return roadmap cũ
// Không tạo roadmap mới
```

### Bước 2: Lấy Dữ Liệu
- Lấy user từ database
- Lấy subject từ database
- Lấy tất cả learning nodes của subject
- Lấy `placementTestLevel` từ user (hoặc 'beginner')
- Lấy `onboardingData` từ user (hoặc {})

### Bước 3: Tạo Roadmap Entity
```typescript
{
  userId: string,
  subjectId: string,
  status: 'active',
  totalDays: 30,
  currentDay: 1,
  startDate: Date (hôm nay),
  endDate: Date (hôm nay + 30 ngày),
  metadata: {
    level: 'beginner' | 'intermediate' | 'advanced',
    interests: string[],
    learningGoals: string,
    estimatedHoursPerDay: number
  }
}
```

### Bước 4: Phân Bổ Learning Nodes Cho 30 Ngày

#### **Ngày 1-10: Beginner Phase (20% nodes)**
- Học các khái niệm cơ bản
- Estimated: 15 phút/ngày
- Type: 'video'

#### **Ngày 11-20: Intermediate Phase (50% nodes)**
- Thực hành và áp dụng
- Estimated: 20 phút/ngày
- Type: 'quiz'

#### **Ngày 21-25: Advanced Phase (30% nodes)**
- Học chuyên sâu
- Estimated: 25 phút/ngày
- Type: 'simulation'

#### **Ngày 26-30: Review Phase**
- Ôn tập lại các bài đã học (days 1-15)
- Estimated: 20 phút/ngày
- Type: 'review'

## API Endpoint

### Tạo Roadmap
```http
POST /api/v1/roadmap/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "subjectId": "uuid-of-subject"
}
```

### Response
```json
{
  "id": "roadmap-uuid",
  "userId": "user-uuid",
  "subjectId": "subject-uuid",
  "status": "active",
  "totalDays": 30,
  "currentDay": 1,
  "startDate": "2025-01-01",
  "endDate": "2025-01-31",
  "metadata": {
    "level": "beginner",
    "interests": [],
    "learningGoals": "...",
    "estimatedHoursPerDay": 15
  },
  "days": [...]
}
```

## Checklist Trước Khi Tạo Roadmap

- [ ] User đã đăng ký và đăng nhập
- [ ] Subject đã được seed trong database
- [ ] Subject có ít nhất 1 Learning Node
- [ ] (Optional) User đã hoàn thành Placement Test
- [ ] (Optional) User đã hoàn thành Onboarding

## Lưu Ý

1. **Mỗi user chỉ có 1 roadmap ACTIVE cho mỗi subject**
   - Nếu đã có roadmap ACTIVE → return roadmap cũ
   - Không tạo roadmap mới

2. **Roadmap được tạo tự động khi:**
   - User chọn subject lần đầu
   - User bắt đầu học một subject mới

3. **Roadmap có thể được tạo thủ công qua API:**
   ```http
   POST /api/v1/roadmap/generate
   Body: { "subjectId": "..." }
   ```

4. **Nếu thiếu Learning Nodes:**
   - Cần seed data cho subject trước
   - Hoặc tạo Learning Nodes thông qua admin panel

## Ví Dụ Flow

### Scenario 1: User Mới, Chưa Có Roadmap
1. User đăng ký → Onboarding → Placement Test
2. User chọn subject "Excel"
3. System check:
   - ✅ User exists
   - ✅ Subject "Excel" exists
   - ✅ Subject có learning nodes
4. System tạo roadmap 30 ngày
5. User bắt đầu học từ Day 1

### Scenario 2: User Đã Có Roadmap
1. User đã có roadmap ACTIVE cho "Excel"
2. User request tạo roadmap mới cho "Excel"
3. System return roadmap cũ (không tạo mới)

### Scenario 3: Subject Không Có Nodes (Tự Động Tạo)
1. User chọn subject "New Subject"
2. Subject chưa có learning nodes
3. **System tự động tạo Learning Nodes bằng AI** (không cần làm gì)
4. System tạo roadmap 30 ngày
5. User bắt đầu học ngay

**Lưu ý**: Chỉ lỗi nếu không thể tạo nodes (API lỗi, không có OPENAI_API_KEY, etc.)

## Troubleshooting

### Error: "User not found"
- **Nguyên nhân**: User chưa đăng ký hoặc token không hợp lệ
- **Giải pháp**: Đảm bảo user đã login và token còn hiệu lực

### Error: "Subject not found"
- **Nguyên nhân**: SubjectId không tồn tại trong database
- **Giải pháp**: Kiểm tra subjectId và seed subjects nếu cần

### Error: "No learning nodes available"
- **Nguyên nhân**: Subject chưa có learning nodes
- **Giải pháp**: Seed learning nodes cho subject đó

### Roadmap không được tạo
- **Nguyên nhân**: Đã có roadmap ACTIVE cho subject
- **Giải pháp**: Check existing roadmap hoặc complete/pause roadmap cũ


