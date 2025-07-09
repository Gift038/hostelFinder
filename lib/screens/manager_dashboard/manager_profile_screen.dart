import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color brown = const Color(0xFF8D6E63);
    final Color white = Colors.white;
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: coffeeBrown,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Avatar and name/email
            Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: brown,
                  child: Icon(Icons.person, size: 60, color: white),
                ),
                const SizedBox(height: 16),
                Text(
                  userProvider.name.isNotEmpty ? userProvider.name : 'Manager Name',
                  style: const TextStyle(
                    color: Color(0xFF4B2E05),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProvider.email.isNotEmpty ? userProvider.email : 'Email',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bio Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF4B2E05),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.person, color: brown),
                          const SizedBox(width: 12),
                          Text(
                            userProvider.name.isNotEmpty ? userProvider.name : 'Name',
                            style: TextStyle(fontSize: 16, color: coffeeBrown, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.wc, color: brown),
                          const SizedBox(width: 12),
                          Text(
                            userProvider.gender.isNotEmpty ? userProvider.gender : 'Gender',
                            style: TextStyle(fontSize: 16, color: coffeeBrown, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.contact_mail, color: brown),
                          const SizedBox(width: 12),
                          Text(
                            userProvider.contact.isNotEmpty ? userProvider.contact : 'Contact',
                            style: TextStyle(fontSize: 16, color: coffeeBrown, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.home_work, color: brown),
                          const SizedBox(width: 12),
                          Text(
                            userProvider.hostelManaged.isNotEmpty
                                ? userProvider.hostelManaged
                                : 'Hostel Managed',
                            style: TextStyle(fontSize: 16, color: coffeeBrown, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
