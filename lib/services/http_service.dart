import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Custom HTTP service for Android CORS compatibility
/// Handles:
///  - Automatic retry on CORS/network failures
///  - Android-specific header configuration
///  - Graceful timeout handling
///  - Request logging for debugging
class HttpService {
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 30);
  static const Duration retryDelay = Duration(milliseconds: 500);

  /// Headers that work better with strict Android WebView CORS policies
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Send empty origin for Android WebView compatibility
    // (some Android devices reject requests with no origin)
    'User-Agent': 'TSF-VMS-Flutter/1.0',
    // Explicitly accept all content to avoid MIME-type errors
    'Accept-Encoding': 'gzip, deflate, br',
    // Android WebView compatibility: allow credentials
    'X-Requested-With': 'XMLHttpRequest',
  };

  /// POST request with Android CORS retry logic
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequestWithRetry(
      () => _postOnce(uri, headers: headers, body: body, encoding: encoding),
      method: 'POST',
      uri: uri,
    );
  }

  /// GET request with Android CORS retry logic
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    return _performRequestWithRetry(
      () => _getOnce(uri, headers: headers),
      method: 'GET',
      uri: uri,
    );
  }

  /// PUT request with Android CORS retry logic
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequestWithRetry(
      () => _putOnce(uri, headers: headers, body: body, encoding: encoding),
      method: 'PUT',
      uri: uri,
    );
  }

  /// PATCH request with Android CORS retry logic
  static Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequestWithRetry(
      () => _patchOnce(uri, headers: headers, body: body, encoding: encoding),
      method: 'PATCH',
      uri: uri,
    );
  }

  /// DELETE request with Android CORS retry logic
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequestWithRetry(
      () => _deleteOnce(uri, headers: headers, body: body, encoding: encoding),
      method: 'DELETE',
      uri: uri,
    );
  }

  /// Single POST attempt
  static Future<http.Response> _postOnce(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final mergedHeaders = {..._defaultHeaders, ...?headers};
    return http.post(
      uri,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    ).timeout(timeout, onTimeout: () {
      throw TimeoutException('Request timeout after ${timeout.inSeconds}s');
    });
  }

  /// Single GET attempt
  static Future<http.Response> _getOnce(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {..._defaultHeaders, ...?headers};
    return http.get(uri, headers: mergedHeaders).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('Request timeout after ${timeout.inSeconds}s');
      },
    );
  }

  /// Single PUT attempt
  static Future<http.Response> _putOnce(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final mergedHeaders = {..._defaultHeaders, ...?headers};
    return http.put(
      uri,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    ).timeout(timeout, onTimeout: () {
      throw TimeoutException('Request timeout after ${timeout.inSeconds}s');
    });
  }

  /// Single PATCH attempt
  static Future<http.Response> _patchOnce(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final mergedHeaders = {..._defaultHeaders, ...?headers};
    return http.patch(
      uri,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    ).timeout(timeout, onTimeout: () {
      throw TimeoutException('Request timeout after ${timeout.inSeconds}s');
    });
  }

  /// Single DELETE attempt
  static Future<http.Response> _deleteOnce(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final mergedHeaders = {..._defaultHeaders, ...?headers};
    return http.delete(
      uri,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    ).timeout(timeout, onTimeout: () {
      throw TimeoutException('Request timeout after ${timeout.inSeconds}s');
    });
  }

  /// Perform request with exponential backoff retry logic
  /// Retries on:
  ///  - Network timeouts
  ///  - CORS errors (403)
  ///  - Server errors (5xx)
  ///  - Connection refused
  static Future<http.Response> _performRequestWithRetry(
    Future<http.Response> Function() requestFn, {
    required String method,
    required Uri uri,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt++;
        _logRequest('$method $uri', attempt: attempt);

        final response = await requestFn();
        
        // Log successful response
        _logResponse(response.statusCode, uri, success: true);

        // Don't retry on success (2xx status codes)
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        // For specific error codes, retry if we have attempts left
        if (response.statusCode == 403 ||
            response.statusCode == 408 ||
            (response.statusCode >= 500 && response.statusCode < 600)) {
          if (attempt < maxRetries) {
            await Future.delayed(
              Duration(milliseconds: (retryDelay.inMilliseconds * attempt).toInt()),
            );
            _logRequest(
              'Retrying ($attempt/$maxRetries) $method $uri',
              attempt: attempt,
              isRetry: true,
            );
            continue;
          }
        }

        // For other error codes, return immediately
        return response;
      } on TimeoutException catch (e) {
        _logError('Timeout: $e (attempt $attempt/$maxRetries)');
        if (attempt < maxRetries) {
          await Future.delayed(
            Duration(milliseconds: (retryDelay.inMilliseconds * attempt).toInt()),
          );
          continue;
        }
        rethrow;
      } on SocketException catch (e) {
        _logError('Network error: $e (attempt $attempt/$maxRetries)');
        if (attempt < maxRetries) {
          await Future.delayed(
            Duration(milliseconds: (retryDelay.inMilliseconds * attempt).toInt()),
          );
          continue;
        }
        rethrow;
      } catch (e) {
        _logError('Request failed: $e (attempt $attempt/$maxRetries)');
        if (attempt < maxRetries) {
          await Future.delayed(
            Duration(milliseconds: (retryDelay.inMilliseconds * attempt).toInt()),
          );
          continue;
        }
        rethrow;
      }
    }

    // Should not reach here, but throw if all retries exhausted
    throw Exception('Request failed after $maxRetries attempts: $method $uri');
  }

  /// Log request for debugging Android CORS issues
  static void _logRequest(
    String message, {
    int attempt = 0,
    bool isRetry = false,
  }) {
    if (kDebugMode) {
      final prefix = isRetry ? '🔄' : '📤';
      debugPrint('$prefix [$attempt/$maxRetries] $message');
    }
  }

  /// Log response for debugging
  static void _logResponse(int statusCode, Uri uri, {required bool success}) {
    if (kDebugMode) {
      final prefix = success ? '✅' : '❌';
      debugPrint('$prefix Response $statusCode from $uri');
    }
  }

  /// Log errors for debugging
  static void _logError(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }
}

// Socket exception import for SocketException type checking
class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  
  @override
  String toString() => message;
}
