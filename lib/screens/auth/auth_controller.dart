import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../home/tenants_dashboard.dart';
import '../home/managers_dashboard.dart';

class AuthController {
  static Future<void> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>;

      Provider.of<UserProvider>(context, listen: false).setUser(
        name: userData['fullName'] ?? '',
        contact: userData['contact'] ?? '',
        gender: userData['gender'] ?? '',
        email: userData['email'] ?? '',
        school: userData['school'] ?? '',
        programme: userData['programme'] ?? '',
        yearOfStudy: userData['yearOfStudy'] ?? '',
        role: userData['role'] ?? '',
        hostelManaged: userData['hostelManaged'] ?? '',
      );

      if (userData['role'] == 'Tenant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TenantsDashboardScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManagerDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    }
  }

  static Future<void> register({
    required BuildContext context,
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'fullName': fullName,
            'email': email,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });

      Provider.of<UserProvider>(context, listen: false).setUser(
        name: fullName,
        email: email,
        role: role,
        contact: '',
        gender: '',
        school: '',
        programme: '',
        yearOfStudy: '',
        hostelManaged: '',
      );

      if (role == 'Tenant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TenantsDashboardScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManagerDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }
  }
}
