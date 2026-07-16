# Release Checklist - Production Launch

This checklist outlines the quality gates and release steps required before deploying client builds to production.

---

## 1. Code Quality & Formatting Gate
- [ ] Run code format:
  ```bash
  flutter format lib/
  ```
- [ ] Execute static analysis:
  ```bash
  flutter analyze
  ```
  *Gate Criteria*: Zero errors or warning indicators are allowed in the analysis report.

---

## 2. Testing Gate
- [ ] Run the test suite:
  ```bash
  flutter test
  ```
  *Gate Criteria*: All tests in [widget_test.dart](file:///d:/TSF/tsf-vms-flutter/test/widget_test.dart) must pass.

---

## 3. Configuration & Target Environment Verification
- [ ] Open [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart).
- [ ] Set `kIsDebug = false` to enforce Koyeb API targets.
- [ ] Open `pubspec.yaml` and increment the version code/build suffix:
  - Format: `version: major.minor.patch+build` (e.g. `version: 1.0.2+3`).
- [ ] Ensure that key signing configurations are set to compile using release profiles.

---

## 4. Compilation Steps
- [ ] Clean previous compilation outputs:
  ```bash
  flutter clean
  ```
- [ ] Fetch dependencies:
  ```bash
  flutter pub get
  ```
- [ ] Build Android Release AAB:
  ```bash
  flutter build appbundle --release
  ```
- [ ] Build Web Release assets:
  ```bash
  flutter build web --release
  ```

---

## 5. Deployment & Post-Release Verification
- [ ] Confirm database backup triggers completed before backend deployment.
- [ ] Deploy server updates to Koyeb.
- [ ] Upload compiled client bundles (AAB/APK/Web) to target app stores or hosting platforms.
- [ ] Perform a sanity check: Log in as admin, check dashboard counters, log a call, and verify that notification triggers update properly.
