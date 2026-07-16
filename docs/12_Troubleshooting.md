# Troubleshooting Guide - Production Issues

This document compiles troubleshooting steps for common client and configuration errors.

---

## 1. Network & API Connectivity Failures

### Symptom: App hangs on loading spinner or displays "Connection error"
- **Potential Cause 1**: The client is configured to use the development API endpoint but the ngrok tunnel is offline.
  - *Verification*: Open [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart) and check if `kIsDebug` is set to `true`.
  - *Fix*: Turn on the local API server and run `ngrok http <port>`. Update `_debugBaseUrl` with the new URL.
- **Potential Cause 2**: The client was compiled with `kIsDebug = true` and deployed to production.
  - *Fix*: Set `kIsDebug = false` in [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart) and rebuild the application.

---

## 2. Authentication & Session Failures

### Symptom: OTP codes are not received by users
- **Potential Cause 1**: SMTP server credentials configured on the backend are incorrect or have expired.
  - *Fix*: Check the SMTP environment variables on Koyeb. Ensure that credentials (port, host, password) match the mail provider settings.
- **Potential Cause 2**: The target email does not exist in the database (for login routes) or is invalid.
  - *Fix*: Ensure the volunteer has completed signup via [register_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/register_screen.dart) before attempting login.

### Symptom: The app redirects to the Login screen immediately after a successful OTP confirmation
- **Potential Cause 1**: The local token storage write failed.
  - *Fix*: Clear app cache/storage on the client device. This resets `flutter_secure_storage` descriptors.
- **Potential Cause 2**: The JWT token returned by the server has expired or has an invalid signature.
  - *Fix*: Verify server system clocks on Koyeb to ensure synchronized timestamps.

---

## 3. Program & Role Access Restrictions

### Symptom: Volunteer receives a "Not subscribed to Neomami program" popup
- **Cause**: The volunteer is approved but has not enrolled in the Neomami Hub program module.
  - *Fix*: Enroll the volunteer via the programs interface. For testing, locate the user record in the MongoDB `volunteers` collection and ensure `"Neomami Hub"` or `"Companion Connect"` is appended to the `interestedPrograms` array.

---

## 4. Admin Operations Failures

### Symptom: Volunteer does not show up in the Certificate Eligible list
- **Cause**: The volunteer has not satisfied all completion criteria:
  - Mentoring status is not `completed`.
  - Exit status is not `handover_completed`.
  - Total tenure duration is less than 3 months.
  - *Fix*: Verify the volunteer's record in the admin panel ([volunteer_detail_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/volunteer_detail_screen.dart)) and update the statuses to satisfy eligibility conditions.
