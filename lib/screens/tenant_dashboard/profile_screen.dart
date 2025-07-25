import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<DocumentSnapshot> _userFuture;
  bool get _isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      _userFuture = Future.error('No user ID found');
    } else {
      _userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMyProfile ? 'My Profile' : 'Tenant Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _ProfileHeader(
                userData: userData,
                isMyProfile: _isMyProfile,
                onProfileUpdate: () => setState(() {
                  _userFuture = FirebaseFirestore.instance
                      .collection('users')
                      .doc(
                        widget.userId ?? FirebaseAuth.instance.currentUser!.uid,
                      )
                      .get();
                }),
              ),
              const SizedBox(height: 24),
              _BioCard(userData: userData, isMyProfile: _isMyProfile),
              if (!_isMyProfile) ...[
                const SizedBox(height: 24),
                _PaymentHistoryCard(userId: widget.userId!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isMyProfile;
  final VoidCallback onProfileUpdate;

  const _ProfileHeader({
    required this.userData,
    required this.isMyProfile,
    required this.onProfileUpdate,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    if (!widget.isMyProfile) return;

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _isUploading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref().child('user_avatars/$userId');
      final uploadTask = await ref.putFile(_imageFile!);
      final avatarUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'avatarUrl': avatarUrl,
      });

      widget.onProfileUpdate(); // Refresh the profile
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.userData['avatarUrl'] as String?;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (avatarUrl != null ? NetworkImage(avatarUrl) : null)
                          as ImageProvider?,
                child: (_imageFile == null && avatarUrl == null)
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            if (widget.isMyProfile)
              Positioned(
                bottom: 0,
                right: 0,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        onPressed: _pickAndUploadImage,
                      ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.userData['fullName'] ?? 'Your Name',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          widget.userData['email'] ?? 'your.email@example.com',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _BioCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isMyProfile;

  const _BioCard({required this.userData, required this.isMyProfile});

  @override
  State<_BioCard> createState() => _BioCardState();
}

class _BioCardState extends State<_BioCard> {
  bool _isEditing = false;

  late final TextEditingController nameController;
  late final TextEditingController genderController;
  late final TextEditingController schoolController;
  late final TextEditingController programmeController;
  late final TextEditingController yearOfStudyController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['fullName']);
    genderController = TextEditingController(text: widget.userData['gender']);
    schoolController = TextEditingController(text: widget.userData['school']);
    programmeController = TextEditingController(
      text: widget.userData['programme'],
    );
    yearOfStudyController = TextEditingController(
      text: widget.userData['yearOfStudy'],
    );
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

  void _saveBioData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fullName': nameController.text,
      'gender': genderController.text,
      'school': schoolController.text,
      'programme': programmeController.text,
      'yearOfStudy': yearOfStudyController.text,
    });
    // Update local provider state as well
    Provider.of<UserProvider>(context, listen: false).setUser(
      name: nameController.text,
      contact: widget.userData['contact'] ?? '',
      gender: genderController.text,
      email: widget.userData['email'] ?? '',
      school: schoolController.text,
      programme: programmeController.text,
      yearOfStudy: yearOfStudyController.text,
    );

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bio Data', style: Theme.of(context).textTheme.titleLarge),
                if (widget.isMyProfile)
                  IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _buildBioField(
              controller: nameController,
              label: 'Name',
              enabled: _isEditing,
            ),
            _buildBioField(
              controller: genderController,
              label: 'Gender',
              enabled: _isEditing,
            ),
            _buildBioField(
              controller: schoolController,
              label: 'School',
              enabled: _isEditing,
            ),
            _buildBioField(
              controller: programmeController,
              label: 'Programme',
              enabled: _isEditing,
            ),
            _buildBioField(
              controller: yearOfStudyController,
              label: 'Year of Study',
              enabled: _isEditing,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveBioData,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBioField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final String userId;
  const _PaymentHistoryCard({required this.userId});

  Future<List<Map<String, dynamic>>> _fetchPayments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('payments')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No payment history.'));
                }
                final payments = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    final date = (p['date'] as Timestamp).toDate();
                    final status = p['status'] ?? 'N/A';
                    return ListTile(
                      leading: Icon(
                        status == 'Success'
                            ? Icons.check_circle
                            : Icons.hourglass_top,
                        color: status == 'Success'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        'UGX ${NumberFormat('#,###').format(p['amount'] ?? 0)}',
                      ),
                      subtitle: Text(
                        'Paid on ${DateFormat.yMMMd().format(date)}',
                      ),
                      trailing: Text(status),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
