# Maintainer Notes - Configuration & Legacy Traps

This document records architectural caveats and operational "gotchas" discovered in the code.

---

## 1. Environment & API URL Configuration Traps

### 1.1 The `kIsDebug` Toggle Trap
If you compile the client with `kIsDebug = true` in [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart#L7), it will attempt to contact the ngrok development URL:
`https://shrew-concrete-cobra.ngrok-free.app`
- **Gotcha**: If you deploy this to the app store or web hosting, production users will experience complete connection failures because the development ngrok tunnel is offline.
- **Rule**: Always verify that `kIsDebug = false` prior to triggering compilation steps.

---

## 2. Authentication & Secure Storage Traps

### 2.1 Secured Keys and Platform Quirks
The token storage relies on `flutter_secure_storage` which acts differently across platforms:
- **Android**: Enabled with `encryptedSharedPreferences: true` ([PROCESS_REPORT.md](file:///d:/TSF/tsf-vms-flutter/PROCESS_REPORT.md#L1331-L1334)). If the user restores their app data via backup utilities, encrypted database keys might become corrupt, causing decryption errors.
  - *Symptom*: App crashes on startup or refuses to load storage.
  - *Fix*: Wrap secure storage read operations in a `try-catch` block. On exceptions, call `delete()` to clear active tokens.
- **Token Keys**: The admin token is stored under the key `"adminToken"`, whereas the volunteer token is stored under `"token"`. Do not mix these keys up in service headers.

---

## 3. Performance Bottlenecks

### 3.1 Scroll Lag in Volunteer Lists
The volunteer list screen ([admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart)) handles rendering all volunteers in one grid list. If the volunteer directory scale reaches over 500 records, the widget tree will experience rendering lag.
- *Fix*: Implement pagination (using `page` and `limit` query parameters) on the volunteer lists endpoint.

### 3.2 Polling Load
The background timer ([notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart#L307)) hits the `/notifications/count` route every 60 seconds. A high volume of concurrent users will cause significant server load.

---

## 4. Key Code Locations and Legacy Snippets
- **Onboarding/Lifecycle Calculation**: Stage resolution logic resides in the frontend model [volunteer_model.dart](file:///d:/TSF/tsf-vms-flutter/lib/models/volunteer_model.dart). If you modify lifecycle flows on the backend, update frontend models correspondingly to prevent UI display mismatches.
- **Keystore Signing Configuration**: Keystores are declared locally in the `android/` directory and use the committed keystore file [upload-keystore.jks](file:///d:/TSF/tsf-vms-flutter/upload-keystore.jks). Maintain copy control of these files outside this repository.
