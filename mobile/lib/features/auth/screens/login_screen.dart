import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:edtech_mobile/core/constants/api_constants.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/widgets/mascot_image.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/features/auth/utils/google_js_stub.dart'
    if (dart.library.html) 'package:edtech_mobile/features/auth/utils/google_js_web.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
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

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<AuthService>(context, listen: false)
            .warmUpBackendConnection();
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (kDebugMode) {
        debugPrint(
          '[LOGIN] email/password result: success=${result['success']}, message=${result['message']}',
        );
      }

      if (result['success'] == true) {
        if (kDebugMode) {
          debugPrint('[LOGIN] navigating -> /dashboard');
        }
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Đăng nhập thất bại';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildLoginCard(),
                      const SizedBox(height: 16),
                      if (_showGoogleOnThisPlatform && !_isWindowsDesktop) ...[
                        _buildGoogleSignIn(),
                        const SizedBox(height: 16),
                      ],
                      _buildForgotPasswordLink(),
                      const SizedBox(height: 16),
                      _buildRegisterLink(),
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

  Widget _buildLogo() {
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purpleNeon.withValues(alpha: 0.22),
                        blurRadius: 32,
                        spreadRadius: 0,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: -8,
                child: MascotImage(
                  MascotKind.happy,
                  width: 128,
                  height: 128,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => AppGradients.primary.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          blendMode: BlendMode.srcIn,
          child: Text(
            'GAMISTU',
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 34,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Học cá nhân hóa, tinh tế',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x332D363D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purpleNeon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Đăng nhập',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                color: AppColors.errorNeon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.errorNeon.withValues(alpha: 0.3)),
              ),
              child: Row(
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
            ),
            const SizedBox(height: 16),
          ],

          // Login Button
          GamingButton(
            text: 'Đăng nhập',
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
            icon: Icons.arrow_forward_rounded,
            glowColor: AppColors.primaryLight,
          ),
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
            fillColor: AppColors.bgOverlay,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x332D363D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.purpleNeon.withValues(alpha: 0.45),
                width: 1,
              ),
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

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool get _showGoogleOnThisPlatform =>
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) ||
      kIsWeb;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (kIsWeb) {
        startGoogleJsSignIn(
          ApiConstants.googleServerClientId,
          (idToken) async {
            final result = await authService.googleLogin(idToken: idToken);
            if (!mounted) return;
            if (result['success'] == true) {
              context.go('/dashboard');
            } else {
              setState(() {
                _errorMessage =
                    result['message'] ?? 'Đăng nhập Google thất bại (web)';
                _isGoogleLoading = false;
              });
            }
          },
          (message) {
            if (!mounted) return;
            setState(() {
              _errorMessage = message;
              _isGoogleLoading = false;
            });
          },
        );
        return;
      }

      // Mobile: không gọi signOut/disconnect ngay trước signIn — dễ khiến Play Services
      // treo vô hạn sau khi user chọn tài khoản. Đổi tài khoản: đăng xuất trong app.
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: ApiConstants.googleServerClientId,
      );

      final account = await googleSignIn.signIn().timeout(
            const Duration(minutes: 2),
            onTimeout: () => null,
          );
      if (account == null) {
        if (kDebugMode) {
          debugPrint('[LOGIN][GOOGLE] account is null (cancelled or timeout)');
        }
        return;
      }

      final auth = await account.authentication.timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException(
          'Hết thời gian lấy token từ Google. Thử lại hoặc cập nhật Google Play Services.',
        ),
      );
      final idToken = auth.idToken;
      if (idToken == null) {
        if (kDebugMode) {
          debugPrint('[LOGIN][GOOGLE] idToken is null');
        }
        if (mounted) {
          setState(() {
            _errorMessage =
                'Không lấy được token từ Google. Kiểm tra serverClientId / cấu hình OAuth.';
          });
        }
        return;
      }

      await authService.warmUpBackendConnection();

      // Không bọc .timeout ngoài: googleLogin đã có retry + receiveTimeout từng request trong AuthService.
      final result = await authService.googleLogin(idToken: idToken);
      if (kDebugMode) {
        debugPrint(
          '[LOGIN][GOOGLE] backend result: success=${result['success']}, message=${result['message']}',
        );
      }

      if (!mounted) return;
      if (result['success'] == true) {
        if (kDebugMode) {
          debugPrint('[LOGIN][GOOGLE] navigating -> /dashboard');
        }
        context.go('/dashboard');
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Đăng nhập Google thất bại';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi đăng nhập Google: ${e.toString()}';
        });
      }
    } finally {
      if (mounted && !kIsWeb) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Widget _buildGoogleSignIn() {
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33474554)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGoogleLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textPrimary),
              )
            else ...[
              const Text(
                'G',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Đăng nhập bằng Google',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        onTap: () => context.push('/forgot-password'),
        child: Text(
          'Quên mật khẩu?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.purpleNeon,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/register'),
          child: Text(
            'Đăng ký ngay',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
