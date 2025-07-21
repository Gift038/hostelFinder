import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddHostelScreen extends StatefulWidget {
  const AddHostelScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddHostelScreenState createState() => _AddHostelScreenState();
}

class _AddHostelScreenState extends State<AddHostelScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amenitiesController = TextEditingController();
  List<XFile>? _images = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null && selectedImages.isNotEmpty) {
      setState(() {
        _images = selectedImages;
      });
    }
  }

  Future<List<String>> _uploadImages(String hostelId) async {
    List<String> downloadUrls = [];
    for (var image in _images!) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('hostel_images/$hostelId/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      final uploadTask = await ref.putFile(File(image.path));
      final url = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _images == null || _images!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select images.')),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final managerId = FirebaseAuth.instance.currentUser?.uid;
      final docRef = FirebaseFirestore.instance.collection('hostels').doc();
      final hostelId = docRef.id;
      final imageUrls = await _uploadImages(hostelId);
      await docRef.set({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'amenities': _amenitiesController.text.trim(),
        'managerId': managerId,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hostel uploaded successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error:  ${e.toString()}')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Hostel')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Hostel Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _amenitiesController,
                decoration: InputDecoration(labelText: 'Amenities (comma separated)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              Text('Hostel Images'),
              SizedBox(height: 8),
              _images != null && _images!.isNotEmpty
                  ? SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images!.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.file(File(_images![i].path), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                    )
                  : Text('No images selected.'),
              TextButton.icon(
                icon: Icon(Icons.add_a_photo),
                label: Text('Pick Images'),
                onPressed: _pickImages,
              ),
              SizedBox(height: 24),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text('Submit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 