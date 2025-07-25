import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddHostelScreen extends StatefulWidget {
  const AddHostelScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddHostelScreenState createState() => _AddHostelScreenState();
}

class _AddHostelScreenState extends State<AddHostelScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1: Hostel Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Step 2: Amenities
  final TextEditingController _amenityInputController = TextEditingController();
  List<String> _amenities = [];

  // Step 3: Rooms
  List<Map<String, dynamic>> _rooms = [];

  // Step 4: Images
  final List<XFile> _images = [];

  bool _isLoading = false;
  LatLng? _pickedLatLng;

  @override
  void initState() {
    super.initState();
    _restoreDraftIfAvailable();
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = jsonEncode({
      'name': _nameController.text,
      'location': _locationController.text,
      'price': _priceController.text,
      'description': _descriptionController.text,
      'amenities': _amenities,
      'rooms': _rooms,
      // Note: images are not saved in draft for simplicity
    });
    await prefs.setString('hostel_draft', draft);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved!')));
    }
  }

  Future<void> _restoreDraftIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('hostel_draft');
    if (draft != null) {
      final data = jsonDecode(draft);
      setState(() {
        _nameController.text = data['name'] ?? '';
        _locationController.text = data['location'] ?? '';
        _priceController.text = data['price'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _amenities = List<String>.from(data['amenities'] ?? []);
        _rooms = List<Map<String, dynamic>>.from(data['rooms'] ?? []);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Draft restored!'),
            action: SnackBarAction(
              label: 'Clear',
              onPressed: () async {
                await prefs.remove('hostel_draft');
                setState(() {
                  _nameController.clear();
                  _locationController.clear();
                  _priceController.clear();
                  _descriptionController.clear();
                  _amenities.clear();
                  _rooms.clear();
                });
              },
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _amenityInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> selectedImages = await picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      // Compress images before adding
      final List<XFile> compressedImages = [];
      for (final xfile in selectedImages) {
        final file = File(xfile.path);
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final compressed = img.encodeJpg(decoded, quality: 70);
          final tempPath =
              '${file.parent.path}/compressed_${file.uri.pathSegments.last}';
          final compressedFile = await File(tempPath).writeAsBytes(compressed);
          compressedImages.add(XFile(compressedFile.path));
        } else {
          compressedImages.add(xfile); // fallback
        }
      }
      setState(() {
        _images.addAll(compressedImages);
      });
    }
  }

  Future<List<String>> _uploadImages(String hostelId) async {
    List<String> downloadUrls = [];
    for (var image in _images) {
      final ref = FirebaseStorage.instance.ref().child(
        'hostel_images/$hostelId/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
      );
      final uploadTask = await ref.putFile(File(image.path));
      final url = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  Future<List<String?>> _uploadRoomImages(String hostelId) async {
    List<String?> roomImageUrls = [];
    for (int i = 0; i < _rooms.length; i++) {
      final roomImage = _rooms[i]['roomImage'] as XFile?;
      if (roomImage != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'hostel_images/$hostelId/room_${_rooms[i]['roomNumber']}_${DateTime.now().millisecondsSinceEpoch}_${roomImage.name}',
        );
        final uploadTask = await ref.putFile(File(roomImage.path));
        final url = await uploadTask.ref.getDownloadURL();
        roomImageUrls.add(url);
      } else {
        roomImageUrls.add(null);
      }
    }
    return roomImageUrls;
  }

  Future<void> _submit() async {
    if (!_validateAllSteps()) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(
        _locationController.text.trim(),
      );
      final coordinates = locations.first;
      final managerId = FirebaseAuth.instance.currentUser?.uid;
      final docRef = FirebaseFirestore.instance.collection('hostels').doc();
      final hostelId = docRef.id;
      final imageUrls = await _uploadImages(hostelId);
      final roomImageUrls = await _uploadRoomImages(hostelId);

      await docRef.set({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'amenities': _amenities,
        'managerId': managerId,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'coordinates': {
          'lat': coordinates.latitude,
          'lng': coordinates.longitude,
        },
        'totalRooms': _rooms.length,
        'occupiedRooms': 0,
      });

      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < _rooms.length; i++) {
        final roomData = _rooms[i];
        final roomRef = docRef.collection('rooms').doc();
        batch.set(roomRef, {
          'roomNumber': roomData['roomNumber'],
          'type': roomData['type'],
          'price': roomData['price'],
          'isOccupied': false,
          'tenantId': null,
          'imageUrl': roomImageUrls[i],
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop(); // Remove loading overlay
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text('Hostel and rooms uploaded successfully!'),
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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading overlay
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddRoomDialog({Map<String, dynamic>? roomToEdit, int? editIndex}) {
    final roomNumberController = TextEditingController(
      text: roomToEdit?['roomNumber'] ?? '',
    );
    final roomPriceController = TextEditingController(
      text: roomToEdit?['price']?.toString() ?? '',
    );
    String selectedRoomType = roomToEdit?['type'] ?? 'Single Room';
    XFile? pickedRoomImage = roomToEdit?['roomImage'] as XFile?;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(roomToEdit == null ? 'Add Room' : 'Edit Room'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: roomNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Room Number',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final isDuplicate = _rooms.asMap().entries.any(
                          (entry) =>
                              entry.value['roomNumber'] == v &&
                              (editIndex == null || entry.key != editIndex),
                        );
                        if (isDuplicate) return 'Duplicate room number';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: roomPriceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRoomType,
                      items: ['Single Room', 'Double Room'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          selectedRoomType = newValue!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Room Type'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        pickedRoomImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(pickedRoomImage!.path),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Text('No image'),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Pick Image'),
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              // Compress the picked image
                              final file = File(picked.path);
                              final bytes = await file.readAsBytes();
                              final decoded = img.decodeImage(bytes);
                              if (decoded != null) {
                                final compressed = img.encodeJpg(
                                  decoded,
                                  quality: 70,
                                );
                                final tempPath =
                                    '${file.parent.path}/compressed_room_${file.uri.pathSegments.last}';
                                final compressedFile = await File(
                                  tempPath,
                                ).writeAsBytes(compressed);
                                setDialogState(() {
                                  pickedRoomImage = XFile(compressedFile.path);
                                });
                              } else {
                                setDialogState(() {
                                  pickedRoomImage = picked;
                                });
                              }
                            }
                          },
                        ),
                        if (pickedRoomImage != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setDialogState(() => pickedRoomImage = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final newRoom = {
                      'roomNumber': roomNumberController.text,
                      'price': double.tryParse(roomPriceController.text) ?? 0,
                      'type': selectedRoomType,
                      'roomImage': pickedRoomImage,
                    };
                    setState(() {
                      if (editIndex != null) {
                        _rooms[editIndex] = newRoom;
                      } else {
                        _rooms.add(newRoom);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Uploading Hostel...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Submitting, please wait...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Hostel',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          final isLastStep = _currentStep == getSteps().length - 1;
          if (isLastStep) {
            _submit();
          } else {
            // Add validation for the current step before proceeding
            if (_validateStep(_currentStep)) {
              setState(() => _currentStep += 1);
            }
          }
        },
        onStepCancel: _currentStep == 0
            ? null
            : () => setState(() => _currentStep -= 1),
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: getSteps(),
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == getSteps().length - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLastStep ? 'SUBMIT' : 'NEXT'),
                ),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('BACK'),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save as Draft'),
                  onPressed: _saveDraft,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Step> getSteps() => [
    Step(
      title: const Text('Hostel Info'),
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Hostel Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Pick on Map'),
                  onPressed: () async {
                    final result = await showDialog<LatLng>(
                      context: context,
                      builder: (context) =>
                          _MapPickerDialog(initialLatLng: _pickedLatLng),
                    );
                    if (result != null) {
                      _pickedLatLng = result;
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                            result.latitude,
                            result.longitude,
                          );
                      if (placemarks.isNotEmpty) {
                        final place = placemarks.first;
                        final address = [
                          place.street,
                          place.locality,
                          place.country,
                        ].where((e) => e != null && e.isNotEmpty).join(', ');
                        setState(() {
                          _locationController.text = address;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 && !_validateStep(0)
          ? StepState.error
          : StepState.indexed,
    ),
    Step(
      title: const Text('Amenities'),
      content: _buildAmenitiesSection(),
      isActive: _currentStep >= 1,
    ),
    Step(
      title: const Text('Rooms'),
      content: _buildRoomsSection(),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 && _rooms.isEmpty
          ? StepState.error
          : StepState.indexed,
    ),
    Step(
      title: const Text('Images'),
      content: _buildImagesSection(),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 && _images.isEmpty
          ? StepState.error
          : StepState.indexed,
    ),
    Step(
      title: const Text('Review'),
      content: _buildReviewSection(),
      isActive: _currentStep >= 4,
    ),
  ];

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          children: _amenities
              .map(
                (amenity) => Chip(
                  label: Text(amenity),
                  onDeleted: () => setState(() => _amenities.remove(amenity)),
                ),
              )
              .toList(),
        ),
        TextFormField(
          controller: _amenityInputController,
          decoration: InputDecoration(
            labelText: 'Add Amenity',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_amenityInputController.text.isNotEmpty) {
                  setState(() {
                    _amenities.add(_amenityInputController.text.trim());
                    _amenityInputController.clear();
                  });
                }
              },
            ),
          ),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _amenities.add(value.trim());
                _amenityInputController.clear();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildRoomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_rooms.isEmpty)
          const Text('No rooms added yet. Please add at least one room.'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rooms.length,
          itemBuilder: (context, index) {
            final room = _rooms[index];
            return Card(
              child: ListTile(
                title: Text('Room ${room['roomNumber']} (${room['type']})'),
                subtitle: Text('Price: ${room['price']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddRoomDialog(
                        roomToEdit: room,
                        editIndex: index,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _rooms.removeAt(index)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Room'),
            onPressed: () => _showAddRoomDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _images.isNotEmpty
            ? SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_images[i].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: IconButton(
                            icon: const CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 12,
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            onPressed: () =>
                                setState(() => _images.removeAt(i)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const Text('No images selected.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Pick Images'),
          onPressed: _pickImages,
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewRow('Hostel Name:', _nameController.text),
        _buildReviewRow('Location:', _locationController.text),
        _buildReviewRow('Price:', _priceController.text),
        _buildReviewRow('Amenities:', _amenities.join(', ')),
        _buildReviewRow('Rooms:', '${_rooms.length} configured'),
        _buildReviewRow('Images:', '${_images.length} selected'),
        const SizedBox(height: 16),
        const Text(
          'Click SUBMIT to upload your hostel. This may take a moment.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    ),
  );

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  bool _validateAllSteps() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return false;
    }
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one room.')),
      );
      setState(() => _currentStep = 2);
      return false;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
      setState(() => _currentStep = 3);
      return false;
    }
    return true;
  }
}

class _MapPickerDialog extends StatefulWidget {
  final LatLng? initialLatLng;
  const _MapPickerDialog({this.initialLatLng});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked =
        widget.initialLatLng ??
        const LatLng(0.3476, 32.5825); // Default to Kampala
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick Hostel Location'),
      content: SizedBox(
        width: 350,
        height: 350,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _picked!, zoom: 14),
          onTap: (latLng) => setState(() => _picked = latLng),
          markers: _picked != null
              ? {Marker(markerId: const MarkerId('picked'), position: _picked!)}
              : {},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _picked),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
