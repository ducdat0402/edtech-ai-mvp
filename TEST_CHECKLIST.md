# Test Checklist - EdTech AI MVP

## 📋 Tổng quan

Checklist này giúp test toàn bộ tính năng của ứng dụng EdTech AI MVP. Test theo thứ tự từ trên xuống để đảm bảo flow hoàn chỉnh.

---

## 🔐 1. Authentication Flow

### 1.1 Registration
- [ ] Mở app → Hiển thị Login screen
- [ ] Tap "Đăng ký" → Navigate to Register screen
- [ ] Nhập thông tin:
  - [ ] Email hợp lệ
  - [ ] Password (tối thiểu 6 ký tự)
  - [ ] Full name
- [ ] Submit → Success message
- [ ] Auto navigate to Dashboard
- [ ] Error cases:
  - [ ] Email đã tồn tại → Error message
  - [ ] Email không hợp lệ → Validation error
  - [ ] Password quá ngắn → Validation error

### 1.2 Login
- [ ] Nhập email/password đúng → Login thành công
- [ ] Navigate to Dashboard
- [ ] Token được lưu
- [ ] Error cases:
  - [ ] Email/password sai → Error message
  - [ ] Email không hợp lệ → Validation error
  - [ ] Network error → Error handling

### 1.3 Logout
- [ ] Từ Dashboard → Tap menu → Logout
- [ ] Confirmation dialog hiển thị
- [ ] Confirm → Navigate to Login
- [ ] Token được clear
- [ ] Cancel → Stay on Dashboard

---

## 🤖 2. Onboarding Flow

### 2.1 Onboarding Chat
- [ ] Từ Dashboard hoặc sau Register → Navigate to Onboarding
- [ ] AI greeting message hiển thị
- [ ] Typing animation hoạt động
- [ ] Nhập message → Send
- [ ] AI response hiển thị
- [ ] Missing slots display cập nhật
- [ ] Complete 4 turns:
  - [ ] Turn 1: Nickname
  - [ ] Turn 2: Age
  - [ ] Turn 3: Current Level
  - [ ] Turn 4: Target Goal
- [ ] "Xong / Test thôi" button hiển thị
- [ ] Tap button → Navigate to Placement Test

### 2.2 Onboarding Status
- [ ] Check onboarding status API
- [ ] Nếu đã complete → Skip onboarding
- [ ] Nếu chưa complete → Show onboarding

---

## 📝 3. Placement Test Flow

### 3.1 Start Test
- [ ] Từ Onboarding → Navigate to Placement Test
- [ ] Test được tạo tự động
- [ ] Question đầu tiên hiển thị
- [ ] Progress bar hiển thị (0/N)

### 3.2 Answer Questions
- [ ] Select answer → Answer được highlight
- [ ] Submit answer → Next question
- [ ] Progress bar cập nhật
- [ ] Adaptive algorithm:
  - [ ] Câu đúng → Câu khó hơn
  - [ ] Câu sai → Câu dễ hơn
  - [ ] Questions liên quan đến subject đã chọn

### 3.3 Complete Test
- [ ] Hoàn thành N questions
- [ ] Navigate to Analysis Complete
- [ ] Test results được lưu

---

## 📊 4. Analysis Complete Screen

### 4.1 Display Results
- [ ] Score hiển thị (%)
- [ ] Level hiển thị (Beginner/Intermediate/Advanced)
- [ ] Strengths list hiển thị
- [ ] Weaknesses list hiển thị
- [ ] Improvement plan hiển thị
- [ ] Roadmap preview hiển thị

### 4.2 Navigation
- [ ] "Dashboard" button → Navigate to Dashboard
- [ ] "Bắt đầu học" button → Navigate to Subject Intro hoặc Roadmap
- [ ] Recommended subject được chọn đúng

---

## 📚 5. Subject & Learning Flow

### 5.1 Subject Introduction
- [ ] Navigate to Subject Intro
- [ ] Subject header hiển thị
- [ ] Knowledge graph hiển thị:
  - [ ] Nodes với positions
  - [ ] Edges connecting nodes
  - [ ] Fog of War effect
  - [ ] Locked/Unlocked states
- [ ] Tutorial overlay hiển thị (4 steps)
- [ ] Course outline hiển thị
- [ ] "Bắt đầu học" button → Navigate to Node Map

### 5.2 Learning Node Map
- [ ] Node map hiển thị
- [ ] Nodes với states:
  - [ ] Locked (grey)
  - [ ] Unlocked (blue)
  - [ ] Completed (green)
- [ ] Edges connecting nodes
- [ ] Fog overlay cho locked nodes
- [ ] Tap node → Navigate to Node Detail
- [ ] List view toggle hoạt động
- [ ] Info button → Show explanation

### 5.3 Node Detail
- [ ] Node title/description hiển thị
- [ ] Content structure stats:
  - [ ] Concepts count
  - [ ] Examples count
  - [ ] Quizzes count
- [ ] Progress HUD hiển thị
- [ ] Content items list hiển thị
- [ ] Grouped by type
- [ ] Tap content item → Navigate to Content Viewer

### 5.4 Content Viewer
- [ ] Content type detection:
  - [ ] Text/Image → Display content
  - [ ] Code → Display với syntax highlighting
  - [ ] Quiz → Interactive multiple choice
  - [ ] Reward → Hidden reward display
- [ ] Quiz interaction:
  - [ ] Select answer
  - [ ] Submit → Show feedback
  - [ ] Correct/Incorrect message
  - [ ] Score calculation
- [ ] "Mark Complete" button
- [ ] Complete → Update progress
- [ ] Navigate back → Progress updated

---

## 🗺️ 6. Roadmap Flow

### 6.1 Roadmap Display
- [ ] Navigate to Roadmap
- [ ] Roadmap header hiển thị:
  - [ ] Level badge
  - [ ] Current day (X/30)
  - [ ] Date range
- [ ] Today's lesson card hiển thị:
  - [ ] Day number
  - [ ] Title/Description
  - [ ] Estimated minutes
  - [ ] Status (pending/completed)
- [ ] 30-day grid hiển thị:
  - [ ] Today highlighted (orange)
  - [ ] Completed days (green)
  - [ ] Current day (blue)
  - [ ] Review days (purple "R" badge)

### 6.2 Today's Lesson
- [ ] Tap "Bắt đầu học" → Navigate to Node Detail
- [ ] Complete lesson → Mark as completed
- [ ] "Xem lại" button nếu đã complete

### 6.3 Day Completion
- [ ] Complete day → Update status
- [ ] Success message hiển thị
- [ ] Roadmap reload

---

## 🎮 7. Gamification Flow

### 7.1 Streak Display
- [ ] Dashboard → Streak section hiển thị
- [ ] Current streak number
- [ ] Consecutive perfect days
- [ ] Weekly progress calendar
- [ ] Streak milestones hiển thị

### 7.2 Daily Quests
- [ ] Navigate to Daily Quests
- [ ] Quest list hiển thị:
  - [ ] Quest title/description
  - [ ] Progress bar
  - [ ] Progress text (X/Y)
  - [ ] Rewards display
- [ ] Quest types với icons:
  - [ ] Complete items (blue)
  - [ ] Maintain streak (orange)
  - [ ] Earn coins (amber)
  - [ ] Earn XP (purple)
  - [ ] Complete node (green)
  - [ ] Complete daily lesson (teal)
- [ ] Complete quest → "Nhận phần thưởng" button
- [ ] Claim reward → Success message
- [ ] Quest status updated (claimed)
- [ ] History tab hiển thị completed quests

### 7.3 Leaderboard
- [ ] Navigate to Leaderboard
- [ ] My rank card hiển thị (nếu có)
- [ ] Tabs: Global, Weekly, Subject
- [ ] Leaderboard entries hiển thị:
  - [ ] Rank number
  - [ ] User name
  - [ ] XP/Streak/Coins
  - [ ] Top 3 với icons (gold, silver, bronze)
- [ ] Current user highlighted
- [ ] Refresh button hoạt động

---

## 📊 8. Dashboard Flow

### 8.1 Dashboard Display
- [ ] Streak section hiển thị
- [ ] Stats cards (XP, Coins, Streak)
- [ ] Quick Actions:
  - [ ] Quests button → Navigate to Quests
  - [ ] Leaderboard button → Navigate to Leaderboard
  - [ ] Roadmap button → Navigate to Roadmap
- [ ] Daily Quests preview (3 items)
- [ ] "Xem tất cả" button → Navigate to Quests
- [ ] Explorer Subjects list
- [ ] Scholar Subjects list

### 8.2 Subject Navigation
- [ ] Tap subject card → Navigate to Subject Intro
- [ ] Track badge hiển thị (Explorer/Scholar)
- [ ] Color coding đúng

### 8.3 Bottom Navigation
- [ ] Dashboard tab → Active
- [ ] Quests tab → Navigate to Quests
- [ ] Ranking tab → Navigate to Leaderboard
- [ ] Profile tab → Navigate to Profile

---

## 👤 9. Profile Flow

### 9.1 Profile Display
- [ ] Navigate to Profile
- [ ] Avatar section hiển thị:
  - [ ] Avatar circle
  - [ ] Frame border (nếu có)
  - [ ] Background color
- [ ] Username/Role hiển thị
- [ ] Minimal view:
  - [ ] Streak display
  - [ ] Mini stats (XP, Coins, Streak)

### 9.2 Detailed View
- [ ] Toggle button → Switch to detailed view
- [ ] Profile info:
  - [ ] Full name
  - [ ] Email
  - [ ] Phone (nếu có)
- [ ] Stats section:
  - [ ] XP, Coins, Streak, Shards
- [ ] Onboarding data:
  - [ ] Nickname, Age, Level, Goal, Daily Time
- [ ] Placement test info:
  - [ ] Score, Level

---

## 🎨 10. UX & Error Handling

### 10.1 Loading States
- [ ] Skeleton loaders hiển thị khi loading
- [ ] Shimmer animation hoạt động
- [ ] Loading states cho:
  - [ ] Dashboard
  - [ ] Profile
  - [ ] Roadmap
  - [ ] Quests
  - [ ] Leaderboard

### 10.2 Error Handling
- [ ] Network error → NetworkErrorWidget
- [ ] Not found → NotFoundErrorWidget
- [ ] Generic error → AppErrorWidget
- [ ] Retry button hoạt động
- [ ] Error messages rõ ràng

### 10.3 Empty States
- [ ] Empty quests → EmptyQuestsWidget
- [ ] Empty leaderboard → EmptyLeaderboardWidget
- [ ] Empty roadmap → Empty state với action
- [ ] Empty lists → EmptyListWidget

### 10.4 Pull-to-Refresh
- [ ] Dashboard → Pull to refresh
- [ ] Profile → Pull to refresh
- [ ] Roadmap → Pull to refresh
- [ ] Quests → Pull to refresh
- [ ] Leaderboard → Pull to refresh

---

## 🔄 11. Navigation Flow

### 11.1 Complete User Journey
- [ ] Register → Dashboard
- [ ] Onboarding → Placement Test
- [ ] Placement Test → Analysis
- [ ] Analysis → Subject Intro
- [ ] Subject Intro → Node Map
- [ ] Node Map → Node Detail
- [ ] Node Detail → Content Viewer
- [ ] Content Viewer → Back to Node Detail
- [ ] Complete content → Progress updated
- [ ] Complete node → Node marked as completed
- [ ] Roadmap → Today's lesson
- [ ] Complete quest → Claim reward
- [ ] Leaderboard → View rankings
- [ ] Profile → View stats

### 11.2 Back Navigation
- [ ] Back button hoạt động đúng
- [ ] Navigation stack đúng
- [ ] Deep linking hoạt động

---

## 🧪 12. Edge Cases

### 12.1 Network Issues
- [ ] No internet → Network error
- [ ] Slow connection → Loading states
- [ ] Timeout → Error handling
- [ ] Retry functionality

### 12.2 Data Issues
- [ ] Empty data → Empty states
- [ ] Invalid data → Error handling
- [ ] Missing data → Fallback values

### 12.3 Authentication Issues
- [ ] Token expired → Redirect to login
- [ ] Invalid token → Error handling
- [ ] No token → Redirect to login

---

## ✅ Test Results

### Test Date: ___________
### Tester: ___________
### Environment: ___________

### Summary
- Total Tests: ___
- Passed: ___
- Failed: ___
- Skipped: ___

### Notes
_________________________________________________
_________________________________________________
_________________________________________________

---

## 🐛 Known Issues

1. _________________________________________________
2. _________________________________________________
3. _________________________________________________

---

## 📝 Test Log

| Date | Feature | Status | Notes |
|------|---------|--------|-------|
|      |         |        |       |
|      |         |        |       |
|      |         |        |       |

---

**Last Updated**: $(date)


