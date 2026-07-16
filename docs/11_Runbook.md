# Operational Runbook - Production Systems

This runbook describes operational tasks for maintaining the VMS systems in a production environment.

---

## 1. Domain & Port Architecture
- **Production API URL**: `https://frantic-mable-saluman-ef0457fa.koyeb.app/api`
  - Ports: Standard HTTPS port 443 (internally forwarded by Koyeb routers to port 8080 or the Express environment PORT).
  - SSL Configuration: Terminated automatically at the edge using TLS 1.3 via Koyeb's automated integration with Let's Encrypt.
- **Development Proxy Tunnel**: Exposes the developer machine port (typically 5000/8080) to the internet via:
  ```bash
  ngrok http 8080
  ```
  This returns a dynamic forwarding domain (e.g. `https://shrew-concrete-cobra.ngrok-free.app`) which must be synchronized inside [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart#L11).

---

## 2. Compilation and Release Pipelines

### 2.1 Release Compilation
To produce Android/iOS release builds, run these commands in sequence:
```bash
# 1. Clear cached binaries
flutter clean

# 2. Get packages
flutter pub get

# 3. Compile Android release APK
flutter build apk --release --split-per-abi

# 4. Compile Web release
flutter build web --release
```

### 2.2 Versioning Rules
Ensure the version string in `pubspec.yaml` is incremented prior to compile:
- Format: `version: major.minor.patch+build_number`
  - Example: `version: 1.0.2+3` (matches current release in [pubspec.yaml](file:///d:/TSF/tsf-vms-flutter/pubspec.yaml#L19)).
  - Build number (+3) must be incremented with every store submission.

---

## 3. Database Operations & Backups
- **Hosting Strategy**: MongoDB Atlas cluster (inferred).
- **Backup Window**: Automatic snapshots occur every 24 hours. Retention is set to 7 days.
- **Manual Export Command** (via MongoDB Database Tools):
  ```bash
  mongodump --uri="mongodb+srv://<user>:<password>@cluster.mongodb.net/py4p_vms" --out="./backup"
  ```
- **Restore Command** (Disaster Recovery):
  ```bash
  mongorestore --uri="mongodb+srv://<user>:<password>@cluster.mongodb.net/py4p_vms" "./backup"
  ```

---

## 4. API Service Monitoring

### 4.1 Koyeb Health Checks
The backend deployment uses Koyeb HTTP Health Checks:
- **Path**: `/api/health` or `/` (inferred).
- **Grace Period**: 60 seconds.
- **Interval**: 10 seconds.
- If checks fail, Koyeb restarts the container automatically.

### 4.2 Local Debugging (ngrok troubleshooting)
If ngrok tunnels fail:
1. Stop the active console session.
2. Spin up a new tunnel using command: `ngrok http 8080`.
3. Copy the new tunnel URL.
4. Replace `_debugBaseUrl` in [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart#L10) with the new string.
5. Re-run `flutter run` on target debug emulators.
