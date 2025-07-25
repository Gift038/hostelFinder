import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class PublishAddScreen extends StatefulWidget {
  const PublishAddScreen({super.key});

  @override
  _PublishAddScreenState createState() => _PublishAddScreenState();
}

class _PublishAddScreenState extends State<PublishAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedHostelId;
  String? _selectedRoomId;
  Stream<QuerySnapshot>? _hostelsStream;
  Stream<QuerySnapshot>? _roomsStream;
  bool _isLoading = false;
  List<XFile> _imageFiles = [];
  String? _selectedCategory;
  int _selectedDuration = 7;

  final List<String> _categories = [
    'Single Room',
    'Double Room',
    'Furnished',
    'Self-contained',
    'Shared',
    'Other',
  ];
  final List<int> _durations = [7, 14, 30];

  @override
  void initState() {
    super.initState();
    _hostelsStream = _fetchManagerHostels();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _fetchManagerHostels() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('hostels')
        .where('managerId', isEqualTo: user.uid)
        .snapshots();
  }

  void _onHostelSelected(String? hostelId) {
    setState(() {
      _selectedHostelId = hostelId;
      _selectedRoomId = null;
      _titleController.clear();
      _descController.clear();
      if (hostelId != null) {
        _roomsStream = _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection('rooms')
            .where('isOccupied', isEqualTo: false)
            .snapshots();
      } else {
        _roomsStream = null;
      }
    });
  }

  void _onRoomSelected(String? roomId, QueryDocumentSnapshot roomDoc) {
    setState(() {
      _selectedRoomId = roomId;
      if (roomId != null) {
        final data = roomDoc.data() as Map<String, dynamic>;
        _titleController.text = 'Room Available at ${data['hostelName'] ?? ''}';
        _descController.text =
            'A lovely ${data['roomType'] ?? ''} room, number ${data['roomNumber'] ?? ''}, is now available for UGX ${data['price'] ?? ''}.';
      } else {
        _titleController.clear();
        _descController.clear();
      }
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _imageFiles = picked);
    }
  }

  Future<List<String>> _uploadImagesToStorage(List<XFile> images) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    List<String> urls = [];
    for (final image in images) {
      final ref = FirebaseStorage.instance.ref().child(
        'ad_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${image.name}',
      );
      final uploadTask = await ref.putFile(File(image.path));
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _showPreviewDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Ad'),
        content: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_imageFiles.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _imageFiles
                          .map(
                            (img) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(img.path), height: 120),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _titleController.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_descController.text),
                const SizedBox(height: 8),
                if (_selectedCategory != null)
                  Chip(label: Text(_selectedCategory!)),
                const SizedBox(height: 8),
                Text('Duration: $_selectedDuration days'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmAndPublishAd();
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndPublishAd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Publish'),
        content: const Text('Are you sure you want to publish this ad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _publishAd();
    }
  }

  Future<void> _publishAd() async {
    if (!_formKey.currentState!.validate() ||
        _selectedHostelId == null ||
        _selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a hostel and room, and fill out all fields.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      List<String> imageUrls = [];
      if (_imageFiles.isNotEmpty) {
        imageUrls = await _uploadImagesToStorage(_imageFiles);
      }
      final expiry = DateTime.now().add(Duration(days: _selectedDuration));
      await _firestore.collection('published_ads').add({
        'title': _titleController.text,
        'description': _descController.text,
        'hostelId': _selectedHostelId,
        'roomId': _selectedRoomId,
        'managerId': _auth.currentUser?.uid,
        'publishedAt': FieldValue.serverTimestamp(),
        'imageUrls': imageUrls,
        'category': _selectedCategory,
        'expiry': expiry,
        'duration': _selectedDuration,
      });
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text('Advertisement published successfully!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish ad: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish Ad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ad Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  StreamBuilder<QuerySnapshot>(
                    stream: _hostelsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            Text(
                              'Failed to load hostels: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: Text('Retry'),
                            ),
                          ],
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedHostelId,
                        onChanged: _onHostelSelected,
                        hint: const Text('Select Hostel'),
                        items: snapshot.data!.docs
                            .map(
                              (doc) => DropdownMenuItem(
                                value: doc.id,
                                child: Text(doc['name']),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  if (_selectedHostelId != null) const SizedBox(height: 16),
                  if (_selectedHostelId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: _roomsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              Text(
                                'Failed to load rooms: ${snapshot.error}',
                                style: TextStyle(color: Colors.red),
                              ),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: Text('Retry'),
                              ),
                            ],
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.data!.docs.isEmpty) {
                          return const Text(
                            'No vacant rooms available in this hostel.',
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedRoomId,
                          onChanged: (value) => _onRoomSelected(
                            value,
                            snapshot.data!.docs.firstWhere(
                              (doc) => doc.id == value,
                            ),
                          ),
                          hint: const Text('Select Vacant Room'),
                          items: snapshot.data!.docs
                              .map(
                                (doc) => DropdownMenuItem(
                                  value: doc.id,
                                  child: Text('Room ${doc['roomNumber']}'),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    hint: const Text('Select Category'),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedDuration,
                    onChanged: (val) =>
                        setState(() => _selectedDuration = val ?? 7),
                    hint: const Text('Ad Duration'),
                    items: _durations
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d days'),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Ad Title',
                      prefixIcon: Icon(Icons.title),
                      helperText: 'E.g. Spacious Room Available',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Ad Description',
                      prefixIcon: Icon(Icons.description),
                      helperText: 'Describe the room and its features',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 4,
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add_a_photo),
                    label: Text('Add Images'),
                    onPressed: _pickImages,
                  ),
                  if (_imageFiles.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _imageFiles
                            .map(
                              (img) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(img.path),
                                    height: 100,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: _imageFiles.isNotEmpty
                          ? Image.file(
                              File(_imageFiles.first.path),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.image, size: 48),
                      title: Text(
                        _titleController.text.isEmpty
                            ? 'Ad Title'
                            : _titleController.text,
                      ),
                      subtitle: Text(
                        _descController.text.isEmpty
                            ? 'Ad Description'
                            : _descController.text,
                      ),
                      trailing: _selectedCategory != null
                          ? Chip(label: Text(_selectedCategory!))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ||
                                        _selectedHostelId == null ||
                                        _selectedRoomId == null ||
                                        _titleController.text.trim().isEmpty ||
                                        _descController.text.trim().isEmpty
                                    ? null
                                    : _showPreviewDialog,
                                child: const Text('Preview & Publish'),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
