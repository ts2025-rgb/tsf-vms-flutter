/// API Configuration
/// Supports three dev modes:
///  - ngrok (kUseNgrok = true)
///  - Cloudflare Tunnel (kUseNgrok = false)
///  - Local IP (kUseLocalDevHost = true)
///
/// Toggle kIsDebug to switch between production and development base URL.
library;

class ApiConfig {
  // ============ CONFIGURATION FLAGS ============
  /// Set to true to use a development tunnel (ngrok or Cloudflare).
  /// Set to false to use production Railway/Koyeb URL.
  static const bool kIsDebug = true;

  /// When kIsDebug == true, set this to true to pick the ngrok tunnel.
  /// If false, Cloudflare tunnel will be used.
  static const bool kUseNgrok = true;

  /// Set to true ONLY for local development on same WiFi (HTTP only)
  /// DO NOT use this in production
  static const bool kUseLocalDevHost = false;

  // ============ BASE URLS ============
  /// Local development via direct IP (HTTP only, same WiFi required)
  /// Android Emulator: http://10.0.2.2:8081
  /// Physical Device: http://localhost:8081
  static const String _localBaseUrl = "http://localhost:8081";

    /// Production backend (Railway / Koyeb)
    /// Use the real backend host directly so the server's CORS policy can allow the Pages origin.
    static const String _productionBaseUrl =
      "https://tsf-backend-production.up.railway.app";

  /// ngrok Tunnel URL (dev only)
  /// Example (your current active tunnel):
  static const String _ngrokBaseUrl =
      "https://bobbing-sterility-subheader.ngrok-free.dev";

  /// Cloudflare Tunnel URL (alternate dev option)
  static const String _cloudflareBaseUrl =
      "https://essentially-contacting-cfr-promotions.trycloudflare.com";

  // ============ SELECTED URL ============
  /// Returns the current API base URL based on configuration
  static String get baseUrl {
    if (kUseLocalDevHost) return _localBaseUrl;
    if (!kIsDebug) return _productionBaseUrl;
    // kIsDebug == true -> choose tunnel provider
    return kUseNgrok ? _ngrokBaseUrl : _cloudflareBaseUrl;
  }

  /// Returns the full API endpoint URL (adds /api)
  static String get apiUrl => "$baseUrl/api";

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
