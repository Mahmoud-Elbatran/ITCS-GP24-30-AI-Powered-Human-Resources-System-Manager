import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';


import 'EmployeePage.dart';
import 'onboarding.dart';
import 'HREmployeePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  Future<void> login() async {
    try {
      setState(() => _isLoading = true);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final userEmail = userCredential.user!.email ?? "";

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists || !doc.data()!.containsKey('role')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User role not found.")),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      final role = doc['role'];

      if (!mounted) return;

      if (role == 'new') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      } else if (role == 'employee') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeePage(userEmail: userEmail),
          ),
        );
      } else if (role == 'hr') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HREmployeePage(userEmail: userEmail),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown role.")),
        );
        setState(() => _isLoading = false);
        return;
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Login failed")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final navyBlue = Color(0xFF0A2540); // Navy Blue background color
    final lightBlue = Color(0xFF5A8BD6);

    return Scaffold(
      backgroundColor: navyBlue, // Navy blue background color
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            color: Colors.white, // White color for the card
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Robot icon container with glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: lightBlue.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.android,
                      size: 80,
                      color: lightBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // REBOTA Text - Modern font applied (Poppins)
                  Text(
                    "REBOTA",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Color(0xFF0A2540), // Direct color usage
                      fontFamily: 'Poppins', // Modern font family
                    ),
                  ),
                  const SizedBox(height: 8),
                  // HR Assistant Text - Color updated to match background
                  Text(
                    "Your HR Assistant",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0A2540), // Direct color usage
                      fontFamily: 'Poppins', // Modern font family
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Email TextField with dark background and floating label style
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)), // Lighter color for text
                    decoration: InputDecoration(
                      labelText: 'Email or Phone Number',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)), // Lighter color for label
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF0A2540)), // Direct color usage
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF0A2540), width: 2), // Direct color usage
                      ),
                      filled: true,
                      fillColor: Color(0xFF0A2540), // Direct color usage
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.white), // White icon
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password field with toggle visibility button
                  TextField(
                    controller: passwordController,
                    obscureText: !_passwordVisible,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)), // Lighter color for text
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)), // Lighter color for label
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF0A2540)), // Direct color usage
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF0A2540), width: 2), // Direct color usage
                      ),
                      filled: true,
                      fillColor: Color(0xFF0A2540), // Direct color usage
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white), // White icon
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white, // White icon for password visibility toggle
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Add forgot password functionality
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Color(0xFF0A2540)), // Direct color usage
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Color(0xFF0A2540).withOpacity(0.5); // Navy blue when disabled
                          }
                          return Colors.white; // White for the button background
                        }),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        elevation: MaterialStateProperty.all(8),
                        shadowColor: MaterialStateProperty.all(Color(0xFF0A2540).withOpacity(0.6)),
                        side: MaterialStateProperty.all(BorderSide(color: Color(0xFF0A2540), width: 2)), // Outline border added
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF0A2540), // Direct color usage
                        ),
                      )
                          : const Text(
                        "Login",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)), // Direct color usage
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
