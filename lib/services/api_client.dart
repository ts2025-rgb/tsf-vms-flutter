import 'dart:convert';
import 'http_service.dart';
import '../config/api_config.dart';

/// Simple API client that handles all common requests
/// Usage: Instead of:
///   http.post(Uri.parse('$baseUrl/admin/login'), ...)
/// Use:
///   ApiClient.post('/admin/login', body: {...})
class ApiClient {
  static String get baseUrl => ApiConfig.apiUrl;

  /// POST request with automatic retry and Android CORS handling
  static Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await HttpService.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return ApiResponse.fromHttp(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// GET request with automatic retry and Android CORS handling
  static Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await HttpService.get(url, headers: headers);
      return ApiResponse.fromHttp(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// PUT request with automatic retry and Android CORS handling
  static Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await HttpService.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return ApiResponse.fromHttp(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// PATCH request with automatic retry and Android CORS handling
  static Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await HttpService.patch(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return ApiResponse.fromHttp(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// DELETE request with automatic retry and Android CORS handling
  static Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await HttpService.delete(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return ApiResponse.fromHttp(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

/// Unified API response wrapper
class ApiResponse {
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? error;
  final bool success;

  ApiResponse({
    required this.statusCode,
    this.data,
    this.error,
    required this.success,
  });

  /// Create from HTTP response
  factory ApiResponse.fromHttp(dynamic response) {
    try {
      final statusCode = response.statusCode ?? 0;
      final body = response.body ?? '';
      
      final data = body.isNotEmpty ? json.decode(body) : null;
      final success = statusCode >= 200 && statusCode < 300;

      return ApiResponse(
        statusCode: statusCode,
        data: data is Map ? data.cast<String, dynamic>() : null,
        success: success,
        error: success ? null : 'HTTP $statusCode',
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        success: false,
        error: 'Failed to parse response: $e',
      );
    }
  }

  /// Create error response
  factory ApiResponse.error(String errorMessage) {
    return ApiResponse(
      statusCode: 0,
      success: false,
      error: errorMessage,
    );
  }

  /// Get data as Map or empty map if null
  Map<String, dynamic> get dataOrEmpty => data ?? {};

  /// Get single value from data
  dynamic operator [](String key) => data?[key];

  @override
  String toString() => 'ApiResponse(status: $statusCode, success: $success, error: $error)';
}
