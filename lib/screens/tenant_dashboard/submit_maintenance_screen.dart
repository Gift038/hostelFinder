import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class SubmitMaintenanceScreen extends StatefulWidget {
  const SubmitMaintenanceScreen({super.key});

  @override
  _SubmitMaintenanceScreenState createState() =>
      _SubmitMaintenanceScreenState();
}

class _SubmitMaintenanceScreenState extends State<SubmitMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedIssueType;
  XFile? _image;
  bool _isLoading = false;

  final List<String> _issueTypes = [
    'Plumbing',
    'Electrical',
    'Furniture',
    'Internet',
    'Other',
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? selectedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
      });
    }
  }

  Future<String?> _uploadImage(String requestId) async {
    if (_image == null) return null;
    final ref = FirebaseStorage.instance.ref().child(
      'maintenance_requests/$requestId/${_image!.name}',
    );
    final uploadTask = await ref.putFile(File(_image!.path));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in.');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      final hostelId = userData['assignedHostel'];
      final roomId = userData['assignedRoom'];
      final roomDoc = await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('rooms')
          .doc(roomId)
          .get();
      final roomData = roomDoc.data() as Map<String, dynamic>;

      final docRef = _firestore.collection('maintenance_requests').doc();
      final imageUrl = await _uploadImage(docRef.id);

      await docRef.set({
        'tenantId': user.uid,
        'tenantName': userData['fullName'],
        'hostelId': hostelId,
        'roomId': roomId,
        'roomNumber': roomData['roomNumber'],
        'managerId':
            (await _firestore.collection('hostels').doc(hostelId).get())
                .data()!['managerId'],
        'issueType': _selectedIssueType,
        'description': _descriptionController.text,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance request submitted.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Maintenance Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                hint: const Text('Select Issue Type'),
                items: _issueTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedIssueType = value),
                validator: (value) =>
                    value == null ? 'Please select an issue type.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description of Issue',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Please provide a description.' : null,
              ),
              const SizedBox(height: 16),
              _image == null
                  ? TextButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Add Photo'),
                      onPressed: _pickImage,
                    )
                  : Image.file(File(_image!.path), height: 150),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      child: const Text('Submit Request'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
