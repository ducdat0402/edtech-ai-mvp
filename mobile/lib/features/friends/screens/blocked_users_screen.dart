import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Danh sách người dùng bạn đã chặn — có thể gỡ chặn.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  final Set<String> _unblocking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getBlockedUsers();
      final raw = data['users'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _users = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmUnblock(Map<String, dynamic> user) async {
    final name = user['fullName'] as String? ?? 'Người này';
    final id = user['id'] as String?;
    if (id == null || id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Gỡ chặn?',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Bạn sẽ có thể gửi lời mời kết bạn và nhắn tin với $name.',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gỡ chặn',
                style: TextStyle(
                    color: AppColors.successNeon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _unblocking.add(id));
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.unblockUser(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gỡ chặn $name'),
          backgroundColor: AppColors.successNeon.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _users.removeWhere((u) => u['id'] == id);
        _unblocking.remove(id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _unblocking.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
    }
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String? _formatBlockedAt(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    return DateFormat.yMMMd().add_Hm().format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text('Đã chặn',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.errorNeon, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.block_rounded,
                      title: 'Chưa chặn ai',
                      message:
                          'Những tài khoản bạn chặn từ danh sách bạn bè sẽ hiển thị ở đây.',
                    )
                  : RefreshIndicator(
                      color: AppColors.purpleNeon,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final id = user['id'] as String? ?? '';
                          final name =
                              user['fullName'] as String? ?? 'Người dùng';
                          final blockedLabel =
                              _formatBlockedAt(user['blockedAt']);
                          final busy = _unblocking.contains(id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0x332D363D)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.errorNeon.withValues(alpha: 0.2),
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(
                                    color: AppColors.errorNeon,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.textPrimary),
                              ),
                              subtitle: blockedLabel != null
                                  ? Text(
                                      'Chặn lúc $blockedLabel',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textTertiary),
                                    )
                                  : null,
                              trailing: busy
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.purpleNeon,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () => _confirmUnblock(user),
                                      child: const Text(
                                        'Gỡ chặn',
                                        style: TextStyle(
                                          color: AppColors.successNeon,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
