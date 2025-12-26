# 🚀 Next Steps - Development Roadmap

## 📊 Current Status

### ✅ Completed
- **Backend**: 100% complete, production ready
- **Flutter Setup**: Project structure, API client, routing
- **Authentication**: Login & Register screens (cần test và fix nếu còn lỗi)
- **Dashboard**: Basic dashboard với stats, quests, subjects

### 🚧 In Progress / Next Priority

---

## 🎯 Phase 1: Fix & Polish Core Features (Ưu tiên cao)

### 1. Fix Login Issue ⚠️
**Status**: Cần test và fix
- [ ] Test login flow end-to-end
- [ ] Fix response parsing nếu còn lỗi
- [ ] Ensure token được save và sử dụng đúng
- [ ] Test auto-redirect sau login

**Estimated**: 1-2 hours

### 2. Improve Dashboard UI
**Status**: Cần cải thiện
- [ ] Better UI/UX design
- [ ] Add loading states
- [ ] Add error handling UI
- [ ] Add pull-to-refresh animation
- [ ] Make subjects clickable → navigate to subject detail

**Estimated**: 2-3 hours

### 3. Add Logout Functionality
**Status**: Chưa có
- [ ] Add logout button trong dashboard
- [ ] Clear token và redirect to login
- [ ] Add confirmation dialog

**Estimated**: 30 minutes

---

## 🎯 Phase 2: Onboarding & Placement Test (Ưu tiên cao)

### 4. Onboarding AI Chat Screen
**Status**: Chưa có
- [ ] Create onboarding chat screen
- [ ] Integrate với Gemini API (qua backend)
- [ ] Chat UI với message bubbles
- [ ] Auto-save onboarding data
- [ ] Progress indicator

**API**: `POST /onboarding/chat`, `GET /onboarding/status`

**Estimated**: 4-6 hours

### 5. Placement Test Screen
**Status**: Chưa có
- [ ] Create placement test screen
- [ ] Adaptive question flow
- [ ] Question display với options
- [ ] Progress bar
- [ ] Submit answer và get next question
- [ ] Results screen với level recommendation

**API**: `POST /test/start`, `POST /test/submit`, `GET /test/result/:id`

**Estimated**: 4-6 hours

---

## 🎯 Phase 3: Learning Features (Ưu tiên trung bình)

### 6. Subject List Screens
**Status**: Chưa có
- [ ] Explorer Subjects screen
- [ ] Scholar Subjects screen
- [ ] Subject detail screen
- [ ] Unlock mechanism UI (Coins + Payment)

**API**: `GET /subjects/explorer`, `GET /subjects/scholar`, `POST /unlock/scholar`

**Estimated**: 3-4 hours

### 7. Learning Node Map (Fog of War)
**Status**: Chưa có
- [ ] Node map visualization
- [ ] Fog of War effect (chỉ hiện unlocked nodes)
- [ ] Node states (locked, unlocked, completed)
- [ ] Tap node → navigate to node detail

**API**: `GET /nodes/subject/:subjectId`

**Estimated**: 6-8 hours (phức tạp)

### 8. Content Item Viewer
**Status**: Chưa có
- [ ] Content item screen (concept, example, hidden reward, boss quiz)
- [ ] Video/image display
- [ ] Quiz interaction
- [ ] Complete item và nhận rewards
- [ ] Progress HUD update

**API**: `GET /content/node/:nodeId`, `POST /progress/complete-item`

**Estimated**: 4-5 hours

### 9. Progress Tracking
**Status**: Chưa có
- [ ] Node progress screen với HUD
- [ ] Progress percentage visualization
- [ ] Completed items list
- [ ] Rewards display

**API**: `GET /progress/node/:nodeId`

**Estimated**: 2-3 hours

---

## 🎯 Phase 4: Roadmap & Quests (Ưu tiên trung bình)

### 10. Roadmap Screen
**Status**: Chưa có
- [ ] Roadmap generation screen
- [ ] 30-day roadmap view
- [ ] Today's lesson highlight
- [ ] Complete day functionality
- [ ] Spaced repetition indicators

**API**: `POST /roadmap/generate`, `GET /roadmap/:id/today`, `POST /roadmap/:id/complete-day`

**Estimated**: 4-5 hours

### 11. Daily Quests Screen
**Status**: Chưa có
- [ ] Daily quests list
- [ ] Quest progress visualization
- [ ] Claim rewards button
- [ ] Quest history

**API**: `GET /quests/daily`, `POST /quests/:id/claim`, `GET /quests/history`

**Estimated**: 3-4 hours

---

## 🎯 Phase 5: Gamification (Ưu tiên thấp)

### 12. Leaderboard Screen
**Status**: Chưa có
- [ ] Global leaderboard
- [ ] Weekly leaderboard
- [ ] Subject-specific leaderboard
- [ ] User rank display
- [ ] Tabs để switch giữa các loại

**API**: `GET /leaderboard/global`, `GET /leaderboard/weekly`, `GET /leaderboard/me`

**Estimated**: 3-4 hours

### 13. Currency & Rewards Display
**Status**: Chưa có
- [ ] Currency screen (XP, Coins, Streak, Shards)
- [ ] Rewards history
- [ ] Achievement badges (future)

**API**: `GET /currency`

**Estimated**: 2-3 hours

---

## 📋 Recommended Order

### Week 1: Core Polish
1. ✅ Fix login issue
2. ✅ Improve dashboard UI
3. ✅ Add logout
4. ✅ Test end-to-end auth flow

### Week 2: Onboarding & Testing
5. ✅ Onboarding AI Chat
6. ✅ Placement Test
7. ✅ Test onboarding → placement → roadmap flow

### Week 3: Learning Core
8. ✅ Subject Lists
9. ✅ Learning Node Map (Fog of War)
10. ✅ Content Item Viewer
11. ✅ Progress Tracking

### Week 4: Roadmap & Quests
12. ✅ Roadmap Screen
13. ✅ Daily Quests
14. ✅ Integration testing

### Week 5: Polish & Gamification
15. ✅ Leaderboard
16. ✅ Currency Display
17. ✅ UI/UX improvements
18. ✅ Performance optimization

---

## 🎨 UI/UX Improvements (Ongoing)

- [ ] Consistent color scheme (Explorer: Green, Scholar: Blue)
- [ ] Loading animations
- [ ] Error states với retry
- [ ] Empty states
- [ ] Pull-to-refresh animations
- [ ] Navigation transitions
- [ ] Responsive design

---

## 🧪 Testing Checklist

- [ ] Auth flow (register → login → dashboard)
- [ ] Onboarding → Placement Test → Roadmap generation
- [ ] Subject unlock (Coins + Payment)
- [ ] Learning flow (Node → Content → Complete)
- [ ] Quest completion và claim rewards
- [ ] Leaderboard display
- [ ] Error handling (network, API errors)
- [ ] Offline handling (future)

---

## 📝 Notes

- **Backend đã sẵn sàng**: Tất cả APIs đã implement và test
- **Swagger Docs**: `http://localhost:3000/api/v1/docs` để reference
- **Priority**: Focus vào core learning flow trước (Onboarding → Test → Roadmap → Learning)
- **UI/UX**: Có thể improve dần, không cần perfect ngay

---

## 🚀 Quick Start Next Step

**Bước tiếp theo ngay:**
1. Fix login issue (nếu còn)
2. Test auth flow end-to-end
3. Bắt đầu làm Onboarding AI Chat screen

**Command để start:**
```bash
# Backend
cd backend
npm start

# Flutter (terminal khác)
cd mobile
flutter run
```

