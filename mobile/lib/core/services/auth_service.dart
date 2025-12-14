import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/constants/api_constants.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

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

  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await _apiClient.getToken();
    return token != null && token.isNotEmpty;
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

