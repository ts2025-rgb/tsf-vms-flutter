
/// API Configuration
/// Set [kIsDebug] to true for development (ngrok), false for production (Koyeb)
class ApiConfig {
  // Toggle this flag to switch between debug and production
  static const bool kIsDebug = false; // Set to false for production

  // Base URLs
  static const String _debugBaseUrl =
      "https://shrew-concrete-cobra.ngrok-free.app";
  static const String _productionBaseUrl =
      "https://tsf-backend-production.up.railway.app";

  // Current base URL based on debug flag
  static String get baseUrl => kIsDebug ? _debugBaseUrl : _productionBaseUrl;

  // API endpoint (adds /api to base URL for debug; uses same-origin proxy in production)
  static String get apiUrl => kIsDebug ? "$baseUrl/api" : "/api";

  // Environment name for logging/display
  static String get environmentName =>
      kIsDebug ? "Development (ngrok)" : "Production (Railway)";
}
