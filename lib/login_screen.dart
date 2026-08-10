import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';
import 'register_screen.dart';
import 'config/api_config.dart';
import 'config/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool _otpSent = false;
  bool _isLoading = false;

  final String baseUrl = ApiConfig.apiUrl;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please enter your email", style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email}),
      );

      // Safely parse response body only if present
      Map<String, dynamic>? data;
      if (res.body != null && res.body.isNotEmpty) {
        try {
          data = json.decode(res.body) as Map<String, dynamic>;
        } catch (_) {
          data = null;
        }
      }

      if (res.statusCode == 200 && data != null && data["success"] == true) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("OTP sent to your email", style: GoogleFonts.poppins()),
          backgroundColor: AppColors.accentGreen,
        ));
      } else {
        final msg = data != null ? (data["message"] ?? "Failed to send OTP") : 'Failed to send OTP (status ${res.statusCode})';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Send OTP failed: $e');
        debugPrint('$stackTrace');
      }

      final message = kIsWeb
          ? 'Network error. On web this often means the backend blocked the request (CORS). Ensure the API allows this origin or use a proxy.'
          : 'Network error. Check your connection and try again.';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please enter OTP", style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "otp": otp}),
      );

      Map<String, dynamic>? data;
      if (res.body != null && res.body.isNotEmpty) {
        try {
          data = json.decode(res.body) as Map<String, dynamic>;
        } catch (_) {
          data = null;
        }
      }

      if (res.statusCode == 200 && data != null && data["success"] == true) {
        // Save token separately for API calls
        await secureStorage.write(key: "token", value: data["token"]);
        
        // Also save full userData for profile/home screen
        await secureStorage.write(
          key: "userData",
          value: json.encode({
            "token": data["token"],
            "user": data["user"],
          }),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data != null ? (data["message"] ?? "OTP verification failed") : 'OTP verification failed (status ${res.statusCode})', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Verify OTP failed: $e');
        debugPrint('$stackTrace');
      }

      final message = kIsWeb
          ? 'Network/server error. On web this may be CORS-related. Ensure the API allows requests from this origin.'
          : 'Server error. Try again.';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width < 450 ? double.infinity : 400,
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', height: 120),
                  const SizedBox(height: 20),
                  Text(
                    "Pathways for Purpose",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Volunteer Management System",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_otpSent)
                    TextFormField(
                      controller: _otpController,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: "OTP",
                        prefixIcon: Icon(Icons.lock_clock, color: AppColors.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  
                  if (!_otpSent)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text("Send OTP", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),

                  if (_otpSent)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accentGreen, Colors.green.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text("Login", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  
                  // Registration link
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    children: [
                      Text("Don't have an account?", style: GoogleFonts.poppins(fontSize: 14)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                        },
                        child: Text(
                          "Register",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Admin login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin-login');
                    },
                    child: Text(
                      "Admin Login",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}