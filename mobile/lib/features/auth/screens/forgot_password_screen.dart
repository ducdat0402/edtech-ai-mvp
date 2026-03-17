import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _emailSent = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Có lỗi xảy ra';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _emailSent ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.successNeon.withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.mark_email_read_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          'Email đã được gửi!',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'Kiểm tra hộp thư của bạn (bao gồm cả mục Spam).\nNhấn vào link trong email để đặt lại mật khẩu.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GamingButton(
          text: 'Quay lại đăng nhập',
          onPressed: () => context.go('/login'),
          icon: Icons.login_rounded,
        ),
      ],
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Quên mật khẩu?',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập email đã đăng ký, chúng tôi sẽ gửi link đặt lại mật khẩu cho bạn.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Email',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.email_rounded, color: AppColors.textTertiary, size: 20),
                    filled: true,
                    fillColor: AppColors.bgTertiary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.purpleNeon, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.errorNeon),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                    if (!value.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorNeon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorNeon.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.errorNeon, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorNeon),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GamingButton(
                  text: 'Gửi link đặt lại',
                  onPressed: _isLoading ? null : _handleSubmit,
                  isLoading: _isLoading,
                  gradient: AppGradients.primary,
                  glowColor: AppColors.purpleNeon,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
