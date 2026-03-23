import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'main_navigator.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool _obscurePassword = true;
  final Color bgDark = const Color(0xFF02050A);
  final Color deepIndigo = const Color(0xFF1E1B4B);

  // FUNCTIONAL LOGIC
  Future<void> _handleLogin() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter username and password.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.loginWithUsername(username, password);
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigator()));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Ipapalabas dito ng system ang "Username not found" o "Incorrect password"
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: _buildBlurCircle(deepIndigo.withOpacity(0.4))),
          Positioned(bottom: -100, left: -50, child: _buildBlurCircle(const Color(0xFF0F172A).withOpacity(0.3))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    Text("Artstagram", style: TextStyle(fontFamily: 'Grandista', fontSize: 45, color: Colors.white, shadows: [Shadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))])),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: Column(
                        children: [
                          const Text("Welcome back!\nLogin with username", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
                          const SizedBox(height: 35),
                          _buildDarkTextField(controller: _usernameController, label: "Username", hint: "Enter your username", icon: Icons.person_outline),
                          const SizedBox(height: 15),
                          _buildDarkTextField(controller: _passwordController, label: "Password", hint: "********", icon: Icons.lock_open_outlined, isPassword: true),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator(color: Color(0xFF6366F1))
                              : _buildGradientButton(text: "Login", onTap: _handleLogin),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("No account? ", style: TextStyle(color: Colors.white54)),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                                child: const Text("Create account", style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
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

  Widget _buildDarkTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12),
        prefixIcon: Icon(icon, color: Colors.white60, size: 22),
        suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white30), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
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