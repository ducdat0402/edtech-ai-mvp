# 🚀 Next Steps - EdTech AI MVP

## 📋 Tổng quan

Backend đã có đầy đủ core features, bây giờ cần:
1. **Test & hoàn thiện** các tính năng đã implement
2. **Implement tính năng còn thiếu** (Leaderboard)
3. **Tối ưu & cải thiện** performance và UX
4. **Chuẩn bị cho Frontend** (API docs, error handling)

---

## 🎯 Ưu tiên cao (Làm ngay)

### 1. Test các tính năng chưa test đầy đủ

#### 1.1. Content Completion Flow
- [ ] Test complete content items (concepts, examples, hidden rewards, boss quiz)
- [ ] Verify auto-rewards (XP, coins, shards)
- [ ] Test progress tracking và HUD updates
- [ ] Test node completion và unlock next nodes

**API cần test:**
```bash
POST /api/v1/progress/complete-item
GET /api/v1/progress/node/:nodeId
GET /api/v1/content/node/:nodeId
```

#### 1.2. Daily Quests System
- [ ] Test get daily quests
- [ ] Test quest progress tracking (auto-update khi complete items)
- [ ] Test claim quest rewards
- [ ] Test quest auto-generation mỗi ngày

**API cần test:**
```bash
GET /api/v1/quests/daily
POST /api/v1/quests/:questId/claim
```

#### 1.3. Onboarding AI Chat
- [ ] Test chat flow với Gemini AI
- [ ] Test slot filling (extract user data)
- [ ] Test auto-save onboarding data
- [ ] Test onboarding completion

**API cần test:**
```bash
POST /api/v1/onboarding/chat
GET /api/v1/onboarding/status
```

#### 1.4. Unlock Mechanism
- [ ] Test unlock Scholar subject với coins
- [ ] Test unlock với payment (mock)
- [ ] Test unlock transactions history

**API cần test:**
```bash
POST /api/v1/unlock/scholar
GET /api/v1/unlock/transactions
```

---

### 2. Implement Leaderboard

**Tính năng:**
- Global leaderboard (top users by XP)
- Weekly leaderboard (reset mỗi tuần)
- Subject-specific leaderboard
- Friends leaderboard (sau này)

**Cần implement:**
- [ ] Leaderboard entity/service
- [ ] Redis caching cho leaderboard (hot data)
- [ ] Scheduled job để update leaderboard
- [ ] API endpoints

**API endpoints:**
```
GET /api/v1/leaderboard/global?limit=100
GET /api/v1/leaderboard/weekly?limit=100
GET /api/v1/leaderboard/subject/:subjectId?limit=100
GET /api/v1/leaderboard/me (user's rank)
```

---

## 🔧 Ưu tiên trung bình (Làm sau)

### 3. Tích hợp Redis cho Performance

**Use cases:**
- [ ] Cache leaderboard data (hot data)
- [ ] Cache user sessions
- [ ] Cache daily quests (tránh regenerate nhiều lần)
- [ ] Rate limiting cho API

**Files cần tạo:**
- `backend/src/config/redis.config.ts`
- `backend/src/common/cache/cache.service.ts`

---

### 4. Cải thiện Error Handling & Validation

- [ ] Global exception filter
- [ ] Custom error responses (consistent format)
- [ ] Better validation messages
- [ ] API error documentation

**Files cần tạo:**
- `backend/src/common/filters/http-exception.filter.ts`
- `backend/src/common/interceptors/transform.interceptor.ts`

---

### 5. API Documentation (Swagger)

- [ ] Setup Swagger/OpenAPI
- [ ] Document tất cả endpoints
- [ ] Add request/response examples
- [ ] Add authentication docs

**Command:**
```bash
npm install @nestjs/swagger swagger-ui-express
```

---

### 6. Testing Improvements

- [ ] Unit tests cho services
- [ ] Integration tests cho API endpoints
- [ ] E2E tests cho critical flows
- [ ] Test coverage reports

---

## 🎨 Ưu tiên thấp (Nice to have)

### 7. Additional Features

- [ ] Notifications system (in-app)
- [ ] Achievement badges
- [ ] Social features (follow, share progress)
- [ ] Analytics & reporting

### 8. Performance Optimization

- [ ] Database query optimization
- [ ] Add indexes cho frequently queried fields
- [ ] Implement pagination cho list endpoints
- [ ] Add response compression

### 9. Security Enhancements

- [ ] Rate limiting
- [ ] Input sanitization
- [ ] SQL injection prevention (TypeORM đã có)
- [ ] XSS prevention
- [ ] CORS configuration

---

## 📱 Chuẩn bị cho Flutter App

### 10. API Improvements for Mobile

- [ ] Add pagination cho tất cả list endpoints
- [ ] Add filtering & sorting
- [ ] Optimize response size (chỉ trả về fields cần thiết)
- [ ] Add image upload endpoints (nếu cần)
- [ ] Add push notification endpoints

### 11. API Versioning

- [ ] Setup API versioning strategy
- [ ] Document breaking changes
- [ ] Maintain backward compatibility

---

## 🎯 Recommended Order

**Tuần 1:**
1. Test Content Completion Flow
2. Test Daily Quests
3. Test Onboarding AI Chat

**Tuần 2:**
4. Implement Leaderboard
5. Tích hợp Redis cho leaderboard

**Tuần 3:**
6. Setup Swagger documentation
7. Cải thiện error handling
8. Write unit tests

**Tuần 4:**
9. Performance optimization
10. Security enhancements
11. Prepare for Flutter integration

---

## 💡 Quick Wins (Có thể làm ngay)

1. **Add more seed data** - Thêm nhiều subjects, nodes, questions
2. **Improve test scripts** - Tạo comprehensive test suite
3. **Add logging** - Winston/Pino cho better debugging
4. **Environment config** - Better .env validation
5. **Health check endpoint** - `/api/v1/health`

---

## 📝 Notes

- Tất cả tính năng core đã được implement
- Database schema đã hoàn chỉnh
- API structure đã ổn định
- Cần focus vào testing và polish

**Next immediate action:** Test Content Completion Flow và Daily Quests!

