import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  /// Thời điểm lưu token (ms epoch) — cửa sổ “ghi nhớ đăng nhập” 30 ngày.
  static const String _loginAtKey = 'auth_login_at_ms';

  /// Gọi khi 401 để cập nhật UI (GoRouter) mà không cần import session vào đây.
  void Function()? onSessionInvalidated;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        // Render / mạng yếu: cold start + TLS có thể > 60s.
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor for debugging (only in debug mode)
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => print('[API] $obj'),
      ));
    }

    // Add logging interceptor for debugging (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ));
    }

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to requests
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors
          if (error.response?.statusCode == 401) {
            clearToken().then((_) {
              onSessionInvalidated?.call();
            });
          }
          // For 200 with null/empty response, don't treat as error
          if (error.response?.statusCode == 200 &&
              (error.response?.data == null ||
                  (error.response?.data is String &&
                      (error.response?.data as String).isEmpty))) {
            // Return success response with null data
            return handler.resolve(
              Response(
                requestOptions: error.requestOptions,
                data: null,
                statusCode: 200,
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final jsonStr = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Token còn hiệu lực: có token, trong 30 ngày kể từ lần đăng nhập, và chưa hết JWT `exp`.
  Future<bool> hasValidStoredSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return false;

    final now = DateTime.now();
    final atStr = await _storage.read(key: _loginAtKey);

    if (atStr != null && atStr.isNotEmpty) {
      final atMs = int.tryParse(atStr);
      if (atMs != null) {
        final loginAt = DateTime.fromMillisecondsSinceEpoch(atMs);
        if (now.difference(loginAt) > const Duration(days: 30)) {
          await clearToken();
          onSessionInvalidated?.call();
          return false;
        }
      }
    }

    final payload = _decodeJwtPayload(token);
    if (payload != null && payload['exp'] != null) {
      final expSec = payload['exp'];
      final expMs = expSec is int
          ? expSec * 1000
          : (expSec is num ? (expSec * 1000).round() : null);
      if (expMs != null) {
        final expAt = DateTime.fromMillisecondsSinceEpoch(expMs);
        if (now.isAfter(expAt)) {
          await clearToken();
          onSessionInvalidated?.call();
          return false;
        }
      }
    }

    // Cài cũ chưa có auth_login_at_ms: gắn mốc hiện tại để bắt đầu cửa sổ 30 ngày.
    if (atStr == null || atStr.isEmpty) {
      await _storage.write(
        key: _loginAtKey,
        value: now.millisecondsSinceEpoch.toString(),
      );
    }

    return true;
  }

  // Save token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(
      key: _loginAtKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  // Clear token
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _loginAtKey);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      // Log response for debugging
      if (kDebugMode) {
        debugPrint('[API] Response status: ${response.statusCode}');
        debugPrint('[API] Response data: ${response.data}');
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API] Post error: $e');
      }
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }

  // POST request with file upload (multipart/form-data)
  Future<Response> postFile(
    String path, {
    required String fileKey,
    required String filePath,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });
      return await _dio.post(path, data: formData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API] Post file error: $e');
      }
      rethrow;
    }
  }

  /// Upload multipart (web/mobile) từ bytes — field `image` giống [postFile].
  Future<Response> postMultipartBytes(
    String path, {
    required String fileKey,
    required List<int> bytes,
    String filename = 'upload.jpg',
  }) async {
    try {
      final formData = FormData.fromMap({
        fileKey: MultipartFile.fromBytes(bytes, filename: filename),
      });
      return await _dio.post(path, data: formData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API] Post multipart bytes error: $e');
      }
      rethrow;
    }
  }
}
