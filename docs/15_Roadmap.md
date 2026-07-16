# Future Product Roadmap

This document outlines planned updates and technical improvements for the PY4P VMS platform.

---

## 1. Immediate Action Items (Next 30 Days)

### 1.1 Remove Committed Keystore Binaries
- **Goal**: Move [upload-keystore.jks](file:///d:/TSF/tsf-vms-flutter/upload-keystore.jks) and [upload_certificate_new.pem](file:///d:/TSF/tsf-vms-flutter/upload_certificate_new.pem) out of the git repository to prevent credential leaks. Configure automatic signing inside the CI/CD pipeline using secrets variables.

### 1.2 Improve Test Coverage
- **Goal**: Expand tests under `test/` beyond [widget_test.dart](file:///d:/TSF/tsf-vms-flutter/test/widget_test.dart). Write unit tests for JSON models ([volunteer_model.dart](file:///d:/TSF/tsf-vms-flutter/lib/models/volunteer_model.dart)) and service requests.

---

## 2. Short-Term Enhancements (Q3 2026)

### 2.1 Migrate Polling to Push Notifications
- **Goal**: Eliminate the 60-second periodic timer call inside [notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart). Integrate Firebase Cloud Messaging (FCM) or WebSockets to update notification lists in real time.

### 2.2 Error Tracking Integration
- **Goal**: Integrate Sentry or Firebase Crashlytics to monitor client exceptions in production.

---

## 3. Medium-Term Enhancements (Q4 2026)

### 3.1 Offline Form Submissions (Local Cache)
- **Goal**: Allow mentoring volunteers to log call notes without internet connection. Cache data locally using Hive or SQLite databases and sync them when connection is restored.
- **Files impacted**: [companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart), [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart).

### 3.2 Advanced Analytics Visualizations
- **Goal**: Integrate the `fl_chart` package to replace text metrics with live charts (Mood score lines and Call Duration distributions) inside [enhanced_vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/enhanced_vms_dashboard_screen.dart).

---

## 4. Long-Term Roadmap (2027)

### 4.1 In-App Video and Audio Calls
- **Goal**: Integrate Agora or Twilio SDKs to allow volunteers to make calls directly within the app, removing the need for phone numbers.
- **Files impacted**: [companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart).

### 4.2 State Management Migration
- **Goal**: Migrate from Provider ([notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart)) to Riverpod or BLoC patterns for improved testability and page separation.
