# Developer Onboarding & Quickstart

This guide outlines software requirements and setup procedures to configure local environments for VMS client development.

---

## 1. Prerequisites

Before setting up the project, install the following software packages on your development machine:
- **Flutter SDK**: version `3.7.x` (target: SDK `^3.7.2` matching constraints in [pubspec.yaml](file:///d:/TSF/tsf-vms-flutter/pubspec.yaml#L22)).
- **Dart SDK**: version `3.7.x`.
- **Android Studio** (with Android SDK and Emulator configured) or **Xcode** (for macOS iOS debugging).
- **Git** version control tool.
- **VS Code** or Android Studio with Flutter extensions.

---

## 2. Setting Up the Local Codebase

Execute the following commands in your terminal to initialize the project:

```bash
# 1. Clone the repository
git clone <repository-url>
cd tsf-vms-flutter

# 2. Retrieve all Flutter dependencies
flutter pub get

# 3. Verify compilation status
flutter analyze
```

---

## 3. Configuring Local API Servers

### 3.1 ngrok Local Tunnel Configuration
To test dynamic updates on physical emulators:
1. Spin up your local API server backend (typically Node.js on port 8080/5000).
2. Start the ngrok tunnel:
   ```bash
   ngrok http 8080
   ```
3. Copy the secure HTTP endpoint URL returned by ngrok.
4. Open [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart) and paste the URL as the `_debugBaseUrl` value:
   ```dart
   static const String _debugBaseUrl = "https://<your-subdomain>.ngrok-free.app";
   ```
5. Set the debug flag to true:
   ```dart
   static const bool kIsDebug = true;
   ```

---

## 4. Running and Verifying Setup

### 4.1 Launching in Debug Mode
To start development servers on a connected emulator or browser:
```bash
# Launch on default emulator
flutter run

# Launch in Web Chrome browser
flutter run -d chrome
```

### 4.2 Running Tests
Validate the development setup by running the test suite:
```bash
flutter test
```
The test suite verify standard launchers and widget titles configured in [widget_test.dart](file:///d:/TSF/tsf-vms-flutter/test/widget_test.dart).
