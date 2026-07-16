# Frequently Asked Questions (FAQ)

---

## 1. Developer FAQ

### Q: How do I switch the frontend client between ngrok (development) and Koyeb (production)?
A: Open [api_config.dart](file:///d:/TSF/tsf-vms-flutter/lib/config/api_config.dart) and change `kIsDebug` to `true` (for ngrok development) or `false` (for Koyeb production). Remember to rebuild the app.

### Q: Why does `test/widget_test.dart` fail?
A: The test expects to find "Pathways for Purpose" text on the main login screen. If you modify the logo or title rendering inside [login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart), you must update the query assertion inside [widget_test.dart](file:///d:/TSF/tsf-vms-flutter/test/widget_test.dart#L18).

### Q: Where are session tokens saved?
A: Session tokens are stored locally on user devices using the `flutter_secure_storage` package (details in [login_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/login_screen.dart#L95)).

---

## 2. Administrator FAQ

### Q: How can I approve a pending volunteer application?
A: Go to the Admin dashboard and select the **Pending** list. Review the volunteer's profile and tap the **Approve** button (implemented in [admin.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin.dart)).

### Q: Why does a volunteer not appear in the "Eligible for Certificate" section?
A: A volunteer must meet all eligibility rules before they show up on this list (such as completing 3 months of mentoring and submitting handover notes via [handover_form_screen.dart](file:///d:/TSF/tsf-vms-flutter/lib/screens/admin/handover_form_screen.dart)).

### Q: Where do volunteer queries go?
A: Volunteer questions go to the Query Management console ([admin_query_management.dart](file:///d:/TSF/tsf-vms-flutter/lib/admin_query_management.dart)). Admins can reply to them directly from this screen.

---

## 3. Deployment FAQ

### Q: Can I run this Flutter app in Web mode?
A: Yes. The code utilizes packages like `universal_html` to prevent compilation errors on browser hosts. Build it using `flutter build web --release`.

### Q: How do I configure SSL for the API server?
A: SSL certificates are managed by Koyeb (for production URLs) via automatic Let's Encrypt certificates. You do not need to configure SSL/TLS files manually in this repository.
