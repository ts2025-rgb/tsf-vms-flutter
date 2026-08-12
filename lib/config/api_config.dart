
/// API Configuration
/// Set [kIsDebug] to true for development (ngrok), false for production (Koyeb)
class ApiConfig {
  // Toggle this flag to switch between development and production.
  // Production must use HTTPS only.
  static const bool kIsDebug = false; // Set to false for production

  // Toggle this to use a direct local development host on Android.
  // Enable this only when you need plain HTTP to a known local IP from the emulator/device.
  static const bool kUseLocalDevHost = false;

  // Base URLs
  static const String _debugBaseUrl =
      "https://shrew-concrete-cobra.ngrok-free.app";
  static const String _productionBaseUrl =
      "https://tsf-backend-production.up.railway.app";
  

  // Use an explicit emulator/device local host IP when developing against a direct backend.
  // Examples:
  //   Android emulator: http://10.0.2.2:8080
  //   Genymotion emulator: http://10.0.3.2:8080
  //   Physical device: http://192.168.1.100:8080
  static const String _localBaseUrl = "http://10.0.2.2:8080";

  // Current base URL based on debug/local selection.
  static String get baseUrl {
    if (kUseLocalDevHost) return _localBaseUrl;
    return kIsDebug ? _debugBaseUrl : _productionBaseUrl;
  }

  // API endpoint (adds /api to base URL)
  static String get apiUrl => "$baseUrl/api";

  // Environment name for logging/display
  static String get environmentName =>
      kIsDebug ? "Development (ngrok)" : "Production (Railway)";
}
