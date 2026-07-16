# Repository Audit Report

This report evaluates code quality, structural architecture, and technical debt in the repository.

---

## 1. File & Folder Quality Audit

### 1.1 Unused Files
- **`lib-backup1.7z`**: Large archive backup file in the repository root. Should be removed.
- **`.add_imports.txt`**: Unused text file.

### 1.2 Exceptionally Large Files
- **[companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart)**: 164 KB, 3,744 lines. Contains massive UI layouts mixed with call note calculations and API calls.
- **[admin_mentee_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_mentee_management.dart)**: 126 KB, ~2,000 lines. Handles both mentee table rendering and assignment transactions.
- **[ccp_admin_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/ccp_admin_dashboard_screen.dart)**: 136 KB. Handles charts, queries list, and statistics widgets in a single class.
  - *Mitigation*: Refactor these files by splitting layouts into sub-widgets and extracting state/logic into state controllers.

---

## 2. Architectural Smells

### 2.1 UI & Logic Mix (Fat View Controllers)
Many screens perform API requests or manipulate model states directly inside widget build functions or state methods rather than delegating tasks to service layers (e.g., [login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart) and [register_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/register_screen.dart)).

### 2.2 Polling Overhead
Background notification check is implemented as active polling via [notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart#L307) rather than utilizing server-push mechanisms (FCM/WebSockets).

### 2.3 Hardcoded Environment Toggles
Environment mapping relies on toggling a static boolean constant `kIsDebug` inside [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart#L7) prior to builds. This can lead to deploying debugging configurations to production.
  - *Remediation*: Switch to compile-time variables (`--dart-define`).

---

## 3. Testing Coverage Deficit
- **Audit Findings**: The `test/` directory contains only a single placeholder file: [widget_test.dart](file:///d:/TSF/tsf-vms-flutter/test/widget_test.dart).
- There are **no unit tests** written to verify:
  - Model parses (e.g., [enhanced_metrics_model.dart](file:///d:/TSF/tsf-vms-flutter/lib/models/enhanced_metrics_model.dart)).
  - Service methods ([vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart)).
  - Complex lifecycle status logic check.
- **Recommendation**: Write tests for parsing methods and state transitions.

---

## 4. Documentation Completeness
- **Pre-Audit State**: Root README.md was a default template. No system-level design docs existed.
- **Post-Audit State**: Core documentation is stored inside the `docs/` folder, and the root README.md has been rewritten.
