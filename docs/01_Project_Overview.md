# Project Overview - PY4P Volunteer Management System

## Business Purpose
The **PY4P Volunteer Management System (VMS)** is a custom cross-platform software solution designed to digitalize and automate the volunteer lifecycle for the Pathways for Purpose (PY4P) organization. The system is designed to streamline administrative overhead and enhance volunteer engagement across multiple social impact programs.

## Problem Solved
Before the implementation of this system (as detailed in [PROCESS_REPORT.md](file:///d:/TSF/tsf-vms-flutter/PROCESS_REPORT.md)), the organization faced operational challenges including:
- **Manual Volunteer Tracking**: Volunteer onboarding, progress tracking, and certificate eligibility calculations were managed via spreadsheets and manual reports.
- **Lack of Centralized Metrics**: No unified platform existed to track volunteer well-being metrics (mood and self-esteem), call frequencies, or training statuses.
- **Segmented Program Management**: Separate processes for the core Volunteer Management System and the Companion Connect Program (CCP) led to communication and data silos.
- **Inefficient Communication**: Absence of an in-app notification system to alert volunteers regarding onboarding milestones, training schedules, or query replies.

## Target Users
- **Volunteers**: Registered individuals who perform mentoring, log hours/calls, and complete tasks.
- **Administrators / Coordinators**: Administrative staff who review applications, manage assignments, monitor analytics, and issue certifications.
- **Mentees**: Social program beneficiaries who are paired with volunteers for mentoring and support.
- **Program Managers**: High-level administrators monitoring program health and exporting analytics reports.

## Business Workflow
1. **Registration & Approval**: A volunteer signs up via [register_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/register_screen.dart). Administrators approve or reject the volunteer in [admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart).
2. **Onboarding & Training**: Once approved, the volunteer enters the onboarding phase, followed by training. Admins track and update these lifecycle stages via [status_dropdowns.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/status_dropdowns.dart) and [volunteer_detail_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/volunteer_detail_screen.dart).
3. **Program Mentoring (Companion Connect Program)**: 
   - Admins assign a mentee to the volunteer using [admin_mentee_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_mentee_management.dart).
   - The volunteer logs mentoring calls, durations, mood scores, and discussions using [companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart).
   - The volunteer can submit query requests to admins, which admins answer through [admin_query_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_query_management.dart).
4. **Gamification Progress**: As the volunteer completes mentoring sessions, the app tracks progress against a 12-call target, visualised in [enhanced_metrics_widgets.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/enhanced_metrics_widgets.dart).
5. **Exit & Certification**:
   - The volunteer requests an exit, completes a handover form via [handover_form_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/handover_form_screen.dart), and their exit is finalized.
   - Admins issue certificates of completion via [certificate_management_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/certificate_management_screen.dart) once criteria are met.

## Project Goals
- Maintain a single, consistent cross-platform codebase (Flutter) for volunteer and admin interfaces.
- Standardise volunteer lifecycle tracking (Onboarding -> Training -> Mentoring -> Exit -> Certificate Issued).
- Capture and aggregate volunteer well-being metrics (Mood, Self-Esteem, Call Quality) in real time.
- Provide data export tools (CSV/JSON) for external reporting.

## Major Capabilities
- **Enhanced Analytics**: Comprehensive tracking of average call durations, well-being trends, star ratings, and milestone achievements in [enhanced_vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/enhanced_vms_dashboard_screen.dart).
- **Sub-Program Support (Neomami Hub)**: Dedicated logger for subscribed volunteers to submit learning records and work portfolios in [neomami_hub_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/volunteer/neomami_hub_screen.dart).
- **In-App Notification Engine**: Optimistic state updates and periodic polling for real-time notifications configured in [notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart).

## Current Status
- Frontend Flutter codebase is fully implemented with routes, mock configurations, API service integrations, and UI modules.
- Backend API endpoints are integrated on the client-side as described in [vms_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/vms_service.dart) and [neomami_service.dart](file:///d:/TSF/tsf-vms-flutter/lib/services/neomami_service.dart).

## Limitations
- **External Backend dependence**: Database, Express server, and authorization role assignment are handled externally. 
- **Offline Mode**: Unable to determine from repository. Offline local caching or queue syncing features are currently not implemented in the services.
- **Push Notifications**: Missing native push notification registration (FCM/APNS). Currently uses in-app polling inside [notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart).
