/// API Configuration
/// Supports three dev modes:
///  - ngrok (kUseNgrok = true)
///  - Cloudflare Tunnel (kUseNgrok = false)
///  - Local IP (kUseLocalDevHost = true)
///
/// Toggle kIsDebug to switch between production and development base URL.

class ApiConfig {
  // ============ CONFIGURATION FLAGS ============
  /// Set to true to use a development tunnel (ngrok or Cloudflare).
  /// Set to false to use production Railway/Koyeb URL.
  static const bool kIsDebug = false;

  /// When kIsDebug == true, set this to true to pick the ngrok tunnel.
  /// If false, Cloudflare tunnel will be used.
  static const bool kUseNgrok = true;

  /// Set to true ONLY for local development on same WiFi (HTTP only)
  /// DO NOT use this in production
  static const bool kUseLocalDevHost = false;

  // ============ BASE URLS ============
  /// Local development via direct IP (HTTP only, same WiFi required)
  /// Android Emulator: http://10.0.2.2:8080
  /// Physical Device: http://192.168.x.x:8080 (replace with your laptop's IP)
  static const String _localBaseUrl = "http://10.0.2.2:8080";

  static const String _rawProductionUrl = "https://tsf-backend-production.up.railway.app";
  static const String _corsProxyPrefix = "https://corsproxy.io/?";

  static const String _ngrokBaseUrl = "https://bobbing-sterility-subheader.ngrok-free.dev";
  static const String _cloudflareBaseUrl = "https://essentially-contacting-cfr-promotions.trycloudflare.com";

  /// Returns the current API base URL dynamically based on environment and platform
  static String get baseUrl {
    if (kUseLocalDevHost) return _localBaseUrl;
    
    if (kIsDebug) {
      return kUseNgrok ? _ngrokBaseUrl : _cloudflareBaseUrl;
    }

    // PRODUCTION LOGIC:
    // Native Android / iOS / Desktop DO NOT suffer from browser CORS.
    // Only Flutter Web requires the CORS proxy.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Direct connection for Android APK/App
      return _rawProductionUrl;
    } else if (kIsWeb) {
      // Browsers enforce CORS, route via proxy
      return "$_corsProxyPrefix$_rawProductionUrl";
    }

    // Default fallback (e.g. iOS or Desktop native builds)
    return _rawProductionUrl;
  }

  static String get apiUrl => "$baseUrl/api";
  }
  /// Returns human-readable environment name for debugging
  static String get environmentName {
    if (kUseLocalDevHost) return "Development (Local IP - Same WiFi)";
    if (kIsDebug) return kUseNgrok ? "Development (ngrok)" : "Development (Cloudflare Tunnel)";
    return "Production (Railway)";
  }

  // ============ QUICK START GUIDE ============
  /// If using ngrok:
  /// 1. Start backend locally (e.g. listening on port 80 or 8080)
  /// 2. Run: `ngrok http 80` (or `ngrok http 8080`)
  /// 3. Copy the forwarding URL (https://<your-subdomain>.ngrok-free.dev)
  /// 4. Replace `_ngrokBaseUrl` above with the new URL OR use environment / build-time replacement.
  ///
  /// If using cloudflared:
  /// 1. Start backend locally
  /// 2. Run: `cloudflared tunnel --url http://localhost:8080`
  /// 3. Use the returned Cloudflare forwarding URL.
}
