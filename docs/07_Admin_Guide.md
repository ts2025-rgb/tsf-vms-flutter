# Admin Panel Guide - PY4P VMS Admin

This guide outlines the functions, forms, and validation rules for each administrator screen implemented in the PY4P VMS.

---

## 1. Admin Login Screen
- **File**: [admin_login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_login_screen.dart)
- **Purpose**: Authenticates administrative users using passwords (unlike passwordless OTPs for volunteers).
- **Fields**:
  - `Email`: Text field. Required format matching standard email schema.
  - `Password`: Secured text field.
- **Validation**:
  - Validates that fields are not empty before forwarding requests to `/auth/admin-login` (inferred).
- **Dangerous Operations**: None.

---

## 2. Admin Home (Program Selector)
- **File**: [admin_home.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_home.dart)
- **Purpose**: Acts as a central selector for admins to switch between the two major impact programs:
  - **Volunteer Management System (VMS)** (navigates to `/admin/vms/dashboard`)
  - **Companion Connect Program (CCP)** (navigates to `/admin/ccp/dashboard` via `/admin/volunteers`)

---

## 3. Volunteer Lifecycle Management Screen
- **File**: [admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart)
- **Purpose**: Standard dashboard to view pending, approved, and rejected volunteer registrations.
- **Fields**:
  - `Search Box`: Filters lists by names or codes.
- **Dangerous Operations**:
  - `Approve / Reject`: Modifies `approvalStatus` to allow/deny access.
  - `Delete Volunteer`: Hard delete of volunteer records from the server database (permanent loss of history).

---

## 4. VMS Dashboard
- **File**: [vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/vms_dashboard_screen.dart)
- **Purpose**: Visualizes general volunteer metrics (total counts, onboarding pipelines). Includes entry points to Certificate Management, CCP Controls, and the Analytics dashboard.

---

## 5. Enhanced Analytics Dashboard
- **File**: [enhanced_vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/enhanced_vms_dashboard_screen.dart)
- **Purpose**: Centralized console for tracking volunteer mentoring performance, well-being trends (Mood, Self-Esteem), call quantities, hours, and gamification milestone levels.
- **Actions**:
  - `Filter Chip Selector`: Switches views between 3 days, week, month, and all time.
  - `Data Export`: Downloads CSV or JSON formatted spreadsheets of metrics.

---

## 6. Mentee Management Screen
- **File**: [admin_mentee_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_mentee_management.dart)
- **Purpose**: Displays mentees enrolled in the Companion Connect Program. Supports creation and matching/unmatching of mentees with volunteers.
- **Fields**:
  - `Add Mentee form` (triggered via [create_mentee_page.dart](file:///d:/TSF/tsf-vms-flutter/lib/create_mentee_page.dart)):
    - `Full Name`: Required text.
    - `Date of Birth`: Date picker.
    - `Gender`: Dropdown select.
    - `Phone`: Text.
    - `Location`: Text.
- **Dangerous Operations**:
  - `Assign / Unassign Mentee`: Modifies mentor/mentee mappings on the server database.

---

## 7. Query Management Screen
- **File**: [admin_query_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_query_management.dart)
- **Purpose**: Lists questions/requests submitted by mentoring volunteers. Supports submitting administrative replies.
- **Fields**:
  - `Reply text`: Required input validation.
- **Dangerous Operations**: None.

---

## 8. Resource Management Screen
- **File**: [resource_management_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/resource_management_screen.dart)
- **Purpose**: Administrative panel to add, edit, or delete reference links, PDFs, training books, and materials.
- **Fields**:
  - `Title`: Required text.
  - `Category`: Dropdown select.
  - `Description`: Text.
  - `Link`: Required URL verification.
- **Dangerous Operations**:
  - `Delete Resource`: Permanently purges items from database collections.

---

## 9. Certificate Management Screen
- **File**: [certificate_management_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/certificate_management_screen.dart)
- **Purpose**: Scans volunteer databases to locate eligible mentors and dispatch digital certificates.
- **Validation**:
  - Eligible volunteers must have completed 3 months of tenure, exited, and finished all pending child handovers.
- **Dangerous Operations**:
  - `Issue Certificate`: Triggers a non-reversible state change marking the user as certified.

---

## 10. Neomami Admin Dashboard
- **File**: [neomami_admin_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/neomami_admin_screen.dart)
- **Purpose**: Allows admins to monitor activity logs logged by volunteers in the Neomami Hub program.
- **Dangerous Operations**:
  - `Admin Delete Entry`: Overrides volunteer entries and deletes logs from database collections.

---

## 11. Admin Management
- **File**: [admin_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/admin_management.dart)
- **Purpose**: Creates and manages login credentials for other coordinators.
- **Fields**:
  - `Email`: Text field with format validation.
  - `Password`: Text field (minimum length validation).
  - `Role`: Dropdown selection (Admin, Superadmin).
- **Dangerous Operations**:
  - `Deactivate Admin Account`: Revokes login tokens and API access.
