# Skill Tree System - Hướng Dẫn

## Tổng Quan

Skill Tree là hệ thống cây kỹ năng giống game, thay thế cho Roadmap truyền thống. Hệ thống này cho phép user:
- Unlock các skill nodes theo thứ tự
- Hoàn thành nodes để nhận XP và Coins
- Tự động unlock các nodes tiếp theo khi hoàn thành prerequisites
- Visual tree structure với các tiers và connections

## Cấu Trúc Database

### 1. SkillTree Entity
- `id`: UUID
- `userId`: User sở hữu tree
- `subjectId`: Subject của tree
- `status`: active, completed, locked
- `totalNodes`: Tổng số nodes
- `unlockedNodes`: Số nodes đã unlock
- `completedNodes`: Số nodes đã hoàn thành
- `totalXP`: Tổng XP đã kiếm được
- `metadata`: Level, completion percentage, etc.

### 2. SkillNode Entity
- `id`: UUID
- `skillTreeId`: Tree chứa node này
- `learningNodeId`: Link đến LearningNode để học
- `title`: Tên node
- `description`: Mô tả
- `order`: Thứ tự trong tree
- `prerequisites`: Node IDs cần hoàn thành trước
- `children`: Node IDs là children
- `type`: skill, concept, practice, boss, reward
- `requiredXP`: XP cần để unlock (optional)
- `rewardXP`: XP nhận được khi hoàn thành
- `rewardCoins`: Coins nhận được
- `unlockConditions`: Điều kiện unlock
- `position`: Vị trí trên tree (x, y, tier)
- `visual`: Icon, color, size, glow

### 3. UserSkillProgress Entity
- `id`: UUID
- `userId`: User
- `skillNodeId`: Node
- `status`: locked, unlocked, in_progress, completed
- `progress`: 0-100 (percentage)
- `xpEarned`: XP đã kiếm
- `coinsEarned`: Coins đã kiếm
- `unlockedAt`: Thời gian unlock
- `startedAt`: Thời gian bắt đầu
- `completedAt`: Thời gian hoàn thành
- `progressData`: Dữ liệu progress chi tiết

## API Endpoints

### Generate Skill Tree
```http
POST /api/v1/skill-tree/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "subjectId": "uuid-of-subject"
}
```

### Get Skill Tree
```http
GET /api/v1/skill-tree?subjectId=<optional>
Authorization: Bearer <token>
```

### Unlock Node
```http
POST /api/v1/skill-tree/:nodeId/unlock
Authorization: Bearer <token>
```

### Complete Node
```http
POST /api/v1/skill-tree/:nodeId/complete
Authorization: Bearer <token>
Content-Type: application/json

{
  "progressData": {
    "completedItems": ["item-id-1", "item-id-2"],
    "quizScore": 85,
    "attempts": 1,
    "bestScore": 85
  }
}
```

## Logic Unlock

1. **Root Nodes**: Tự động unlock khi tạo Skill Tree (nodes không có prerequisites)
2. **Child Nodes**: Tự động unlock khi hoàn thành parent node
3. **Prerequisites**: Phải hoàn thành tất cả prerequisites trước khi unlock
4. **XP Requirements**: Nếu có `requiredXP`, user phải có đủ XP

## Visual Structure

- **Tiers**: Nodes được chia thành các tiers (0, 1, 2, 3...)
- **Position**: Mỗi node có vị trí (x, y) trên tree
- **Colors**: Màu sắc dựa trên type và tier
- **Icons**: Icon khác nhau cho skill, boss, reward
- **Glow Effect**: Boss nodes có glow effect

## Game-like Features

1. **XP & Coins**: Nhận XP và Coins khi hoàn thành nodes
2. **Progress Tracking**: Track progress 0-100% cho mỗi node
3. **Unlock Animations**: (Có thể thêm sau)
4. **Achievements**: (Có thể tích hợp với achievement system)
5. **Visual Feedback**: Colors, icons, glow effects

## Migration từ Roadmap

- Roadmap vẫn tồn tại (legacy)
- Skill Tree là hệ thống mới
- Có thể chạy song song hoặc migrate dần
- Dashboard đã được update để dùng Skill Tree

## Flutter Integration

### Routes
- `/skill-tree` - Skill Tree screen
- `/skill-tree?subjectId=<id>` - Skill Tree cho subject cụ thể

### API Service Methods
- `generateSkillTree(subjectId)`
- `getSkillTree({subjectId})`
- `unlockSkillNode(nodeId)`
- `completeSkillNode(nodeId, {progressData})`

## Next Steps

1. ✅ Entities created
2. ✅ Service & Controller created
3. ✅ Flutter screen created
4. ⏳ Visual tree connections (lines between nodes)
5. ⏳ Unlock animations
6. ⏳ Better visual design
7. ⏳ Integration với learning flow

