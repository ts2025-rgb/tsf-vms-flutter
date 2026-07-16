# Known Issues & Bug History

This document lists discovered bugs, impact evaluations, and remediation code blocks.

---

## 1. Resolved Bug: Certificate Eligibility Calculation

- **Symptom**: Volunteers were flagged as eligible for certificate generation before they completed their exit handovers.
- **Severity**: **High**. Led to incorrect certifications.
- **Cause**: Backend criteria checked only months of tenure (`volunteeringDurationMonths >= 3`) without verifying exit statuses.
- **Remediation**: Eligibility check updated to require:
  - Active mentoring status set to `completed`.
  - Exit status set to `handover_completed`.
  - Tenure tenure greater than or equal to 3 months.
- **Files involved**: Inferred backend controllers, matched on client in [volunteer_model.dart](file:///d:/TSF/tsf-vms-flutter/lib/models/volunteer_model.dart).

---

## 2. Resolved Bug: Notification Badge Count Sync Failures

- **Symptom**: The unread count badge stuck at stale values even after reading/marking messages.
- **Severity**: **Medium**. Led to inconsistent UX.
- **Cause**: Rollback sequence failed to execute during optimistic UI updates when API request timed out.
- **Remediation**: Implemented robust exception catcher wrapper to trigger rollback:
  ```dart
  try {
    await NotificationService.markOneAsRead(token, id);
  } catch (_) {
    // Roll back optimistic UI changes
    notifications[idx] = notifications[idx].copyWith(isRead: false);
    unreadCount++;
    notifyListeners();
  }
  ```
- **Files involved**: [notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart).

---

## 3. Configuration Issue: Committed Android Release Keystore

- **Symptom**: The keystore binary `upload-keystore.jks` is stored inside the git repository.
- **Severity**: **Medium**. Configuration risk.
- **Impact**: Keystore and PEM certificate files are visible to any developer with repository checkout access.
- **Remediation**: Remove binary and configure keystores dynamically via environment secrets.
- **Files involved**: [upload-keystore.jks](file:///d:/TSF/tsf-vms-flutter/upload-keystore.jks) and [upload_certificate_new.pem](file:///d:/TSF/tsf-vms-flutter/upload_certificate_new.pem).
