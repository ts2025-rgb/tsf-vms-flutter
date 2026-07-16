# API Documentation - REST Endpoints

All network requests from the Flutter client to the backend REST API are processed via endpoints compiled below. 

Authentication is managed via HTTP Header: `Authorization: Bearer <token>`.
Ngrok bypass header is present on development environments: `ngrok-skip-browser-warning: true`.

---

## 1. Authentication Endpoints

### 1.1 POST `/auth/send-otp`
- **Purpose**: Triggers a passive email OTP generation for passwordless sign-in.
- **Authentication**: None.
- **Authorization**: None.
- **Input**:
  ```json
  { "email": "user@py4p.com" }
  ```
- **Response**:
  ```json
  { "success": true, "message": "OTP sent successfully" }
  ```
- **Files involved**: [login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart)

### 1.2 POST `/auth/verify-otp`
- **Purpose**: Verifies the OTP code sent via email and returns a session JWT token.
- **Authentication**: None.
- **Authorization**: None.
- **Input**:
  ```json
  { "email": "user@py4p.com", "otp": "123456" }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "token": "eyJhbGciOi...",
    "user": {
      "id": "usr_123",
      "email": "user@py4p.com",
      "role": "volunteer"
    }
  }
  ```
- **Files involved**: [login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart)

---

## 2. Volunteer Management (VMS) Endpoints

### 2.1 GET `/admin/vms/dashboard`
- **Purpose**: Fetch statistical aggregates of volunteers across lifecycle stages.
- **Authentication**: Required (`adminToken`).
- **Authorization**: Admin.
- **Response**:
  ```json
  {
    "success": true,
    "stats": {
      "totalVolunteers": 150,
      "activeMentoring": 67,
      "pendingApproval": 12,
      "onboardingCount": 23,
      "trainingCount": 18,
      "exitPendingCount": 5,
      "certificateReadyCount": 8
    }
  }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L31-L51), [vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/vms_dashboard_screen.dart)

### 2.2 GET `/admin/vms/stage/:stage`
- **Purpose**: Fetch a list of volunteers filtered by lifecycle stage.
- **Authentication**: Required (`adminToken`).
- **Authorization**: Admin.
- **Response**:
  ```json
  {
    "success": true,
    "volunteers": [
      {
        "_id": "vol_1",
        "fullName": "Jane Doe",
        "volunteerCode": "PY4P-2025-0012",
        "email": "jane@py4p.com"
      }
    ]
  }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L53-L79), [admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart)

### 2.3 GET `/admin/vms/volunteer/:identifier`
- **Purpose**: Get a detailed profile of a volunteer by ID or volunteer code.
- **Authentication**: Required (`adminToken`).
- **Authorization**: Admin.
- **Response**:
  ```json
  {
    "success": true,
    "volunteer": {
      "_id": "vol_1",
      "fullName": "Jane Doe",
      "onboardingStatus": "completed",
      "trainingStatus": "completed"
    }
  }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L81-L103), [volunteer_detail_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/volunteer_detail_screen.dart)

### 2.4 PATCH `/admin/vms/:id/onboarding`
- **Purpose**: Update volunteer onboarding stage.
- **Authentication**: Required (`adminToken`).
- **Authorization**: Admin.
- **Input**:
  ```json
  { "status": "completed" }
  ```
- **Response**:
  ```json
  { "success": true, "volunteer": { ... } }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L105-L129)

### 2.5 PATCH `/admin/vms/:id/training`
- **Purpose**: Update training stage and optionally schedule dates.
- **Authentication**: Required (`adminToken`).
- **Authorization**: Admin.
- **Input**:
  ```json
  {
    "status": "scheduled",
    "scheduledDate": "2026-02-15T10:00:00.000Z"
  }
  ```
- **Response**:
  ```json
  { "success": true, "volunteer": { ... } }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L131-L161)

### 2.6 PATCH `/admin/vms/:id/mentoring`
- **Purpose**: Set mentoring stage status.
- **Authentication**: Required (`adminToken`).
- **Authorization**: Admin.
- **Input**:
  ```json
  { "status": "active" }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L163-L187)

### 2.7 POST `/admin/vms/:id/request-exit`
- **Purpose**: Initiate a volunteer exit process with matching details.
- **Input**:
  ```json
  { "reason": "Relocating" }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L189-L216)

### 2.8 POST `/admin/vms/:id/handover`
- **Purpose**: Records child mentoring handover notes during volunteer exit transitions.
- **Input**:
  ```json
  {
    "childName": "Alex Smith",
    "childCurrentStatus": "referred",
    "handoverNotes": "Notes go here..."
  }
  ```
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L218-L248), [handover_form_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/handover_form_screen.dart)

### 2.9 POST `/admin/vms/:id/finalize-exit`
- **Purpose**: Finalizes exit workflow flag status.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L250-L270)

### 2.10 POST `/admin/vms/:id/issue-certificate`
- **Purpose**: Issues a completion certificate record.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L272-L292), [certificate_management_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/certificate_management_screen.dart)

### 2.11 GET `/admin/vms/export/csv`
- **Purpose**: Download CSV formatted summary of all volunteers.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L294-L328)

---

## 3. Enhanced Analytics Dashboard Endpoints

### 3.1 GET `/admin/vms/dashboard/enhanced`
- **Purpose**: Fetch all enhanced metrics aggregate (Mood, Self-Esteem, Call Hours, Star Ratings) in a single API roundtrip.
- **Parameters**: `filter` (Enums: `3days`, `week`, `month`, `all`)
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L407-L428), [enhanced_vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/enhanced_vms_dashboard_screen.dart)

### 3.2 GET `/admin/vms/call-metrics`
- **Purpose**: Fetch aggregated call session quantities and hours metrics.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L430-L455)

### 3.3 GET `/admin/vms/mood-metrics`
- **Purpose**: Fetch average mood ratings and trends.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L457-L482)

### 3.4 GET `/admin/vms/self-esteem-metrics`
- **Purpose**: Fetch self-esteem tracking values.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L484-L509)

### 3.5 GET `/admin/vms/call-quality-metrics`
- **Purpose**: Fetch star distribution and rated session counts.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L511-L536)

### 3.6 GET `/admin/vms/mentor-ratings`
- **Purpose**: Fetch mentor rating distributions.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L538-L563)

### 3.7 GET `/admin/vms/volunteers/:id/progress`
- **Purpose**: Fetch call progress milestones (gamification goals).
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L565-L587)

### 3.8 PATCH `/admin/vms/calls/:callId/rate`
- **Purpose**: Rate call quality.
- **Input**: `{ "rating": 5, "notes": "Excellent interaction" }`
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L589-L616)

### 3.9 GET `/admin/vms/export`
- **Purpose**: Export metrics data as CSV or JSON with active time ranges.
- **Files involved**: [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart#L618-L647)

---

## 4. Companion Connect Program (CCP) Endpoints

### 4.1 GET `/api/companion-connect/admin/mentees`
- **Purpose**: Fetch all mentees for admin dashboard view.
- **Files involved**: [admin_mentee_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_mentee_management.dart)

### 4.2 POST `/api/companion-connect/admin/mentees`
- **Purpose**: Create a new mentee.
- **Files involved**: [create_mentee_page.dart](file:///d:/TSF/tsf-vms-flutter/lib/create_mentee_page.dart)

### 4.3 POST `/api/companion-connect/admin/assign-mentee`
- **Purpose**: Assign mentee to volunteer.
- **Input**: `{ "menteeId": "m_1", "volunteerId": "v_1" }`
- **Files involved**: [admin_mentee_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_mentee_management.dart)

### 4.4 GET `/api/companion-connect/mentee`
- **Purpose**: Retrieve the assigned mentee profile for the logged-in volunteer.
- **Files involved**: [companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart)

### 4.5 POST `/api/companion-connect/notes`
- **Purpose**: Log a mentoring call session.
- **Files involved**: [companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart)

---

## 5. Neomami Hub Endpoints

### 5.1 POST `/neomam/entries`
- **Purpose**: Create a Neomami Hub activity entry.
- **Files involved**: [neomami_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/neomami_service.dart#L33-L85), [neomami_hub_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/volunteer/neomami_hub_screen.dart)

### 5.2 GET `/neomam/entries`
- **Purpose**: Get all Neomami Hub entries for the logged-in volunteer.
- **Files involved**: [neomami_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/neomami_service.dart#L89-L140), [neomami_hub_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/volunteer/neomami_hub_screen.dart)

### 5.3 DELETE `/neomam/entries/:id`
- **Purpose**: Delete a Neomami Hub entry.
- **Files involved**: [neomami_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/neomami_service.dart#L253-L295), [neomami_hub_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/volunteer/neomami_hub_screen.dart)

---

## 6. Notifications Endpoints

### 6.1 GET `/notifications/count`
- **Purpose**: Retrieve counts of unread notifications.
- **Files involved**: [notification_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/notification_service.dart#L51-L64)

### 6.2 GET `/notifications`
- **Purpose**: Retrieve paginated list of notifications for the volunteer.
- **Files involved**: [notification_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/notification_service.dart#L24-L49), [notifications_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/volunteer/notifications_screen.dart)

---

## 7. Status Codes & Error Responses
- **`200 OK` / `201 Created`**: Successful execution.
- **`400 Bad Request`**: Validation errors.
- **`401 Unauthorized`**: Token invalid or expired.
- **`403 Forbidden`**: Role authorization checks failed or subscription is missing (e.g. for Neomami Hub endpoints).
- **`500 Internal Server Error`**: Backend server crash or MongoDB query timeout.
