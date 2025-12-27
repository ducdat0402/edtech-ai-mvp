import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60), // Increased timeout
        receiveTimeout: const Duration(seconds: 60), // Increased timeout
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
            // Token expired, clear and redirect to login
            _storage.delete(key: _tokenKey);
          }
          // For 200 with null/empty response, don't treat as error
          if (error.response?.statusCode == 200 && 
              (error.response?.data == null || 
               (error.response?.data is String && (error.response?.data as String).isEmpty))) {
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

  // Save token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Clear token
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
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

  // DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }
}

