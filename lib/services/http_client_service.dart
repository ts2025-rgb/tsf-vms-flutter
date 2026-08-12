import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Custom HTTP Client Service for handling modern Android CORS issues
/// Provides proper certificate handling and request configuration
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();

  late http.Client _client;

  factory HttpClientService() {
    return _instance;
  }

  HttpClientService._internal() {
    _client = _createHttpClient();
  }

  /// Create a custom HTTP client with proper SSL/TLS configuration
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();

    // Configure certificate validation based on build mode
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      // Allow self-signed certificates only in debug/development
      if (kDebugMode) {
        // Allow ngrok and development URLs
        if (host.contains('ngrok') || 
            host.contains('localhost') || 
            host.contains('127.0.0.1')) {
          return true;  // Accept self-signed certificate
        }
      }
      // In release/production, only accept properly signed certificates
      return false;
    };

    // Set timeout for better network handling on slow connections
    httpClient.connectionTimeout = const Duration(seconds: 30);
    
    // Enable connection pooling for better performance
    httpClient.maxConnectionsPerHost = 10;

    return http.IOClient(httpClient);
  }

  /// Get the HTTP client instance
  http.Client get client => _client;

  /// Make a GET request with proper headers for Android
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = _getDefaultHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return _client.get(url, headers: mergedHeaders);
  }

  /// Make a POST request with proper headers for Android
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final defaultHeaders = _getDefaultHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return _client.post(
      url,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    );
  }

  /// Make a PATCH request with proper headers for Android
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final defaultHeaders = _getDefaultHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return _client.patch(
      url,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    );
  }

  /// Make a PUT request with proper headers for Android
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final defaultHeaders = _getDefaultHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return _client.put(
      url,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    );
  }

  /// Make a DELETE request with proper headers for Android
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final defaultHeaders = _getDefaultHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return _client.delete(
      url,
      headers: mergedHeaders,
      body: body,
      encoding: encoding,
    );
  }

  /// Get default headers needed for modern Android and ngrok
  static Map<String, String> _getDefaultHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate, br',
      'User-Agent': 'TSF-VMS-Flutter/1.0',
      'ngrok-skip-browser-warning': '69420',
      'X-Forwarded-Proto': 'https',
      'Connection': 'keep-alive',
    };
  }

  /// Close the client
  void close() {
    _client.close();
  }
}
