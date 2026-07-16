# Frontend Guide - PY4P VMS Frontend

The frontend client is built using the **Flutter** SDK (version ^3.7.2), rendering a single, responsive application for mobile and web views.

---

## 1. Routing & Navigation
Routing configuration is centralized in the root file [main.dart](file:///d:/TSF/tsf-vms-flutter/lib/main.dart).
- **Named Routes**: Static pages are loaded using a named route table:
  - `/login`: [login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart) (Login view)
  - `/home`: [home_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/home_screen.dart) (Volunteer landing page)
  - `/profile`: [profile_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/profile_screen.dart) (User profile settings)
  - `/admin-login`: [admin_login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_login_screen.dart) (Admin auth gateway)
  - `/admin`: [admin_home.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_home.dart) (Admin portal layout)
  - `/admin/volunteers`: [admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart) (Main volunteer list)
  - `/admin/vms/dashboard`: [vms_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/vms_dashboard_screen.dart)
  - `/admin/ccp/dashboard`: [ccp_admin_dashboard_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/ccp_admin_dashboard_screen.dart)
  - `/admin/vms/certificates`: [certificate_management_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/certificate_management_screen.dart)
  - `/notifications`: [notifications_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/volunteer/notifications_screen.dart)
  - `/admin/notifications`: [admin_notifications_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/admin_notifications_screen.dart)
  - `/admin/neomami`: [neomami_admin_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/neomami_admin_screen.dart)
  - `/neomami-hub`: [neomami_hub_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/volunteer/neomami_hub_screen.dart)
- **Dynamic Routing**: Managed inside `onGenerateRoute` inside [main.dart](file:///d:/TSF/tsf-vms-flutter/lib/main.dart):
  - `/admin/vms/volunteer/:id` navigates to [volunteer_detail_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/volunteer_detail_screen.dart).
  - `/admin/vms/handover/:id` navigates to [handover_form_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/handover_form_screen.dart).

---

## 2. Layouts & Responsive Design
- **Cross-Platform Adaptation**: Screens dynamically adjust width using `MediaQuery`. For example, in [login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart#L132), layout boxes restrict width to 400px on desktop web layouts but expand to full width on mobile screens:
  ```dart
  width: MediaQuery.of(context).size.width < 450 ? double.infinity : 400
  ```
- **Grid Lists & Scrollables**: Handled dynamically using `CustomScrollView`, `SliverGrid`, and `ListView.builder` inside [admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart) and [companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart).

---

## 3. Reusable UI Components
Common widgets are placed in the `lib/widgets/` directory:
- **`DashboardStatCard`** ([dashboard_stat_card.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/dashboard_stat_card.dart)): Displays counts with label, icon, and colors.
- **`GamificationProgressWidget`** ([enhanced_metrics_widgets.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/enhanced_metrics_widgets.dart)): Tracks call counts (3, 6, 9, 12 milestones) with a progress bar.
- **`LifecycleProgressIndicator`** ([lifecycle_progress_indicator.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/lifecycle_progress_indicator.dart)): Visualizes steps from onboarding, training, mentoring, to certificate ready.
- **`NotificationBell`** ([notification_bell.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/notification_bell.dart)): Displayed in application headers to trigger notifications with real-time badges.
- **`VMSVolunteerCard`** ([vms_volunteer_card.dart](file:///d:/TSF/tsf-vms-flutter/lib/widgets/vms_volunteer_card.dart)): Standardized volunteer preview element showing locations, stage tags, and options.

---

## 4. Theme & Styling
- **Primary Font**: Uses `Poppins` configured globally via Google Fonts inside [main.dart](file:///d:/TSF/tsf-vms-flutter/lib/main.dart#L48).
- **Colors**: Standardized palette is declared in [app_colors.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/app_colors.dart):
  - Brand Blues: `primaryBlue` (0xFF006896), `secondaryBlue` (0xFF0197b2), `tertiaryBlue` (0xFF00adc9).
  - Accent Colors: `accentGreen` (0xFF2e8a57), `accentYellow` (0xFFf1dd6b), `accentOrange` (0xFFf46640).
- **Gradients**: Custom gradients like `primaryGradient` (Blue to Teal) are applied to buttons, app bars, and dashboards.

---

## 5. Forms & Validation
Input validations are executed on the client side using standard `Form` states:
- **Email Validation**: Checked during OTP request and registration ([login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart)).
- **Numeric Duration**: Duration validated to be between 1 and 180 minutes before submitting call logs ([companionconnect.dart](file:///d:/TSF/tsf-vms-flutter/lib/companionconnect.dart)).
- **Required Text Fields**: Form fields are tracked using `TextEditingController` controllers and validated before submission.

---

## 6. State Management
- **Provider Architecture**: Uses `ChangeNotifierProvider` globally initialized in [main.dart](file:///d:/TSF/tsf-vms-flutter/lib/main.dart#L31).
- **Notification State**: [notification_provider.dart](file:///d:/TSF/tsf-vms-flutter/lib/providers/notification_provider.dart) triggers notifications count checks, polling requests, and updates across widgets.
- **Local Screen States**: Managed using `StatefulWidget` widgets and local `setState` updates for pagination, sorting filters, and modal transitions.

---

## 7. Accessibility
- Touch targets set to standard minimum padding.
- Contrasting text elements (dark gray `#333333` vs. white `#ffffff`).
- Accessibility support via standard Flutter screen reader (Semantic) compliance.
