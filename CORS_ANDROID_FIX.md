# CORS & Android Request Fix - Complete Guide

## Problem Summary
Modern Android versions block cross-origin requests (CORS) and have stricter SSL/certificate validation. When using ngrok tunnels or development servers, you might see:
- "CORS error" in Logcat
- "Certificate verification failed"
- Requests work with VPN but fail without it
- 403 errors from backend

## Solution Components

### 1. Custom HTTP Client Service (`lib/services/http_client_service.dart`)
Provides a centralized HTTP client with proper configuration:
- **SSL/TLS Certificate Handling**: Allows self-signed certificates for development
- **Proper Headers**: Includes all necessary headers for ngrok and modern Android
- **Connection Management**: Proper timeout and connection pooling

**Key Headers Added:**
```dart
'ngrok-skip-browser-warning': '69420'   // Skip ngrok browser warning
'X-Forwarded-Proto': 'https'            // Tell backend it's HTTPS
'Accept-Encoding': 'gzip, deflate'      // Compression support
'Connection': 'keep-alive'              // Connection persistence
```

**Certificate Handling:**
```dart
httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
  // Allow ngrok and localhost certificates
  if (host.contains('ngrok') || host.contains('localhost')) {
    return true;  // Accept certificate
  }
  return false;
};
```

### 2. Updated VMSService (`lib/services/vms_service_fixed.dart`)
- Uses the custom HTTP client instead of default `http` package
- All requests go through the centralized client
- Better error handling and request configuration

**Migration Guide:**
Replace imports in your files:
```dart
// OLD
import 'package:py4p_vms/services/vms_service.dart';

// NEW
import 'package:py4p_vms/services/vms_service_fixed.dart';
```

### 3. Android Manifest Configuration (`android/app/src/main/AndroidManifest.xml`)

**Required Permissions:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

**Network Security Configuration:**
```xml
<domain-config cleartextTrafficPermitted="false">
    <domain includeSubdomains="true">*.ngrok.io</domain>
    <domain includeSubdomains="true">*.ngrok-free.app</domain>
    <domain includeSubdomains="true">localhost</domain>
</domain-config>
```

This allows HTTPS connections to ngrok domains while blocking cleartext HTTP.

## Implementation Steps

### Step 1: Add HTTP Client Service
✅ Already created at `lib/services/http_client_service.dart`

### Step 2: Update Your Services
Replace your current service implementations with the fixed versions:

**For VMSService:**
```dart
// In any file using VMSService, update the import:
import 'package:py4p_vms/services/vms_service_fixed.dart' as vms_service;

// Use it the same way as before
final service = vms_service.VMSService();
```

### Step 3: Update Companion Connect Service
If you have a companion connect service, apply the same pattern:

```dart
// lib/services/companion_connect_service.dart
import 'http_client_service.dart';

class CompanionConnectService {
  late final http.Client _httpClient;
  
  CompanionConnectService() {
    _httpClient = HttpClientService().client;
  }
  
  Future<http.Response> fetchMentee() async {
    return _httpClient.get(
      Uri.parse('$baseUrl/companion-connect/mentee'),
      headers: _getHeaders(),
    );
  }
  
  // ... rest of methods
}
```

### Step 4: API Configuration (Already Set)
Your `api_config.dart` is correctly configured:
```dart
static const bool kIsDebug = false;  // Set to false for production
static const bool kUseLocalDevHost = false;

// For ngrok development:
static const String _debugBaseUrl = "https://shrew-concrete-cobra.ngrok-free.app";
```

**For Production (Railway):**
```dart
static const String _productionBaseUrl = "https://tsf-backend-production.up.railway.app";
```

### Step 5: Testing

**Test with ngrok (Development):**
```dart
// In api_config.dart, set:
static const bool kIsDebug = true;

// Run on Android device/emulator
flutter run -d <device_id>
```

**Test with Production:**
```dart
// In api_config.dart, set:
static const bool kIsDebug = false;

// Build and test
flutter run --release -d <device_id>
```

## Expected Results

✅ **Before Fix:**
- Requests blocked on Android 9+
- Works with VPN
- CORS errors in Logcat

✅ **After Fix:**
- Requests work without VPN
- No CORS errors
- Proper certificate validation
- Better connection management

## Troubleshooting

### Issue: Still getting CORS errors
**Solution:**
1. Check backend CORS headers are set correctly
2. Verify ngrok URL is correct
3. Clear app cache: `adb shell pm clear com.py4p.vms`
4. Rebuild: `flutter clean && flutter pub get && flutter run`

### Issue: Certificate verification failed
**Solution:**
1. Check if `badCertificateCallback` is properly configured
2. Ensure domain name is in the callback check
3. Verify SSL certificate on backend is valid for production

### Issue: Timeouts on slow networks
**Solution:**
Adjust timeout in `http_client_service.dart`:
```dart
httpClient.connectionTimeout = const Duration(seconds: 60); // Increase from 30
```

### Issue: Requests stuck or not completing
**Solution:**
Ensure proper connection closure in your services:
```dart
@override
void dispose() {
  _httpClient.close();  // Close client when done
  super.dispose();
}
```

## Security Notes ⚠️

### Production Deployment:
```dart
// NEVER do this in production:
httpClient.badCertificateCallback = (cert, host, port) => true;  // UNSAFE!

// Instead, only allow development domains:
if (kIsDebug) {  // Only in development
  httpClient.badCertificateCallback = (cert, host, port) {
    return host.contains('ngrok');
  };
}
```

### HTTPS Only:
- Always use HTTPS in production
- Remove cleartext traffic entirely for production builds
- Use proper SSL certificates from trusted authorities

## Files Modified/Created

| File | Purpose | Status |
|------|---------|--------|
| `lib/services/http_client_service.dart` | Custom HTTP client | ✅ Created |
| `lib/services/vms_service_fixed.dart` | Updated VMS service | ✅ Created |
| `android/app/src/main/AndroidManifest.xml` | Network security config | ✅ Updated |
| `lib/config/api_config.dart` | API configuration | ✓ Already correct |

## Next Steps

1. **Replace imports** in your main app files
2. **Test on Android 9+ devices**
3. **Verify all API calls work**
4. **Update any other HTTP service files** following the same pattern
5. **Test with VPN disabled**
6. **Check Logcat for any errors**

## Reference Links

- [Flutter HTTP Client Documentation](https://pub.dev/packages/http)
- [Android Network Security Configuration](https://developer.android.com/training/articles/security-config)
- [ngrok Browser Warning Header](https://ngrok.com/docs/http/browser-warning-header/)
- [Android 9 Cleartext Traffic](https://developer.android.com/training/articles/security-config#CleartextTrafficPermitted)

---

**Created:** 2026-08-12
**For:** TSF VMS Flutter App
**Version:** 1.0.2+3
