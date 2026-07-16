# System Sequence Diagrams

This document contains sequence diagrams for the system's core workflows: Authentication, Dashboard Loading, Analytics, and Notifications.

---

## 1. User Authentication Flow (OTP-Based Login)
Volunteers log in without passwords using OTP codes sent to their emails.

```mermaid
sequenceDiagram
    autonumber
    actor Volunteer
    participant Login as LoginPage (login_screen.dart)
    participant Storage as FlutterSecureStorage
    participant API as Backend REST API
    participant SMTP as SMTP Email Server

    Volunteer->>Login: Enter Email
    Login->>API: POST /auth/send-otp (email)
    API->>SMTP: Dispatch OTP email
    API-->>Login: JSON { success: true }
    Login-->>Volunteer: Show SnackBar & OTP input field
    Volunteer->>Login: Enter OTP Code
    Login->>API: POST /auth/verify-otp (email, otp)
    Note over API: Verify OTP code & generate JWT token
    API-->>Login: JSON { success: true, token, user }
    Login->>Storage: Write token & userData values
    Login->>Volunteer: Navigate to HomePage
```

---

## 2. Dashboard Loading Data Flow
Admin requests statistical totals for all volunteers.

```mermaid
sequenceDiagram
    autonumber
    actor Admin
    participant Dashboard as VMSDashboardScreen
    participant Service as VMSService (vms_service.dart)
    participant Storage as FlutterSecureStorage
    participant API as Backend REST API

    Admin->>Dashboard: Open VMS Dashboard
    Dashboard->>Service: getDashboard()
    Service->>Storage: Read "adminToken"
    Storage-->>Service: Return adminToken
    Service->>API: GET /admin/vms/dashboard (with Authorization Header)
    Note over API: Verify JWT is Admin role
    API-->>Service: JSON { success: true, stats: {...} }
    Service-->>Dashboard: Return VMSDashboardStats model
    Dashboard->>Admin: Render Dashboard widgets
```

---

## 3. Enhanced Metrics Flow (Advanced Analytics)
Admin loads aggregated analytics filtered by date range.

```mermaid
sequenceDiagram
    autonumber
    actor Admin
    participant Screen as EnhancedVMSDashboardScreen
    participant Service as VMSService (vms_service.dart)
    participant API as Backend REST API

    Admin->>Screen: Tap Analytics icon & Select filter (e.g. 'week')
    Screen->>Service: getEnhancedDashboard(filter: 'week')
    Service->>API: GET /admin/vms/dashboard/enhanced?filter=week (with JWT header)
    Note over API: Aggregates CallSessions, MoodTracking, SelfEsteem, Ratings
    API-->>Service: JSON { success: true, data: {...} }
    Service-->>Screen: Return EnhancedDashboardStats model
    Screen->>Admin: Update cards with trends & statistics
```

---

## 4. Polling Notification Flow
Monitors new notifications in the background.

```mermaid
sequenceDiagram
    autonumber
    participant App as App Context
    participant Prov as NotificationProvider (notification_provider.dart)
    participant Service as NotificationService (notification_service.dart)
    participant API as Backend REST API

    App->>Prov: init() on login
    Loop Every 60 Seconds
        Prov->>Service: getNotificationCount(token)
        Service->>API: GET /notifications/count (with Bearer Token)
        API-->>Service: JSON { data: { unread: 5 } }
        Service-->>Prov: Return unreadCount
        Prov->>App: notifyListeners() (Updates badge count)
    End
```
