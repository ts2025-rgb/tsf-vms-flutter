# Backend Guide - PY4P VMS Backend

The backend codebase for the PY4P VMS is not hosted in this repository; this repository contains only the Flutter client application. The following details have been inferred from the documentation and configuration files located in this repository (specifically [PROCESS_REPORT.md](file:///d:/TSF/tsf-vms-flutter/PROCESS_REPORT.md) and [BACKEND_CHECKLIST.md](file:///d:/TSF/tsf-vms-flutter/BACKEND_CHECKLIST.md)).

---

## 1. Request Lifecycle
When a request is initiated from the Flutter client (such as a request to update onboarding status in [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart)):
1. **Client Dispatch**: The client sends an HTTPS request (e.g., `PATCH /api/admin/vms/:id/onboarding`) with headers containing a JWT bearer token under `Authorization: Bearer <adminToken>`.
2. **Reverse Proxy / SSL Termination**: Handled by Koyeb (Production) or ngrok (Development).
3. **Global Middleware Execution**: 
   - **Rate Limiting**: Limits requests per IP (using `express-rate-limit`).
   - **Security Headers**: Set via the `helmet` package to prevent XSS, clickjacking, and sniff attacks.
   - **CORS Handling**: Allows incoming requests from the frontend client.
4. **Authentication Middleware**: Decodes the JWT token.
   - If invalid/expired, returns `401 Unauthorized`.
   - If valid, binds user details (id, email, role) to the request object (`req.user`).
5. **Authorization Middleware**: Checks permissions (e.g. checks if `req.user.role === 'admin'`).
   - If unauthorized, returns `403 Forbidden`.
6. **Controller Mapping**: Route handler directs the request to the matching controller.
7. **Business Logic & Service Layer**: The controller triggers the service layer.
   - For volunteer lifecycle updates, it updates status fields and calculates duration metrics.
   - Performs database writes/updates via Mongoose.
8. **Audit Logging**: Logs the admin or volunteer action in the AuditLog database collection.
9. **JSON Response Dispatch**: Returns JSON response with `success: true` or `success: false` and corresponding payloads/errors.

---

## 2. Inferred Controllers and Services
- **Auth Module**: 
  - Routes: `/auth/send-otp`, `/auth/verify-otp`.
  - Operations: Validates emails, generates OTPs, triggers SMTP emails, and generates JWT tokens.
- **VMS Analytics Service**:
  - Routes: `/admin/vms/dashboard/enhanced`, `/admin/vms/call-metrics`, `/admin/vms/mood-metrics`.
  - Operations: Aggregates stats from CallSessions, MoodTracking, SelfEsteemTracking, and Volunteers collections.
- **Companion Connect Program (CCP) Service**:
  - Routes: `/companion-connect/admin/mentees`, `/companion-connect/notes`, `/companion-connect/queries`.
  - Operations: Manages mentees, logs call notes, advances progress, and handles volunteer queries.
- **Neomami Hub Program Service**:
  - Routes: `/neomam/entries`, `/neomam/admin/entries-filtered`.
  - Operations: Validates subscriptions and processes CRUD operations for volunteer activity entries.

---

## 3. Repositories (Data Persistence)
Data persistence operations are handled via Mongoose ODM schemas on a MongoDB deployment.
Detailed files, database controllers, or directory layout:
> Unable to determine from repository.

---

## 4. Middleware & Validation
- **Authentication**: JWT token verification.
- **Role Control**: Verification of `req.user.role === 'admin'` for routes starting with `/admin`.
- **Subscription Checks**: Verifies `user.subscribedPrograms` includes `Neomami Hub` before resolving volunteer entries under `/neomam/entries` (described in [neomami_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/neomami_service.dart)).
- **Input Validation**: `Unable to determine from repository` (exact backend validation scripts or schemas are not present).

---

## 5. Dependency Graph
- Runtime: Node.js
- Framework: Express.js
- Database Interface: Mongoose ODM -> MongoDB
- Security: Helmet, Express-Rate-Limit
- Auth: jsonwebtoken
- Transport: nodemailer (for SMTP OTPs)
- Host: Koyeb
- Tunnel: ngrok
