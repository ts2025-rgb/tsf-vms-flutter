import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'admin_login_screen.dart';
import 'admin_home.dart';
import 'admin.dart';
import 'screens/admin/vms_dashboard_screen.dart';
import 'screens/admin/volunteer_detail_screen.dart';
import 'screens/admin/handover_form_screen.dart';
import 'screens/admin/certificate_management_screen.dart';
import 'models/volunteer_model.dart';
import 'config/app_colors.dart';

void main() {
  runApp(const PY4PVMSApp());
}

class PY4PVMSApp extends StatelessWidget {
  const PY4PVMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PY4P VOLUNTEER MANAGEMENT SYSTEM',
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.backgroundLight1,
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Poppins',
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/admin/volunteers': (context) => const AdminScreen(),
        '/admin/vms/dashboard': (context) => const VMSDashboardScreen(),
        '/admin/vms/certificates': (context) => const CertificateManagementScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes with parameters
        final uri = Uri.parse(settings.name ?? '');
        
        // /admin/vms/volunteer/:id
        if (uri.pathSegments.length == 4 &&
            uri.pathSegments[0] == 'admin' &&
            uri.pathSegments[1] == 'vms' &&
            uri.pathSegments[2] == 'volunteer') {
          final volunteerId = uri.pathSegments[3];
          final volunteer = settings.arguments as Volunteer?;
          return MaterialPageRoute(
            builder: (context) => VolunteerDetailScreen(
              volunteerId: volunteerId,
              initialVolunteer: volunteer,
            ),
          );
        }
        
        // /admin/vms/handover/:id
        if (uri.pathSegments.length == 4 &&
            uri.pathSegments[0] == 'admin' &&
            uri.pathSegments[1] == 'vms' &&
            uri.pathSegments[2] == 'handover') {
          final volunteerId = uri.pathSegments[3];
          final volunteer = settings.arguments as Volunteer?;
          return MaterialPageRoute(
            builder: (context) => HandoverFormScreen(
              volunteerId: volunteerId,
              volunteer: volunteer,
            ),
          );
        }
        
        return null;
      },
    );
  }
}