import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/auth/auth_session_controller.dart';
import 'package:edtech_mobile/core/constants/api_constants.dart';

class AuthService {
  final ApiClient _apiClient;
  final AuthSessionController? _session;

  AuthService(this._apiClient, [this._session]);

  void _onAuthSuccess() {
    _session?.setLoggedIn(true);
  }

  /// Gọi khi vào màn login (mobile): giúp mở TLS + DNS trước, giảm timeout “lần đầu” khi đăng nhập Google.
  Future<void> warmUpBackendConnection() async {
    try {
      await _apiClient.get(
        ApiConstants.health,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
    } catch (_) {}
  }

  bool _googleLoginFailureRetryable(Map<String, dynamic> r) {
    if (r['retryable'] == true) return true;
    final msg = (r['message'] ?? '').toString().toLowerCase();
    return msg.contains('timeout') ||
        msg.contains('quá lâu') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup') ||
        msg.contains('socketexception');
  }

  Future<Map<String, dynamic>> _googleLoginOnce(String idToken) async {
    try {
      final response = await _apiClient.post(
        '/auth/google',
        data: {'idToken': idToken},
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 90),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        Map<String, dynamic> dataMap;
        if (responseData is Map<String, dynamic>) {
          dataMap = responseData;
        } else if (responseData is String) {
          try {
            dataMap = jsonDecode(responseData) as Map<String, dynamic>;
          } catch (_) {
            return {'success': false, 'message': 'Invalid response format'};
          }
        } else {
          return {'success': false, 'message': 'Unexpected response format'};
        }

        final token = dataMap['accessToken'] ?? dataMap['access_token'];
        if (token != null && token.toString().isNotEmpty) {
          await _apiClient.saveToken(token.toString());
          _onAuthSuccess();
          return {
            'success': true,
            'token': token.toString(),
            'user': dataMap['user'] ?? dataMap,
          };
        }
        return {'success': false, 'message': 'No token received'};
      }
      return {'success': false, 'message': 'Google login failed'};
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final data = e.response!.data;
          final msg = data is Map
              ? (data['message'] ?? 'Google login failed')
              : 'Google login failed';
          return {'success': false, 'message': msg.toString()};
        }
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError) {
          return {
            'success': false,
            'retryable': true,
            'message':
                'Mạng hoặc máy chủ phản hồi chậm. Đang thử lại tự động…',
          };
        }
      }
      return {
        'success': false,
        'message': e.toString(),
        'retryable': false,
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = response.data['accessToken'] ?? response.data['access_token'];
        if (token != null) {
          await _apiClient.saveToken(token);
          _onAuthSuccess();
        }
        return {
          'success': true,
          'token': token,
          'user': response.data['user'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      // Handle DioException
      if (e is DioException) {
        String errorMessage = 'Registration failed';
        
        // Try to extract error message from response
        if (e.response != null) {
          final data = e.response!.data;
          if (data is Map<String, dynamic>) {
            errorMessage = data['message'] ?? 
                          (data['error'] is String ? data['error'] : null) ??
                          'Registration failed';
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Server response timeout. Please try again.';
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': e.response?.statusCode,
        };
      }
      
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      // Debug: Log response
      if (kDebugMode) {
        debugPrint('[AuthService] Login response status: ${response.statusCode}');
        debugPrint('[AuthService] Login response data type: ${response.data.runtimeType}');
        debugPrint('[AuthService] Login response data: ${response.data}');
      }
      
      // Check if response is successful (200 or 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response data
        final responseData = response.data;
        
        // Handle both Map and String (JSON string) responses
        Map<String, dynamic> dataMap;
        if (responseData is Map<String, dynamic>) {
          dataMap = responseData;
        } else if (responseData is String) {
          // Try to parse JSON string
          try {
            dataMap = jsonDecode(responseData) as Map<String, dynamic>;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[AuthService] Failed to parse response as JSON: $e');
            }
            return {
              'success': false,
              'message': 'Invalid response format from server',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Unexpected response format: ${responseData.runtimeType}',
          };
        }
        
        // Extract token (try both accessToken and access_token)
        final token = dataMap['accessToken'] ?? dataMap['access_token'];
        
        if (token != null && token.toString().isNotEmpty) {
          await _apiClient.saveToken(token.toString());
          _onAuthSuccess();

          if (kDebugMode) {
            debugPrint('[AuthService] Token saved successfully');
            debugPrint('[AuthService] User data: ${dataMap['user']}');
          }

          return {
            'success': true,
            'token': token.toString(),
            'user': dataMap['user'] ?? dataMap,
          };
        } else {
          if (kDebugMode) {
            debugPrint('[AuthService] No token found in response');
            debugPrint('[AuthService] Response keys: ${dataMap.keys.toList()}');
          }
          return {
            'success': false,
            'message': 'No token received from server',
          };
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login failed',
      };
    } catch (e) {
      // Handle DioException
      if (e is DioException) {
        // If we got a response but it's an error, try to parse it
        if (e.response != null) {
          final statusCode = e.response!.statusCode;
          final data = e.response!.data;
          
          String errorMessage = 'Login failed';
          if (data is Map<String, dynamic>) {
            errorMessage = data['message'] ?? 
                          (data['error'] is String ? data['error'] : null) ??
                          'Login failed';
          }
          
          return {
            'success': false,
            'message': errorMessage,
            'statusCode': statusCode,
          };
        }
        
        // Network errors
        String errorMessage = 'Login failed';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Server response timeout. Please try again.';
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': e.response?.statusCode,
        };
      }
      
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> googleLogin({required String idToken}) async {
    const maxAttempts = 3;
    Map<String, dynamic>? last;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
      last = await _googleLoginOnce(idToken);
      if (last['success'] == true) {
        last.remove('retryable');
        return last;
      }
      if (!_googleLoginFailureRetryable(last) || attempt == maxAttempts) {
        last.remove('retryable');
        return last;
      }
    }
    last ??= {'success': false, 'message': 'Google login failed'};
    last.remove('retryable');
    return last;
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return {'success': true, 'message': response.data['message'] ?? 'Email đã được gửi'};
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? 'Có lỗi xảy ra') : 'Có lỗi xảy ra';
        return {'success': false, 'message': msg.toString()};
      }
      return {'success': false, 'message': 'Không kết nối được server'};
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    _session?.setLoggedIn(false);

    // Đăng xuất khỏi Google trên thiết bị → lần sau bấm “Đăng nhập Google” sẽ chọn tài khoản.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final gsi = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: ApiConstants.googleServerClientId,
        );
        await gsi.signOut();
        await gsi.disconnect();
      } catch (_) {}
    }
  }

  Future<bool> isAuthenticated() async {
    return _apiClient.hasValidStoredSession();
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

