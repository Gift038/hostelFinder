import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_controller.dart';
import '../home/tenants_dashboard.dart';
import '../home/managers_dashboard.dart';
import '../auth/register_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color coffeeBrown = const Color(0xFF4B2E05);
  final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
  final Color tan = const Color(0xFFD7BFA6);

  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _authError;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _authError = null; });
    final authController = AuthController();
    final error = await authController.loginUser(email: _email, password: _password);
    if (!mounted) return;
    if (error != null) {
      setState(() { _authError = error; _loading = false; });
      return;
    }
    // Fetch user data and route
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        if (data['role'] == 'Tenant') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TenantsDashboardScreen()));
        } else if (data['role'] == 'Hostel Manager') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManagerDashboard()));
        } else {
          setState(() { _authError = 'Unknown user role.'; });
        }
      } else {
        setState(() { _authError = 'User data not found.'; });
      }
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: coffeeBrown,
        title: const Text('Log In'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: coffeeBrown.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  Icon(Icons.login, color: coffeeBrown, size: 48),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown),
                    ),
                  ),
                  const SizedBox(height: 24),
              TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.email, color: lightCoffeeBrown),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: coffeeBrown, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                ),
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                    onChanged: (v) => _email = v,
              ),
                  const SizedBox(height: 16),
              TextFormField(
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.lock, color: lightCoffeeBrown),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: coffeeBrown, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: lightCoffeeBrown),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                    onChanged: (v) => _password = v,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
              TextButton(
                onPressed: () {},
                        style: TextButton.styleFrom(foregroundColor: coffeeBrown),
                child: const Text('Forgot Password?'),
              ),
              TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterAccountScreen()),
                          );
                        },
                        style: TextButton.styleFrom(foregroundColor: coffeeBrown),
                        child: const Text("Sign Up"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coffeeBrown,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login'),
                  ),
                  if (_authError != null) ...[
                    const SizedBox(height: 12),
                    Text(_authError!, style: const TextStyle(color: Colors.red)),
            ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 