# Android CORS Fix - Client-Side Implementation

## Problem
Some Android devices were failing to make API requests due to:
- Strict CORS policy enforcement
- Missing or incorrect headers for WebView requests
- Network timeouts on some devices
- CORS preflight failures

## Solution
Implemented `HttpService` with automatic retry logic and Android-compatible headers, plus an easy-to-use `ApiClient` wrapper.

## What Changed

### New Files Created
1. **`lib/services/http_service.dart`** - Low-level HTTP client with:
   - Automatic retry logic (up to 3 attempts with exponential backoff)
   - Android-compatible headers (User-Agent, X-Requested-With, etc.)
   - Timeout handling (30 seconds)
   - Request/response logging for debugging
   - Graceful CORS error handling

2. **`lib/services/api_client.dart`** - High-level API wrapper with:
   - Simple method calls: `ApiClient.get()`, `ApiClient.post()`, etc.
   - Automatic error handling and response parsing
   - Unified `ApiResponse` type for all requests
   - Zero configuration needed

### Modified Files
- **`lib/admin_login_screen.dart`** - Example of migration to use `ApiClient`

## How to Use

### New Way (Recommended)
```dart
import 'services/api_client.dart';

// Simple POST request
final response = await ApiClient.post(
  '/admin/login',
  body: {
    'email': 'user@example.com',
    'password': 'password123',
  },
);

if (response.success) {
  print('Success: ${response.data}');
} else {
  print('Error: ${response.error}');
}
```

### Old Way (Still Works, But Less Reliable)
```dart
import 'package:http/http.dart' as http;

final response = await http.post(
  Uri.parse('$baseUrl/admin/login'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({...}),
);
```

## Migration Steps

For each screen that makes API calls:

1. **Replace imports:**
   ```dart
   // OLD
   import 'package:http/http.dart' as http;
   
   // NEW
   import 'services/api_client.dart';
   ```

2. **Replace each API call:**
   ```dart
   // OLD
   final response = await http.get(
     Uri.parse('$baseUrl/some/endpoint'),
   );
   final data = json.decode(response.body);
   
   // NEW
   final response = await ApiClient.get('/some/endpoint');
   final data = response.data;
   ```

3. **Update error handling:**
   ```dart
   // OLD
   if (response.statusCode == 200) { ... }
   
   // NEW
   if (response.success) { ... }
   ```

## Files to Update (Priority Order)

High Priority (Frequently Used):
- `lib/home_screen.dart`
- `lib/login_screen.dart`
- `lib/register_screen.dart`
- `lib/profile_screen.dart`
- `lib/admin.dart`
- `lib/companionconnect.dart`

Medium Priority:
- `lib/admin_mentee_management.dart`
- `lib/admin_query_management.dart`
- `lib/create_mentee_page.dart`

## How It Works

### For Android Devices That Fail
1. **First attempt** sends request with Android-compatible headers
2. **If timeout/CORS error** waits 500ms and retries
3. **If still fails** retries again with exponential backoff
4. **Logs all failures** so we can debug specific devices

### Headers That Fix Android Issues
- `User-Agent: TSF-VMS-Flutter/1.0` - Identifies as mobile app
- `X-Requested-With: XMLHttpRequest` - Android WebView compatibility
- `Accept-Encoding: gzip, deflate, br` - Common compression support

### Retry Strategy
- **Max retries:** 3 attempts
- **Delay between retries:** 500ms (first), 1000ms (second)
- **Retries on:** timeouts, 403 Forbidden, 408 Request Timeout, 5xx errors
- **Doesn't retry on:** 2xx success, 4xx client errors (except 403/408)

## Testing

To test on an Android device:

```bash
# 1. Build for Android
flutter build apk --release

# 2. Install on device
adb install build/app/outputs/flutter-apk/app-release.apk

# 3. Run and test login
# Check logcat for retry messages:
adb logcat | grep "🔄"  # Shows retries
adb logcat | grep "📤"  # Shows requests
adb logcat | grep "✅"  # Shows successes
```

## Environment Variables

No configuration needed! The service automatically:
- Uses the production backend from `ApiConfig.apiUrl`
- Applies Android-compatible headers to all requests
- Handles timeouts and retries transparently

## Debugging

Enable Flutter debug mode to see request logs:
- `🔄` = Request retry attempt
- `📤` = New request sent
- `✅` = Response received
- `❌` = Request failed
- `⚠️` = Warning/timeout

## Backend Support

The backend must:
- Accept requests from your deployed origins
- Return proper CORS headers (already implemented in updated `server.js`)
- Respond to preflight OPTIONS requests

All of this is already configured in `tsf-backend-main/server.js`.

## Questions?

If a specific Android device still fails:
1. Check the debug logs
2. Verify the backend is running and accessible
3. Ensure `ApiConfig.baseUrl` points to correct backend
4. The frontend will automatically retry, so wait a few seconds for all retries to complete

---

**Status:** ✅ Deployed to Cloudflare Pages
**Build:** Flutter web with automatic Android CORS retry logic
**Next:** Migrate remaining screens to use `ApiClient`
