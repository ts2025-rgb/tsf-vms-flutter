import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'admin_login_screen.dart';
import 'admin.dart';

void main() {
  runApp(const TSFVMSApp());
}

class TSFVMSApp extends StatelessWidget {
  const TSFVMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSF Visit Management System',
      theme: ThemeData(
        primaryColor: const Color(0xFF0A3A81),
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
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
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}