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
- [ ] Explorer Subjects screen
- [ ] Scholar Subjects screen
- [ ] Subject detail screen
- [ ] Unlock mechanism UI (Coins + Payment)

### 7. Learning Node Map (Fog of War)
- [ ] Node map visualization
- [ ] Fog of War effect (chỉ hiện unlocked nodes)
- [ ] Node states (locked, unlocked, completed)

### 8. Content Item Viewer
- [ ] Content item screen
- [ ] Video/image display
- [ ] Quiz interaction
- [ ] Complete item và nhận rewards

### 9. Progress Tracking
- [ ] Node progress screen với HUD
- [ ] Progress percentage visualization

---

## 📋 Recommended Order

### Week 1: Core Polish
1. Fix login issue
2. Improve dashboard UI
3. Add logout

### Week 2: Onboarding & Testing
4. Onboarding AI Chat
5. Placement Test

### Week 3: Learning Core
6. Subject Lists
7. Learning Node Map
8. Content Item Viewer

### Week 4: Roadmap & Quests
9. Daily Quests
10. Integration testing

### Week 5: Polish & Gamification
11. Leaderboard
12. Currency Display
13. UI/UX improvements

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
