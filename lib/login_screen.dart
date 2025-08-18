import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';
import 'register_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

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

  final String baseUrl = "https://shrew-concrete-cobra.ngrok-free.app/api"; // Replace with your actual URL

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

      final data = json.decode(res.body);
      if (res.statusCode == 200 && data["success"]) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("OTP sent to your email", style: GoogleFonts.poppins()),
          backgroundColor: Colors.teal,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data["message"] ?? "Failed to send OTP", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Network error. Try again.", style: GoogleFonts.poppins()),
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

      final data = json.decode(res.body);
      if (res.statusCode == 200 && data["success"]) {
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
          content: Text(data["message"] ?? "OTP verification failed", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Server error. Try again.", style: GoogleFonts.poppins()),
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
                    "Tengbang Sintha Foundation",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Volunteer Management System",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.teal[700],
                    ),
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        prefixIcon: const Icon(Icons.lock_clock, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                  const SizedBox(height: 16),
                  
                  if (!_otpSent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
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
                            : Text("Send OTP", style: GoogleFonts.poppins(fontSize: 16)),
                      ),
                    ),

                  if (_otpSent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
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
                            : Text("Login", style: GoogleFonts.poppins(fontSize: 16)),
                      ),
                    ),

                  const SizedBox(height: 20),
                  
                  // Registration link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?", style: GoogleFonts.poppins(fontSize: 14)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                        },
                        child: Text(
                          "Register",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.teal[700],
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