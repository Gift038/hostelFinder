import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

const Color coffeeBrown = Color(0xFF6F4E37); // Coffee brown
const Color lightCoffee = Color(0xFFD7CCC8); // Light coffee brown

class UserProfile {
  final String name;
  final String email;
  final String gender;
  final String contactInfo;
  final String joinedYear;
  final String avatarUrl;
  final List<PaymentHistory> paymentHistory;

  UserProfile({
    required this.name,
    required this.email,
    required this.gender,
    required this.contactInfo,
    required this.joinedYear,
    required this.avatarUrl,
    required this.paymentHistory,
  });
}

class PaymentHistory {
  final String title;
  final String date;
  final String roomType;
  final String amount;

  PaymentHistory({
    required this.title,
    required this.date,
    required this.roomType,
    required this.amount,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController genderController;
  late TextEditingController schoolController;
  late TextEditingController programmeController;
  late TextEditingController yearOfStudyController;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    nameController = TextEditingController(text: userProvider.name);
    genderController = TextEditingController(text: userProvider.gender);
    schoolController = TextEditingController(text: userProvider.school);
    programmeController = TextEditingController(text: userProvider.programme);
    yearOfStudyController = TextEditingController(text: userProvider.yearOfStudy);
  }

  @override
  void dispose() {
    nameController.dispose();
    genderController.dispose();
    schoolController.dispose();
    programmeController.dispose();
    yearOfStudyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveBioData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setUser(
      name: nameController.text,
      contact: userProvider.contact,
      gender: genderController.text,
      email: userProvider.email,
      school: schoolController.text,
      programme: programmeController.text,
      yearOfStudy: yearOfStudyController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!')),
    );
    setState(() {});
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: brown,
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null ? Icon(Icons.person, size: 60, color: white) : null,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: coffeeBrown,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userProvider.name.isNotEmpty ? userProvider.name : 'Your Name',
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
                      _buildBioField(
                        controller: nameController,
                        icon: Icons.person,
                        label: 'Name',
                      ),
                      const SizedBox(height: 14),
                      _buildBioField(
                        controller: genderController,
                        icon: Icons.wc,
                        label: 'Gender',
                      ),
                      const SizedBox(height: 14),
                      _buildBioField(
                        controller: schoolController,
                        icon: Icons.school,
                        label: 'School',
                      ),
                      const SizedBox(height: 14),
                      _buildBioField(
                        controller: programmeController,
                        icon: Icons.menu_book,
                        label: 'Programme of Study',
                      ),
                      const SizedBox(height: 14),
                      _buildBioField(
                        controller: yearOfStudyController,
                        icon: Icons.calendar_today,
                        label: 'Year of Study',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: coffeeBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _saveBioData,
                          child: const Text('Save'),
                        ),
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

  Widget _buildBioField({required TextEditingController controller, required IconData icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: coffeeBrown),
          border: InputBorder.none,
          hintText: label,
        ),
      ),
    );
  }
}
