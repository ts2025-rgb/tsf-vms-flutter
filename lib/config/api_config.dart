import 'package:flutter/foundation.dart';

class ApiConfig {
  // 1. Declare missing flags here:
  static const bool kIsDebug = false;
  static const bool kUseNgrok = true;
  static const bool kUseLocalDevHost = false;

  // Raw Backend URLs
  static const String _rawProductionUrl = "https://tsf-backend-production.up.railway.app";
  static const String _corsProxyPrefix = "https://corsproxy.io/?";
  static const String _ngrokBaseUrl = "https://bobbing-sterility-subheader.ngrok-free.dev";
  static const String _cloudflareBaseUrl = "https://essentially-contacting-cfr-promotions.trycloudflare.com";

  static String get baseUrl {
    if (kIsDebug) {
      return kUseNgrok ? _ngrokBaseUrl : _cloudflareBaseUrl;
    }

    // Production environment logic
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _rawProductionUrl; // Direct connection for Android native APK
    } else if (kIsWeb) {
      return "$_corsProxyPrefix$_rawProductionUrl"; // CORS proxy for web builds
    }

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
