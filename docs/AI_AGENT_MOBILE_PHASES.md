# AI Agent — Mobile phases (behavior → insights)

## Phase 1 — ✅ Hoàn thành

**Mục tiêu:** Ghi hành vi học lên backend (`user_behaviors`).

- `POST /ai-agents/behavior/track` qua `ApiService.trackAiBehavior` + `AiBehaviorTracker` (fire-and-forget).
- Điểm gắn: `node_detail`, `lesson_types_overview`, 4 màn lesson, `end_quiz` (`view`, `attempt_quiz`, `complete`, `contentItemId` khi có).

**Kiểm tra:** Đăng nhập → học vài thao tác → `GET /ai-agents/behavior/node/:nodeId` hoặc DB.

---

## Phase 2 — ✅ (slice hiện tại)

**Mục tiêu:** Đọc phản hồi từ AI agents và hiển thị cho học viên.

- `GET /ai-agents/mastery/:nodeId` → `ApiService.getAiMastery`
- `GET /ai-agents/its/adjust-difficulty` → `ApiService.getAiAdjustedDifficulty`
- `GET /ai-agents/behavior/node/:nodeId` → `ApiService.getAiNodeBehavior` (sẵn sàng cho màn debug / phase sau)

**UI:**

- `AiLearningInsightCard` trên **Node detail** (sau HUD tiến độ) và **Lesson types overview**.
- Gọi API sau khi load dữ liệu chính; lỗi mạng/401 thì ẩn card.

## Phase 3 — ✅ (DRL + ITS hint + Admin behaviors)

1. **DRL — bài tiếp theo**  
   - `GET /ai-agents/drl/next-node` → `ApiService.getAiDrlNextNode`  
   - UI: `DrlNextNodeCard` trên **Node detail** (cần `subjectId` trên node). Nút **Mở bài gợi ý** → `/nodes/:id`.

2. **ITS — gợi ý trong End quiz**  
   - `POST /ai-agents/its/hint` → `ApiService.requestAiItsHint`  
   - `contentItemId`: `end_quiz:{nodeId}:q{index}`  
   - Nút **Gợi ý AI (ITS)** trên từng câu; backend có thể gọi OpenAI.

3. **Admin — xem behaviors của user bất kỳ**  
   - Backend: `GET /analytics/user-behaviors?userId=&nodeId=&limit=` (JWT + **AdminGuard**).  
   - Mobile: `ApiService.getAdminUserBehaviors`  
   - UI: khối **AI — User behaviors** đầu tab **Analytics** trong Admin Panel.

---

## Phase 4 — ✅ LangChain kế hoạch ôn + analytics (trong lộ trình cá nhân)

**Mục tiêu:** Gom DRL/ITS/hành vi để **phân tích** và **xếp kế hoạch ôn ngắn hạn**; các bước DRL / fallback LangChain **chỉ chọn `learningNodeId` đã nằm trên personal mind map** (chat/placement). Nếu chưa có map hoặc chưa gắn bài → fallback như cũ (cả môn).

| API | `ApiService` |
|-----|----------------|
| `POST /ai-agents/langchain/roadmap` | `generateAiLangchainRoadmap` |
| `GET /ai-agents/its/recommendations` | `getAiItsRecommendations` |
| `GET /ai-agents/behavior/error-patterns` | `getAiErrorPatterns` |
| `GET /ai-agents/behavior/strengths-weaknesses` | `getAiStrengthsWeaknesses` |
| `GET /ai-agents/its/should-skip/:nodeId` | `getAiShouldSkipTopic` *(sẵn cho tích hợp thêm)* |

**UI:** màn `AiLearningCoachScreen` — route `/subjects/:id/ai-coach`.

- **Luồng chính:** **Chọn cách tạo lộ trình** / **Lộ trình của bạn** — Coach là lớp *theo dõi + gợi ý* trên map đã có, không thay chat/placement.
- **Lối tắt:** icon **biểu đồ** (`DomainsListScreen`) và Quick Action **Coach AI** (`Dashboard`).

- Chọn **7 / 14 / 30 ngày** (mặc định 14; 30 ngày có thể rất chậm do vòng lặp backend).
- Ô mục tiêu → **Tạo kế hoạch ôn (AI)** → `summary`, `confidence`, các bước **chỉ trong** lộ trình cá nhân (mở `/nodes/:id`).
- Phần trên: nhịp học, lỗi quiz, số bài mạnh/yếu, gợi ý ITS.

---

## Phase 5 — ✅ Quyền riêng tư, hub Dashboard, minh bạch hành vi

**Mục tiêu:** Người học kiểm soát được **ghi hành vi** và **gọi AI cloud**; vào Coach AI dễ hơn; xem **lịch sử sự kiện** trên từng bài.

### `AiUserPreferences` (`shared_preferences`)

| Tuỳ chọn (Hồ sơ → **AI & quyền riêng tư**) | Tác dụng |
|-------------------------------------------|----------|
| **Ghi nhận hành vi học** | Bật (mặc định): `AiBehaviorTracker` gửi `POST /ai-agents/behavior/track`. Tắt: không gửi sự kiện mới. |
| **Gợi ý AI trên cloud** | Bật (mặc định): mastery/ITS/DRL/Coach/hint quiz gọi API. Tắt: ẩn/tắt các luồng đó; Coach hiện banner hướng dẫn bật lại. |

- Khởi tạo: `main.dart` → `WidgetsFlutterBinding.ensureInitialized()` + `await AiUserPreferences.instance.load()`.

### UI

- **Hồ sơ:** card **AI & quyền riêng tư** (2 `SwitchListTile` + `ListenableBuilder`).
- **Dashboard:** Quick Action **Coach AI** → bottom sheet chọn môn → `/subjects/:id/ai-coach`.
- **Chi tiết node:** `ExpansionTile` **Hoạt động gần đây (AI)** → `GET /ai-agents/behavior/node/:nodeId` (đọc được cả khi đã tắt ghi mới).
- **End quiz:** nút gợi ý ITS vô hiệu khi tắt cloud; có snackbar nếu vẫn bấm.
- **Lesson types overview / Node insights:** không gọi mastery/ITS khi tắt cloud.

---

## Kiểm tra tổng hợp (5 phase) & giới hạn

### Đã đối chiếu code (mobile + backend)

| Phase | Trạng thái | Ghi chú |
|-------|------------|---------|
| 1 | OK | Mọi `track` đi qua `AiBehaviorTracker` → `fireAndForget` **phải** tôn trọng `behaviorTrackingEnabled` (đã sửa: guard trong `fireAndForget`, không chỉ `trackLessonScreenOpened`). |
| 2 | OK | Insight card ẩn khi API lỗi; tắt **cloud** thì không gọi mastery/ITS. |
| 3 | OK | DRL + ITS hint + admin `GET /analytics/user-behaviors`. |
| 4 | OK | Coach + đủ method API; `getAiShouldSkipTopic` **chưa** gắn UI (optional). |
| 5 | OK | Prefs + Dashboard Coach + lịch sử node + tách **tracking** vs **cloud AI**. |

### Xung đột / hành vi cần biết (không phải bug)

1. **Tắt cloud giữa chừng:** Một số màn (node detail, lesson overview) **không** `ListenableBuilder` theo prefs → insight có thể cũ đến khi kéo refresh / vào lại màn.
2. **Tracking tắt, cloud bật:** Mastery/ITS vẫn chạy nhưng ít dữ liệu mới → chỉ số có thể “đứng” hoặc dựa bài đã học trước khi tắt.
3. **Backend LangChain:** `days` lớn (30) = nhiều vòng DRL/ITS → timeout/risk chậm; nên test 7 trước.
4. **Module Nest:** `AnalyticsModule` import `AiAgentsModule` — không vòng phụ thuộc ngược; `nest build` cần pass sau thay đổi.

### Có thể bổ sung sau (không chặn MVP)

- Gắn `GET /ai-agents/its/should-skip/:nodeId` vào card insight hoặc lesson overview.
- `ListenableBuilder` trên node detail / lesson overview khi đổi prefs.
- Test tự động (widget/integration) cho tracker + prefs.
