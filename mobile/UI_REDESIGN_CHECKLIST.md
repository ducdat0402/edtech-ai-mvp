# Gamistu UI redesign — tiến độ màn hình

Khi **tất cả** mục dưới đây ở trạng thái ✅, coi như vòng redesign UI (theo `DESIGN.md`) **hoàn tất**.

## Đã làm ✅
- [x] Theme global + assets mascot + brand (`Vòng 0`)
- [x] `login_screen`, `register_screen`
- [x] `forgot_password_screen`
- [x] `onboarding_chat_screen`
- [x] `bottom_nav_bar`, `dashboard_screen`
- [x] `subjects_hub_screen`
- [x] `subject_intro_screen`, `unlock_subject_screen`
- [x] `learning_path_choice_screen`, `subject_learning_goals_screen`, `personal_mind_map_screen` (welcome, chat, header, danh sách topic/tile/bottom sheet)
- [x] `adaptive_placement_test_screen`
- [x] `domains_list_screen`, `domain_detail_screen`, `all_lessons_screen`
- [x] `node_detail_screen` — `AppColors` toàn màn + dọn dead code (dialog tạo content độ khó, format selector/chip, `_countContentByFormat`, HUD difficulty từng mức, `_getItemTypeLabel`, `apiService` thừa, unreachable revert); `Colors.white`/`transparent` chỗ contrast
- [x] Lesson types (`lib/features/lessons/`): ghost + `primaryLight` thay `cyanNeon`/`borderPrimary` toàn thư mục; `text_editor` SnackBar + ví dụ minh họa `xpGold`; spinner `lesson_types_overview`

- [x] Cộng đồng & chat: `community_hub_screen`, `community_feed_tab`, `friends_screen` (wrapper), `friends_connections_panel`, `blocked_users_screen`, `world_chat_screen`, `chat_bubble`, `conversations_screen`, `chat_room_screen` — ghost + `primaryLight`, hub TabBar + AppBar đồng bộ Gamistu

- [x] `shop_screen`, `payment_screen`, `currency_screen`, `rewards_history_screen` + `streak_week_card` (viền ghost)

- [x] `daily_quests_screen`, `leaderboard_screen`, `weekly_rewards_history_screen`, `leaderboard_user_profile_sheet` (ghost + `primaryLight`, gradient tuần đồng bộ)

- [x] `profile_screen`, `journey_log_screen`, `competencies_screen`, `profile_competency_preview_row`, `my_contributions_screen`, `contribution_upload_screen` (ghost + `primaryLight`, journey bỏ debug print)

- [x] `admin_panel_screen` + `comparison_dialog` (ghost, `primaryLight`, TabBar/AppBar đồng bộ, snackbar token)
- [x] `my_pending_contributions_screen`, `create_subject_screen`, `create_domain_screen`, `create_topic_screen`, `create_lesson_screen` (`h4`, domain accent `primaryLight`, độ khó → token)
- [x] `contributor_mind_map_screen` (dark contributor, ghost border, bottom sheet/dialog/snackbar tokens)
- [x] `placement_test_screen`, `analysis_complete_screen` (ghost `0x332D363D`, leading `textSecondary`, spinner `primaryLight`); `AppErrorWidget` / `SkeletonLoader` (token dark + `GamingButton` retry)

**Trạng thái:** các mục checklist UI redesign đã đủ; còn `info` analyzer (print debug, `withOpacity` deprecated) có thể xử lý dần toàn app.

Cập nhật file này sau mỗi lượt (đánh dấu ✅ và ghi ngắn ngày/commit nếu cần).
