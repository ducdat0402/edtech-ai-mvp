import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/theme/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      );

      if (result['success'] == true) {
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        String errorMessage = result['message'] ?? 'Registration failed';

        if (result['statusCode'] == 409) {
          errorMessage = 'Email đã tồn tại. Bạn có muốn đăng nhập không?';
        }

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _animationController.dispose();
    super.dispose();
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
            child: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Register Card
                      _buildRegisterCard(),
                      const SizedBox(height: 24),

                      // Login Link
                      _buildLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon with glow
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
          child: const Icon(
            Icons.person_add_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'TẠO TÀI KHOẢN',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bắt đầu hành trình học tập của bạn',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name Field
          _buildTextField(
            controller: _fullNameController,
            label: 'Họ và tên',
            hint: 'Nguyễn Văn A',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập họ tên';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'your@email.com',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!value.contains('@')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            hint: '••••••••',
            icon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textTertiary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorNeon.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.errorNeon, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.errorNeon,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage!.contains('đăng nhập'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Đăng nhập ngay →',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.cyanNeon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Register Button
          GamingButton(
            text: 'Đăng ký',
            onPressed: _isLoading ? null : _handleRegister,
            isLoading: _isLoading,
            gradient: AppGradients.success,
            glowColor: AppColors.successNeon,
            icon: Icons.check_rounded,
          ),

          const SizedBox(height: 16),

          // Benefits
          _buildBenefits(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
            suffixIcon: suffixIcon,
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
              borderSide:
                  const BorderSide(color: AppColors.successNeon, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.errorNeon),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.errorNeon, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      {'icon': Icons.school_rounded, 'text': 'Học tập cá nhân hóa'},
      {'icon': Icons.emoji_events_rounded, 'text': 'Nhận phần thưởng'},
      {'icon': Icons.trending_up_rounded, 'text': 'Theo dõi tiến độ'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: benefits.map((benefit) {
          return Column(
            children: [
              Icon(
                benefit['icon'] as IconData,
                color: AppColors.purpleNeon,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                benefit['text'] as String,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            'Đăng nhập',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.cyanNeon,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
