# Implementation Roadmap - EdTech AI MVP

## Tổng quan
Kế hoạch triển khai dựa trên tất cả yêu cầu đã được cung cấp, được chia thành 4 phases chính với priority rõ ràng.

---

## 📋 Phase 1: Core Flow Enhancement (Priority: HIGH)
**Mục tiêu**: Hoàn thiện MAIN FLOW chính của ứng dụng

### 1.1 Enhanced Onboarding System
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Backend Tasks:
- [ ] Update `OnboardingService` để track 5 fields mới:
  - `nickname` (Biệt danh)
  - `age` (Tuổi)
  - `currentLevel` (beginner/intermediate/advanced)
  - `targetGoal` (Mục tiêu học tập)
  - `dailyTime` (Thời gian học/ngày - phút)
- [ ] Implement termination conditions:
  - Slot Filling: Check đủ 5 fields
  - Turn Count Limit: Max 7 turns
  - Hybrid UI: Return `canProceed` flag
- [ ] Update `AiService.extractOnboardingData()` để extract 5 fields mới
- [ ] Update `AiService.generateOnboardingResponse()` với termination logic
- [ ] Add typing animation support (streaming response)

#### Frontend Tasks:
- [ ] Update `OnboardingChatScreen` với typing animation
- [ ] Add "Xong / Test thôi" button (hiện khi `canProceed: true`)
- [ ] Display turn count và missing slots
- [ ] Handle termination states

**Dependencies**: None  
**Blocks**: Placement Test logic

---

### 1.2 Enhanced Placement Test
**Status**: ⏳ Pending  
**Estimated Time**: 3-4 days

#### Backend Tasks:
- [ ] Update `PlacementTestService.startTest()`:
  - Check `currentLevel` từ onboarding
  - Nếu `beginner` → Return test với `status: SKIPPED`
  - Nếu không → Tạo adaptive test
- [ ] Implement adaptive test logic:
  - Start với 1 Medium question
  - Track topic performance (VLOOKUP, Pivot Table, etc.)
  - Drill-down: Nếu sai → Câu hỏi dễ hơn cùng topic
  - Move on: Nếu đúng 2 lần liên tiếp → Tăng độ khó hoặc đổi topic
- [ ] Add `topic` field vào Question entity
- [ ] Update `submitAnswer()` với adaptive logic
- [ ] Generate next question based on performance

#### Frontend Tasks:
- [ ] Handle `SKIPPED` test status → Navigate to Subject Intro
- [ ] Display adaptive test progress
- [ ] Show topic being tested

**Dependencies**: Enhanced Onboarding (currentLevel)  
**Blocks**: Test Results Analysis

---

### 1.3 Test Results Analysis Screen
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Backend Tasks:
- [ ] Create `PlacementTestAnalysisService`:
  - Analyze topic performance
  - Identify strengths (>80% correct)
  - Identify weaknesses (<60% correct)
  - Generate immediate goals (AI-powered)
  - Generate future improvements (AI-powered)
- [ ] Add endpoint: `GET /test/results/:testId/analysis`
- [ ] Integrate với AI để generate personalized insights

#### Frontend Tasks:
- [ ] Create `AnalysisCompleteScreen`:
  - Strengths card (green)
  - Weaknesses card (red)
  - Improvement strategy card (yellow)
  - Custom roadmap preview (blue)
  - "Start Learning Journey" button
- [ ] Implement skeleton loader cho long text
- [ ] Add "Xem thêm" expansion cho weaknesses

**Dependencies**: Enhanced Placement Test  
**Blocks**: Subject Intro, Roadmap

---

### 1.4 Subject Introduction Screen
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Backend Tasks:
- [ ] Add endpoint: `GET /subjects/:id/intro`
- [ ] Build knowledge graph structure:
  - Nodes với position (x, y)
  - Edges (prerequisites)
  - Unlock status
- [ ] Generate tutorial steps (4 steps)
- [ ] Return course outline data

#### Frontend Tasks:
- [ ] Create `SubjectIntroScreen`:
  - Knowledge Graph visualization với animation
  - Tutorial overlay (step-by-step)
  - Highlight elements (Explorer vs Scholar sections)
  - "Bỏ qua" button
- [ ] Animate node unlocking
- [ ] Interactive tutorial flow

**Dependencies**: Test Results Analysis  
**Blocks**: Roadmap display

---

## 🎯 Phase 2: Points & Content System (Priority: HIGH)
**Mục tiêu**: Hệ thống điểm và cấu trúc nội dung

### 2.1 L-Points & C-Points System
**Status**: ⏳ Pending  
**Estimated Time**: 4-5 days

#### Backend Tasks:
- [ ] Create `PointsCalculationService`:
  - Base points theo lesson type
  - Difficulty multipliers
  - Performance multipliers
  - Streak bonus calculation
- [ ] Create `LevelCalculationService`:
  - XP → Level conversion
  - Level progress tracking
  - Level up detection
- [ ] Update `ContentItem` entity:
  - Add `lessonType` enum (microlesson, standard_lesson, module, mini_assessment, full_assessment)
  - Add `difficulty` enum (extremely_low, low, medium, high, asian)
  - Add `estimatedMinutes`
- [ ] Migration: Đổi `xp` → `lPoints` trong database
- [ ] Update `UserCurrency` entity:
  - `lPoints` (thay `xp`)
  - `cPoints` (mới)
  - `streakData` (tracking)
- [ ] Update `UserProgressService.completeContentItem()`:
  - Tính L-Points với công thức mới
  - Tính C-Points (nếu là assessment)
  - Check level up
- [ ] Update all XP references → L-Points

#### Frontend Tasks:
- [ ] Update UI để hiển thị L-Points thay XP
- [ ] Add C-Points display
- [ ] Level progress bar
- [ ] Level up animation

**Dependencies**: None  
**Blocks**: Content structure updates

---

### 2.2 Content Structure Enhancement
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Backend Tasks:
- [ ] Update `ContentItem` entity với fields mới (đã list ở 2.1)
- [ ] Add `contentFlow` structure:
  - `hook` (video/image/interactive)
  - `context` (text/audio)
  - `action` (quiz/simulation)
- [ ] Add `rewards` structure:
  - `hiddenReward` flag
  - `unlockAtProgress` (60%, 80%)
- [ ] Update seed data với lesson types và difficulties

#### Frontend Tasks:
- [ ] Display lesson type và difficulty
- [ ] Show estimated time
- [ ] Content flow UI (hook → context → action)

**Dependencies**: L-Points System  
**Blocks**: Hidden Rewards

---

### 2.3 Hidden Rewards & Boss Quiz
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Backend Tasks:
- [ ] Add `checkHiddenRewards()` method:
  - Check progress milestones (60%, 80%)
  - Random reward logic
  - Unlock rewards
- [ ] Add `canUnlockBossQuiz()` method:
  - Check 90% progress
  - Return unlock status
- [ ] Update `completeContentItem()`:
  - Check hidden rewards
  - Check boss quiz unlock
  - Award milestone rewards

#### Frontend Tasks:
- [ ] Hidden reward animation
- [ ] Boss quiz unlock notification
- [ ] Progress milestone indicators

**Dependencies**: Content Structure  
**Blocks**: None

---

## 🌉 Phase 3: Explorer → Scholar Bridge (Priority: MEDIUM)
**Mục tiêu**: Kết nối 2 nhánh học tập

### 3.1 Explorer → Scholar Bridge
**Status**: ⏳ Pending  
**Estimated Time**: 3-4 days

#### Backend Tasks:
- [ ] Update `RoadmapService.generateScholarRoadmap()`:
  - Check Explorer progress
  - Apply 20% endowed progress nếu đã hoàn thành Explorer
  - Mark 20% đầu là completed
- [ ] Update `SubjectsService.unlockScholarSubject()`:
  - Validate Coin requirements
  - Support 2 payment methods:
    - 100% Coins
    - 20% Coins + 80% Cash (validate min 20% coins)
  - Return unlock status với messages
- [ ] Add validation: Không đủ 20% coins → Disable cash payment

#### Frontend Tasks:
- [ ] Scholar unlock screen với options
- [ ] Payment method selection
- [ ] Validation messages
- [ ] Progress transfer animation (20%)

**Dependencies**: Roadmap system  
**Blocks**: Item system

---

### 3.2 Item System
**Status**: ⏳ Pending  
**Estimated Time**: 4-5 days

#### Backend Tasks:
- [ ] Create `Item` entity:
  - `type` (avatar, background, frame, badge, title, effect, power_up)
  - `rarity` (common, uncommon, rare, epic, legendary, mythic)
  - `function` (cosmetic, boost_xp, boost_coin, etc.)
  - `visual` (imageUrl, iconUrl, color, animationUrl)
  - `effect` (multipliers, duration)
  - `unlockConditions`
- [ ] Create `UserItem` entity:
  - Track owned items
  - Equipped status
  - Expiration (cho power-ups)
- [ ] Create `ItemsService`:
  - `getItems()` với filters
  - `equipItem()` logic
  - `purchaseItem()` logic
  - `applyPowerUp()` effects
- [ ] Create `ItemsController` với endpoints

#### Frontend Tasks:
- [ ] Items shop screen
- [ ] Equip item UI
- [ ] Purchase flow
- [ ] Power-up effects display

**Dependencies**: Explorer → Scholar Bridge  
**Blocks**: Profile system

---

### 3.3 Achievement System
**Status**: ⏳ Pending  
**Estimated Time**: 3-4 days

#### Backend Tasks:
- [ ] Create `Achievement` entity:
  - `type` (milestone, streak, completion, perfect_score, collection, social)
  - `requirements` (flexible JSON)
  - `rewards` (L-Points, coins, items)
- [ ] Create `UserAchievement` entity
- [ ] Create `AchievementsService`:
  - `checkAndUnlockAchievements()` - Auto-check khi có event
  - `unlockAchievement()` - Unlock và apply rewards
- [ ] Integrate với các services:
  - Level up → Check milestone achievements
  - Streak milestones → Check streak achievements
  - Complete node → Check completion achievements

#### Frontend Tasks:
- [ ] Achievements screen
- [ ] Achievement unlock animation
- [ ] Badge display

**Dependencies**: Item System  
**Blocks**: Profile system

---

### 3.4 Profile System
**Status**: ⏳ Pending  
**Estimated Time**: 3-4 days

#### Backend Tasks:
- [ ] Update `User` entity:
  - `avatarId`, `backgroundId`, `role`, `status`
  - `profileSettings` (privacy, visibility)
- [ ] Update `UsersService`:
  - `getProfile()` với mode (minimal/detailed)
  - `updateProfile()` với new fields
  - `getProfileStats()` - Mini dashboard data
- [ ] Create profile endpoints

#### Frontend Tasks:
- [ ] `ProfileMinimalScreen`:
  - Avatar với frame
  - Username & Role
  - Mini dashboard (XP, Level, Streak)
  - Achievements grid
  - Settings button
- [ ] `ProfileDetailedScreen`:
  - Full profile info
  - Settings với DropMenu
  - Privacy settings
  - Notification settings

**Dependencies**: Item System, Achievement System  
**Blocks**: None

---

## 🎨 Phase 4: UI Screens Implementation (Priority: MEDIUM)
**Mục tiêu**: Implement các màn hình UI dựa trên hình ảnh tham khảo

### 4.1 Skeleton Loader Component
**Status**: ⏳ Pending  
**Estimated Time**: 1 day

#### Tasks:
- [ ] Create reusable `SkeletonLoader` widget
- [ ] Add `shimmer` package
- [ ] Implement skeleton cho:
  - Text lines
  - Cards
  - Lists
- [ ] Use trong Test Results screen

**Dependencies**: None  
**Blocks**: Analysis Complete Screen

---

### 4.2 Analysis Complete Screen
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Tasks:
- [ ] Create `AnalysisCompleteScreen`:
  - Header với icon và title
  - Strengths card (green, left)
  - Weaknesses card (red, right)
  - Improvement strategy card (yellow, middle)
  - Custom roadmap card (blue, bottom)
  - "Start Learning Journey" button
- [ ] Implement skeleton loader cho long text
- [ ] Add expansion cho weaknesses
- [ ] Connect với backend analysis API

**Dependencies**: Skeleton Loader, Test Results Analysis  
**Blocks**: None

---

### 4.3 Video Lesson Screen
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Tasks:
- [ ] Add `video_player` và `chewie` packages
- [ ] Create `VideoLessonScreen`:
  - Progress indicators (top)
  - Video player với play button overlay
  - Lesson title overlay
  - Key Takeaways section
  - "Continue to Quiz" button
- [ ] Handle video playback
- [ ] Connect với content API

**Dependencies**: None  
**Blocks**: Lesson Viewer

---

### 4.4 Lesson Viewer Screen (Scholar Track)
**Status**: ⏳ Pending  
**Estimated Time**: 4-5 days

#### Tasks:
- [ ] Create `LessonViewerScreen`:
  - Header với module title và lesson title
  - Action buttons (bookmark, share, copy)
  - Tabs: Content, Simplify, Quiz, Example
  - Main content area với expandable sections
  - Navigation buttons (Previous, Mark Complete, Next)
- [ ] Create sidebar:
  - Course outline
  - Module list với expansion
  - Lesson list với active indicator
  - Progress indicators
- [ ] Implement tab switching
- [ ] Implement expandable sections
- [ ] Connect với content API

**Dependencies**: Video Lesson Screen  
**Blocks**: None

---

### 4.5 Gamified Streak Display
**Status**: ⏳ Pending  
**Estimated Time**: 2-3 days

#### Tasks:
- [ ] Create `StreakDisplay` widget:
  - Large streak number với glow effect
  - Flame icon với animation
  - Weekly progress (7 days)
  - Visual distinction: Weekdays (blue) vs Weekends (yellow)
  - Checkmarks cho completed days
  - Particles/glow effects
- [ ] Add to Dashboard hoặc Profile
- [ ] Connect với streak API

**Dependencies**: None  
**Blocks**: None

---

## 📊 Implementation Timeline

### Week 1-2: Phase 1 (Core Flow)
- Day 1-3: Enhanced Onboarding
- Day 4-7: Enhanced Placement Test
- Day 8-10: Test Results Analysis
- Day 11-13: Subject Introduction

### Week 3-4: Phase 2 (Points & Content)
- Day 14-18: L-Points & C-Points System
- Day 19-21: Content Structure Enhancement
- Day 22-24: Hidden Rewards & Boss Quiz

### Week 5-6: Phase 3 (Bridge & Systems)
- Day 25-28: Explorer → Scholar Bridge
- Day 29-33: Item System
- Day 34-37: Achievement System
- Day 38-41: Profile System

### Week 7-8: Phase 4 (UI Screens)
- Day 42: Skeleton Loader
- Day 43-45: Analysis Complete Screen
- Day 46-48: Video Lesson Screen
- Day 49-53: Lesson Viewer Screen
- Day 54-56: Streak Display

---

## 🔄 Dependencies Graph

```
Enhanced Onboarding
    ↓
Enhanced Placement Test
    ↓
Test Results Analysis → Subject Introduction
    ↓
L-Points System → Content Structure → Hidden Rewards
    ↓
Explorer → Scholar Bridge → Item System → Achievement System → Profile System
    ↓
UI Screens (parallel development)
```

---

## ✅ Next Immediate Steps

1. **Start với Phase 1.1: Enhanced Onboarding**
   - Update backend extraction logic
   - Add termination conditions
   - Update Flutter UI với typing animation

2. **Sau đó Phase 1.2: Enhanced Placement Test**
   - Implement adaptive logic
   - Add topic tracking

3. **Tiếp theo Phase 1.3: Test Results Analysis**
   - Create analysis service
   - Build UI screen

---

## 📝 Notes

- **Priority**: Phase 1 > Phase 2 > Phase 3 > Phase 4
- **Dependencies**: Cần follow đúng thứ tự để tránh conflicts
- **Testing**: Test từng phase trước khi chuyển phase tiếp theo
- **Documentation**: Update API docs sau mỗi phase

