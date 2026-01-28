import 'package:flutter/foundation.dart';

/// API Configuration
/// Set [kIsDebug] to true for development (ngrok), false for production (Koyeb)
class ApiConfig {
  // Toggle this flag to switch between debug and production
  static const bool kIsDebug = true;
  
  // Base URLs
  static const String _debugBaseUrl = "https://shrew-concrete-cobra.ngrok-free.app";
  static const String _productionBaseUrl = "https://frantic-mable-saluman-ef0457fa.koyeb.app";
  
  // Current base URL based on debug flag
  static String get baseUrl => kIsDebug ? _debugBaseUrl : _productionBaseUrl;
  
  // API endpoint (adds /api to base URL)
  static String get apiUrl => "$baseUrl/api";
  
  // Environment name for logging/display
  static String get environmentName => kIsDebug ? "Development (ngrok)" : "Production (Koyeb)";
}
