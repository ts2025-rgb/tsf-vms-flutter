
/// API Configuration
/// Updated to work without ngrok dependency
/// 
/// THREE WAYS TO USE:
/// 1. PRODUCTION (Recommended for testing): Set kIsDebug = false (uses Railway)
/// 2. CLOUDFLARE TUNNEL (Dev with local backend): Set kIsDebug = true (use Cloudflare URL)
/// 3. LOCAL IP (Same WiFi only): Set kUseLocalDevHost = true (no setup needed)

class ApiConfig {
  // ============ CONFIGURATION FLAGS ============
  
  /// Set to true to use Cloudflare Tunnel (development)
  /// Set to false to use production Railway URL
  static const bool kIsDebug = true;  // ✅ Set to true for Cloudflare Tunnel development

  /// Set to true ONLY for local development on same WiFi (HTTP only)
  /// DO NOT use this in production
  static const bool kUseLocalDevHost = false;

  // ============ BASE URLS ============
  
  /// Local development via direct IP (HTTP only, same WiFi required)
  /// Android Emulator: http://10.0.2.2:8080
  /// Physical Device: http://192.168.x.x:8080 (replace with your laptop's IP)
  static const String _localBaseUrl = "http://10.0.2.2:8080";

  /// Production backend (Railway - works everywhere)
  static const String _productionBaseUrl =
      "https://tsf-backend-production.up.railway.app";

  /// Cloudflare Tunnel URL (free ngrok replacement - dev only)
  /// ✅ Active Tunnel URL - Your current development tunnel
  static const String _cloudflareBaseUrl =
      "https://essentially-contacting-cfr-promotions.trycloudflare.com";

  // ============ SELECTED URL ============
  
  /// Returns the current API base URL based on configuration
  static String get baseUrl {
    if (kUseLocalDevHost) {
      return _localBaseUrl;  // Local IP mode
    }
    return kIsDebug ? _cloudflareBaseUrl : _productionBaseUrl;
  }

  /// Returns the full API endpoint URL (adds /api)
  static String get apiUrl => "$baseUrl/api";

  /// Returns human-readable environment name for debugging
  static String get environmentName {
    if (kUseLocalDevHost) {
      return "Development (Local IP - Same WiFi)";
    }
    if (kIsDebug) {
      return "Development (Cloudflare Tunnel)";
    }
    return "Production (Railway)";
  }

  // ============ QUICK START GUIDE ============
  
  /// YOUR SETUP IS READY! Here's what to do next:
  /// 
  /// 1. ✅ Backend tunnel is running
  ///    URL: https://essentially-contacting-cfr-promotions.trycloudflare.com
  /// 
  /// 2. ✅ Flutter config updated (kIsDebug = true)
  /// 
  /// 3. NEXT: Rebuild and run the app
  ///    flutter clean
  ///    flutter pub get
  ///    flutter run
  /// 
  /// 4. Test the connection
  ///    - Open Login screen
  ///    - Try sending OTP
  ///    - Check if it works!
  /// 
  /// ⚠️ IMPORTANT: Keep the cloudflared tunnel running in background
  /// If tunnel stops, the URL won't work. Restart with:
  ///    cloudflared tunnel --url http://localhost:8080
  
  // ============ ENVIRONMENT VERIFICATION ============
  
  /// Debug info: logs current configuration
  static String getConfigInfo() {
    return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 API Configuration Info
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Environment:  $environmentName
API URL:      $apiUrl
Base URL:     $baseUrl
Debug Mode:   $kIsDebug
Local Mode:   $kUseLocalDevHost
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Cloudflare Tunnel URL: 
   https://essentially-contacting-cfr-promotions.trycloudflare.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ''';
  }
}
