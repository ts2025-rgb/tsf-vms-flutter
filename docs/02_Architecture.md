# High Level Architecture - PY4P VMS

The PY4P Volunteer Management System (VMS) is structured as a **three-tier client-server architecture** composed of a mobile/web client tier, an application API tier, and a data tier.

```mermaid
graph TD
    classDef client fill:#dcfce7,stroke:#166534,stroke-width:2px;
    classDef app fill:#dbeafe,stroke:#1e40af,stroke-width:2px;
    classDef db fill:#fee2e2,stroke:#991b1b,stroke-width:2px;

    subgraph Client Tier [Client Tier - Flutter]
        Web["Web Progressive App"]:::client
        Mobile["Mobile App (Android/iOS)"]:::client
    end

    subgraph Application Tier [Application Tier - Node.js/Express]
        API["REST API Router"]:::app
        Auth["Auth Controller"]:::app
        VMS["VMS Controller"]:::app
        CCP["CCP Controller"]:::app
        Neomami["Neomami Controller"]:::app
        Notif["Notification Service"]:::app
    end

    subgraph Data Tier [Data Tier - MongoDB]
        DB[("MongoDB Database")]:::db
    end

    Client Tier -->|HTTPS / JSON REST API| API
    API --> Auth
    API --> VMS
    API --> CCP
    API --> Neomami
    API --> Notif
    Auth --> DB
    VMS --> DB
    CCP --> DB
    Neomami --> DB
    Notif --> DB
```

---

## 1. Client Tier (Frontend)
The client interface is developed using Flutter (configured in [pubspec.yaml](file:///d:/TSF/tsf-vms-flutter/pubspec.yaml)). It targets mobile platforms (Android, iOS) and web hosting.
Key characteristics:
- **Presentation Layer**: Built using modular, reusable components located in `lib/widgets/` (such as [enhanced_metrics_widgets.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/enhanced_metrics_widgets.dart) and [lifecycle_progress_indicator.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/lifecycle_progress_indicator.dart)).
- **State Management**: Uses the `Provider` architecture for app-wide reactivity (e.g. notifications in [notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart)).
- **Service Layer**: Manages outbound API requests using the HTTP package. Configured in [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart), [neomami_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/neomami_service.dart), [heartbeat_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/heartbeat_service.dart), and [notification_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/notification_service.dart).
- **Secure Key/Token Storage**: Secured using the `flutter_secure_storage` package across platforms.

---

## 2. Application Tier (Backend)
- **Runtime Environment**: Node.js (inferred from package setup described in [PROCESS_REPORT.md](file:///d:/TSF/tsf-vms-flutter/PROCESS_REPORT.md)).
- **Web Server Framework**: Express.js.
- **API Architecture**: RESTful endpoints returning JSON payloads.
- **Authentication**: JWT-based access tokens passed via HTTP `Authorization: Bearer <token>` headers.
- **Services**: Manages core volunteer states, handles notifications matching query triggers, and processes reports.

---

## 3. Data Tier (Database)
- **Database Engine**: MongoDB.
- **Object Document Mapper (ODM)**: Mongoose (inferred from database documentation in [PROCESS_REPORT.md](file:///d:/TSF/tsf-vms-flutter/PROCESS_REPORT.md)).
- **Schemas**: Separate collections for Users, Volunteers, Mentees, CallSessions, MoodTracking, SelfEsteemTracking, MentorRatings, Queries, Notifications, Programs, and Certificates.

---

## 4. Key Architectural Patterns & Features
- **Authentication**: OTP-based authentication (passwordless) using email verification. JWT is generated upon correct OTP validation.
- **Authorization**: Role-based access control (RBAC). Admin operations require roles with "admin" privileges. Regular volunteer operations verify subscription status and ownership.
- **Storage**: Image/document upload pipeline. In-app profile pictures use `image_picker` ([register_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/register_screen.dart)) and file attachment uploads use `file_picker`. Cloud-side storage backend configuration details are: `Unable to determine from repository`.
- **AI / RAG**: `Unable to determine from repository`. No AI models, vector databases, embeddings, prompts, or retrieval systems are present in the frontend or configuration files.
- **OCR**: `Unable to determine from repository`. No Optical Character Recognition modules or libraries are used.
- **Search**: Case-insensitive regex-based search queries on volunteer codes, email, names, and content titles, executed on backend search routes `/admin/vms/search` and `/neomami/admin/volunteers`.
- **Deployment**: Exposes development environments via ngrok tunnels and hosts production services on Koyeb.
- **External Services**: Uses SMTP servers for email-based OTP dispatch.
