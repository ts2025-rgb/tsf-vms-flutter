# Security Audit & Recommendations

This document outlines the security posture of the PY4P VMS project based on a comprehensive audit of the Flutter client repository.

---

## 1. Identity & Credentials Management

### 1.1 Hardcoded Secrets
- **Audit Findings**: No raw backend API keys, JWT secret keys, or email passwords are stored in the client source files. Config file [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart) contains only base ngrok/Koyeb URLs.
- **Identified Risk**: The release upload keystore [upload-keystore.jks](file:///d:/TSF/tsf-vms-flutter/upload-keystore.jks) is committed directly to the project root directory.
  - *Severity*: **Medium**. While this is an *upload* key (which can be reset on Google Play) and not the Google Play app signing key, committing private keystore binaries directly to version control increases the risk of unauthorized release compilation.
  - *Recommendation*: Remove the keystore binary from the git repository. Add it to `.gitignore` and supply it dynamically inside the CI/CD pipeline using secrets environment variables.

### 1.2 Authentication Strength
- **Volunteer Gateway**: passwordless, OTP-based authentication via emails ([login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart)).
  - *Audit Findings*: OTP code length is validated to be exactly 6 numeric characters before sending verification payloads.
  - *Severity*: **Low**. Passwordless authentication prevents credential stuffing or dictionary attacks.
- **Admin Gateway**: Admin login uses traditional email and password combinations ([admin_login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_login_screen.dart)).
  - *Audit Findings*: `Unable to determine from repository` if there is multi-factor authentication (MFA) or lockouts on repeated password failures.

---

## 2. Authorization (RBAC) & Token Management
- **Token Storage**: JWT access tokens are stored in the client using `flutter_secure_storage` ([login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart#L95)), which implements:
  - iOS: Keychain services.
  - Android: EncryptedSharedPreferences.
  - Web: LocalStorage.
- **Authorization Bypass (Client-side)**: Page routing restrictions are configured via Flutter routes but do not block API endpoints. All write operations rely on backend token role verification.
  - *Identified Risk*: `Unable to determine from repository` if the backend correctly validates that a volunteer token cannot access other volunteers' data on endpoint calls since the backend codebase is external.

---

## 3. Vulnerability Analysis

### 3.1 Injection Vulnerabilities
- **SQL / NoSQL Injection**: Parametric queries and Mongoose ODM schemas protect the database against NoSQL injection.
- **XSS (Cross-Site Scripting)**: The client application runs inside Flutter widgets which automatically escape raw text outputs, neutralizing HTML/JS context injections.
- **Prompt Injection**: Not applicable. There are no AI, LLM, RAG, or embedding vectors configured in this project.

### 3.2 CSRF (Cross-Site Request Forgery)
- Since the Flutter client handles tokens in request headers (`Authorization: Bearer <token>`) rather than relying on session cookies, the API is immune to standard cross-site request forgery attacks.

### 3.3 File Upload Security
- **File size restrictions**: The client checks that profile picture assets are under 5MB prior to upload ([PROCESS_REPORT.md](file:///d:/TSF/tsf-vms-flutter/PROCESS_REPORT.md#L1623-L1637)).
- **Input Validation**: Extension validations (e.g. restricting uploads to jpg/png) are managed via standard properties on `image_picker`.

### 3.4 Rate Limiting & Denial of Service (DoS)
- Inferred backend implementations utilize API rate limiting (`express-rate-limit`) configured on endpoint routes.
- **Polling overhead**: The client notification bell polls the backend API `/notifications/count` every 60 seconds ([notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart)). This creates a steady transaction volume that could overload servers if scale matches thousands of active concurrent users.
  - *Recommendation*: Migrate from polling to WebSockets or push notifications (Firebase Cloud Messaging).

---

## 4. Security Audit Scorecard

| Area | Status | Severity | Remediation |
|---|---|---|---|
| Secret Management | Upload keystore checked in | **Medium** | Remove binary, add to `.gitignore` |
| Transport Security | HTTP endpoints in config | **Low** | Enforce HTTPS via TLS settings |
| Authentication | 6-digit OTP validations | **Low** | Implement lockout after consecutive failures |
| Client Storage | Secure Storage wrappers | **Info** | Standard best practices applied |
| Dependency Vulnerabilities | Outdated package imports | **Low** | Run `flutter pub outdated` |
