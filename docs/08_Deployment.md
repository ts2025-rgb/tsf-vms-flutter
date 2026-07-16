# Deployment Runbook - PY4P VMS

This runbook documents the deployment, scaling, build, and rollback procedures for the VMS system client and backend services.

---

## 1. System Environments & Configurations

### 1.1 Client Environment Constants
Located in [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart). Before compilation, toggles must be set to match target environments:
- **Development (kIsDebug = true)**: Utilizes local servers exposed via ngrok tunnels.
  - Development URL: `https://shrew-concrete-cobra.ngrok-free.app`
- **Production (kIsDebug = false)**: Points to the live Koyeb production deployment.
  - Production URL: `https://frantic-mable-saluman-ef0457fa.koyeb.app`

---

## 2. Infrastructure Setup (Backend)

### 2.1 Hosting Platform: Koyeb
The Node.js Express backend is deployed as a Docker container service on Koyeb.
- **Reverse Proxy & SSL**: Auto-terminated by Koyeb's edge routers using automatic Let's Encrypt SSL/TLS certificates.
- **Port Routing**: Exposed on port 80/443 (internally routed to port 8080 or matching `PORT` environment variables on Express).
- **Domains**: Inferred production domain: `frantic-mable-saluman-ef0457fa.koyeb.app`.
- **Scaling**: Configured with horizontal auto-scaling (minimum 1 instance, maximum 3 instances based on CPU utilization metrics).

### 2.2 Host Environment Variables
The following environment variables are configured on Koyeb:
- `NODE_ENV`: Set to `production`.
- `MONGODB_URI`: Connection string for the managed MongoDB database.
- `JWT_SECRET`: Secret key for signing session tokens.
- `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS`: SMTP credentials to dispatch authentication OTPs.
- `PORT`: Server listen port.

---

## 3. Frontend Client Compilation & Build

To compile release versions of the Flutter client, run the following commands in the workspace root directory:

### 3.1 Android Build
- **APK (Standalone Distribution)**:
  ```bash
  flutter build apk --release --split-per-abi
  ```
  Generates optimized, architecture-specific APK files under `build/app/outputs/flutter-apk/`.
- **AAB (Google Play Store Bundle)**:
  ```bash
  flutter build appbundle --release
  ```
  Generates the Android App Bundle under `build/app/outputs/bundle/release/`.
- **Sign Config**: In Android production pipelines, builds utilize the upload keystore file [upload-keystore.jks](file:///d:/TSF/tsf-vms-flutter/upload-keystore.jks) and corresponding certificate [upload_certificate_new.pem](file:///d:/TSF/tsf-vms-flutter/upload_certificate_new.pem) to sign binaries before store uploads.

### 3.2 Web Build
```bash
flutter build web --release
```
Generates HTML5, JS, and CSS static asset bundles under the `build/web/` folder. This directory is then deployed to static host servers.

### 3.3 iOS Build (macOS Host only)
```bash
flutter build ios --release
```
Compiles and registers iOS bundle files. Must be opened and signed inside Xcode prior to App Store distribution.

---

## 4. Release & Rollback Procedures

### 4.1 Backend Rollback
Since Koyeb tracks build revisions:
1. Log into the Koyeb Console.
2. Select the VMS Backend service.
3. Locate the list of Revisions.
4. Select the last stable revision ID and click **Re-deploy**. This reverts code and database schemas (provided database migrations are backwards-compatible).

### 4.2 Frontend Client Rollback
1. Revert git commits to the last stable release point.
2. Verify version counts in `pubspec.yaml` (e.g. decrement patch number or increment build suffix).
3. Compile a clean build (using `flutter clean` then `flutter build`).
4. Upload the downgraded bundle to Google Play console or App Store and trigger an immediate rollout update.
5. In web hosting, push the previous build contents to Firebase Hosting / Netlify.

---

## 5. Disaster Recovery
- **Database Backup**: Managed MongoDB database backups are scheduled daily.
- **Recovery Points**: Restoring backups requires targeting connection string updates via environment variables to swap cluster endpoints.
- **Failovers**: `Unable to determine from repository`. Database replication limits or failover clusters are not detailed.
