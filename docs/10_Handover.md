# Handover Guide - Engineering Ownership

This document serves as the official handover handbook for engineers taking over maintenance of the PY4P Volunteer Management System.

---

## 1. Project Navigation (What to Study First)

To quickly understand the frontend codebase structure, study files in this order:
1. **Entry Point & Router**: Read [main.dart](file:///d:/TSF/tsf-vms-flutter/lib/main.dart) to understand routes, dynamic route segments (`/admin/vms/volunteer/:id`), and global providers.
2. **Environment & Styling Config**: Review [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart) to understand how the client switches between debug and production endpoints, and [app_colors.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/app_colors.dart) for style guides.
3. **Core Data Models**: Examine [volunteer_model.dart](file:///d:/TSF/tsf-vms-flutter/lib/models/volunteer_model.dart) to understand how volunteer statuses (`OnboardingStatus`, `TrainingStatus`, `MentoringStatus`, `ExitStatus`) translate to the active lifecycle.
4. **API Service Connector**: Read [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart) to see how authorization tokens are appended to API request headers.
5. **Main User Interfaces**:
   - Volunteer Landing Page: [home_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/home_screen.dart).
   - Core Mentoring Portal: [companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart).
   - Admin Dashboards: [admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart) and [ccp_admin_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/ccp_admin_dashboard_screen.dart).

---

## 2. Critical Business Rules

- **Strict Lifecycle Sequencing**: Volunteers cannot progress to the **Mentoring** phase without their `trainingStatus` being marked as `completed`. This validation is computed dynamically inside the model.
- **Certificate Eligibility**: A volunteer is eligible for a certificate if and only if:
  1. Mentoring status is `completed`.
  2. Tenure duration matches or exceeds 3 months.
  3. Exit status is set to `handover_completed`.
  - If any handover forms are pending, certificate generation is blocked.
- **Neomami Program Authorization**: The Neomami Hub program is restricted. Volunteers must be subscribed to access `/neomami-hub` routes. Non-subscribed volunteers receive `403 Forbidden` responses from the API, which the app intercepts and displays as an error.

---

## 3. Maintenance Protocols

### 3.1 Daily Operations
- **Log Checks**: Monitor ngrok/Koyeb server connection limits.
- **Unresolved Queries**: Check pending queries dashboard ([admin_query_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_query_management.dart)).

### 3.2 Weekly Operations
- **Pending Approvals**: Review pending volunteer signups ([admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart)).
- **Metric Export**: Run data exports from the analytics console to verify CSV/JSON generation functionality ([enhanced_vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/enhanced_vms_dashboard_screen.dart)).

### 3.3 Monthly Operations
- **Dependency Auditing**: Audit package changes inside `pubspec.yaml`.
- **Database Backup Verification**: Verify MongoDB snapshots on the cloud host provider dashboard.

---

## 4. Operational Guardrails

### What Should NEVER Be Changed:
- **`flutter_secure_storage` Setup**: The security options for iOS Keychain and Android EncryptedSharedPreferences (configured in services) must not be simplified. Changing options will prevent active sessions from decrypting tokens, forcing all users to re-login.
- **Centralized API Config structure**: All network components must fetch URLs dynamically from `ApiConfig.apiUrl` ([api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart)). Do not hardcode endpoint domains inside individual services.

### What Can Safely Be Refactored:
- **Notification Polling Engine**: The current setup uses a periodic Timer to query notification counts ([notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart#L307-L318)). This can be refactored to WebSockets or Firebase Push Notifications to reduce API overhead.
- **Charts and Graphs rendering**: The visual indicators on [enhanced_vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/enhanced_vms_dashboard_screen.dart) can be upgraded to live charts using the imported `fl_chart` library.

---

## 5. Incident Response Guide
- **Symptom: App displays "Connection error. Please try again." on startup**
  - *Cause*: Backend API is down or kIsDebug flag is mismatched.
  - *Mitigation*: Verify server health on Koyeb. If performing local tests, check if the ngrok URL has expired. If so, spin up a new tunnel and update `_debugBaseUrl` in [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart).
- **Symptom: Admin is unable to log in**
  - *Cause*: Invalid credentials, token expired, or role changed on database.
  - *Mitigation*: Admin accounts must have their role set to `"admin"` in the MongoDB Users collection.
