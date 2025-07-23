import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  String? _profileImageUrl;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _isUploading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_pics/${user.uid}.jpg',
        );
        await ref.putFile(File(picked.path));
        final url = await ref.getDownloadURL();
        setState(() => _profileImageUrl = url);
        // Optionally, save URL to Firestore user doc
      }
      setState(() => _isUploading = false);
    }
  }

  void _showEditProfileDialog(UserProvider userProvider) {
    final nameController = TextEditingController(text: userProvider.name);
    final contactController = TextEditingController(text: userProvider.contact);
    final genderController = TextEditingController(text: userProvider.gender);
    final hostelController = TextEditingController(
      text: userProvider.hostelManaged,
    );
    final bioController = TextEditingController(
      text: userProvider.school,
    ); // Use school as bio for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact'),
              ),
              TextField(
                controller: genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              TextField(
                controller: hostelController,
                decoration: const InputDecoration(labelText: 'Hostel Managed'),
              ),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio/Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              userProvider.setUser(
                name: nameController.text,
                contact: contactController.text,
                gender: genderController.text,
                email: userProvider.email,
                school: bioController.text,
                hostelManaged: hostelController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(userProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Quick Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatCard(label: 'Hostels', value: '3'),
                  _StatCard(label: 'Residents', value: '120'),
                  _StatCard(label: 'Requests', value: '5'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Avatar and name/email
            Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: brown,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(Icons.person, size: 60, color: white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: coffeeBrown,
                          child: _isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userProvider.name.isNotEmpty
                      ? userProvider.name
                      : 'Manager Name',
                  style: const TextStyle(
                    color: Color(0xFF4B2E05),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProvider.email.isNotEmpty ? userProvider.email : 'Email',
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
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
                            userProvider.name.isNotEmpty
                                ? userProvider.name
                                : 'Name',
                            style: TextStyle(
                              fontSize: 16,
                              color: coffeeBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.wc, color: brown),
                          const SizedBox(width: 12),
                          Text(
                            userProvider.gender.isNotEmpty
                                ? userProvider.gender
                                : 'Gender',
                            style: TextStyle(
                              fontSize: 16,
                              color: coffeeBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.contact_mail, color: brown),
                          const SizedBox(width: 12),
                          Text(
                            userProvider.contact.isNotEmpty
                                ? userProvider.contact
                                : 'Contact',
                            style: TextStyle(
                              fontSize: 16,
                              color: coffeeBrown,
                              fontWeight: FontWeight.w600,
                            ),
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
                            style: TextStyle(
                              fontSize: 16,
                              color: coffeeBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: brown),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              userProvider.school.isNotEmpty
                                  ? userProvider.school
                                  : 'Bio/Description',
                              style: TextStyle(
                                fontSize: 16,
                                color: coffeeBrown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Theme toggle and support
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brightness_6, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Dark Mode'),
                      Switch(
                        value: Theme.of(context).brightness == Brightness.dark,
                        onChanged: (val) {
                          // Implement theme toggle logic here
                        },
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Show support dialog or open email
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Social links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.web, color: Colors.blue),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.facebook, color: Colors.blue),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.email, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
