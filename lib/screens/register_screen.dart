import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // These controllers capture what the user types in each box
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Boolean variables to toggle password visibility (eye icon)
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // --- DARK MODE COLORS ---
  final Color bgDark = const Color(0xFF02050A);
  final Color deepIndigo = const Color(0xFF1E1B4B);

  // FUNCTIONAL LOGIC FOR REGISTRATION
  Future<void> _handleRegister() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPass = _confirmPasswordController.text.trim();

    // Validations
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill out all fields.");
      return;
    }
    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters.");
      return;
    }
    if (password != confirmPass) {
      _showSnackBar("Password has not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if username exists
      bool taken = await _authService.isUsernameTaken(username);
      if (taken) {
        setState(() => _isLoading = false);
        _showSnackBar("Username has already exist.");
        return;
      }

      // Proceed to the register
      User? user = await _authService.register(email, password, username);
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          _showSnackBar("Account created successfully!");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // 1. BACKGROUND GLOWS
          Positioned(top: -100, right: -50, child: _buildBlurCircle(deepIndigo.withOpacity(0.4))),
          Positioned(bottom: -100, left: -50, child: _buildBlurCircle(const Color(0xFF0F172A).withOpacity(0.3))),

          // 2. MAIN CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    Text("Artstagram", style: TextStyle(fontFamily: 'Lobster', fontSize: 45, color: Colors.white, shadows: [Shadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))])),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: Column(
                        children: [
                          const Text("Create your account\nto get started!", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
                          const SizedBox(height: 35),
                          _buildDarkTextField(controller: _usernameController, label: "Username", hint: "Enter your username", icon: Icons.person_outline),
                          const SizedBox(height: 15),
                          _buildDarkTextField(controller: _emailController, label: "Email", hint: "Enter your email", icon: Icons.mail_outline),
                          const SizedBox(height: 15),
                          _buildDarkTextField(controller: _passwordController, label: "Password", hint: "********", icon: Icons.lock_open_outlined, isPassword: true, isObscured: obscurePassword, toggleVisibility: () => setState(() => obscurePassword = !obscurePassword)),
                          const SizedBox(height: 15),
                          _buildDarkTextField(controller: _confirmPasswordController, label: "Confirm Password", hint: "********", icon: Icons.shield_outlined, isPassword: true, isObscured: obscureConfirmPassword, toggleVisibility: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword)),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const CircularProgressIndicator(color: Color(0xFF6366F1))
                              : _buildGradientButton(text: "Create Account", onTap: _handleRegister),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? ", style: TextStyle(color: Colors.white54, fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text("Login", style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 13)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isPassword = false, bool? isObscured, VoidCallback? toggleVisibility}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? (isObscured ?? true) : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12),
        prefixIcon: Icon(icon, color: Colors.white60, size: 22),
        suffixIcon: isPassword ? IconButton(icon: Icon((isObscured ?? true) ? Icons.visibility_off : Icons.visibility, color: Colors.white30), onPressed: toggleVisibility) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback onTap}) {
    return Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]), boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
    );
  }

  Widget _buildBlurCircle(Color color) {
    return Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: color), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90), child: Container(color: Colors.transparent)));
  }
}