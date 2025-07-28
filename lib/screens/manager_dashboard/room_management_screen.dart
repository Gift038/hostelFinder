import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:html' as web;

import '../../l10n/app_localizations.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Currently selected hostel ID
  String? _selectedHostelId;

  // Stream of rooms for the selected hostel
  Stream<QuerySnapshot>? _roomsStream;

  // User role, default to 'manager'
  String _userRole = 'manager';

  // Search query string
  String _search = '';

  // Filter status: 'All', 'Occupied', 'Available'
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  /// Fetches the current user's role from Firestore and updates state.
  Future<void> _fetchUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = doc.data()?['role'] ?? 'manager';
      });
    }
  }

  /// Returns a stream of hostels managed by the current user.
  Stream<QuerySnapshot> _fetchManagerHostels() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('hostels')
        .where('managerId', isEqualTo: user.uid)
        .snapshots();
  }

  /// Handles selection of a hostel, updates the rooms stream accordingly.
  void _onHostelSelected(String hostelId) {
    setState(() {
      _selectedHostelId = hostelId;
      _roomsStream = _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('rooms')
          .snapshots();
      // _selectedRooms.clear(); // Removed because _selectedRooms no longer exists
    });
  }

  /// Shows a dialog to add or edit a room.
  /// Only accessible to users with 'manager' or 'admin' roles.
  void _showAddEditRoomDialog({DocumentSnapshot? roomDoc}) {
    if (!['manager', 'admin'].contains(_userRole)) return;

    final isEdit = roomDoc != null;
    final data = roomDoc?.data() as Map<String, dynamic>? ?? {};

    final numberCtrl = TextEditingController(text: data['roomNumber']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: data['price']?.toString() ?? '');
    final typeCtrl = TextEditingController(text: data['type'] ?? '');
    final tenantCtrl = TextEditingController(text: data['tenant'] ?? '');
    final rawAmenities = data['amenities'];
    final amenities = <String>{};

    if (rawAmenities is List) {
      for (var item in rawAmenities) {
        if (item is String) amenities.add(item);
      }
    }

    XFile? imageFile;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEdit
                ? AppLocalizations.of(context)?.editRoom ?? 'Edit Room'
                : AppLocalizations.of(context)?.addRoom ?? 'Add Room'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numberCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.roomNumber ?? 'Room Number',
                    ),
                  ),
                  TextField(
                    controller: priceCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.price ?? 'Price',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: typeCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.roomType ?? 'Room Type',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Wi‑Fi', 'A/C', 'Gym', 'Pool', 'Study Room', 'Kitchen']
                        .map((amenity) => FilterChip(
                              label: Text(amenity),
                              selected: amenities.contains(amenity),
                              onSelected: (sel) => setStateDialog(() {
                                sel ? amenities.add(amenity) : amenities.remove(amenity);
                              }),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tenantCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.tenant ?? 'Tenant',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text('Select Image'),
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) setStateDialog(() => imageFile = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (imageFile != null)
                    kIsWeb
                        ? Image.network(imageFile!.path, height: 80)
                        : Image.file(File(imageFile!.path), height: 80)
                  else if (data['imageUrl'] != null)
                    Image.network(data['imageUrl'], height: 80),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (_selectedHostelId == null) return;
                    final details = {
                      'roomNumber': numberCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                      'type': typeCtrl.text.trim(),
                      'tenant': tenantCtrl.text.trim(),
                      'amenities': amenities.toList(),
                      'isOccupied': data['isOccupied'] ?? false,
                    };

                    if (imageFile != null && !kIsWeb) {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('room_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile!.name}');
                      await ref.putFile(File(imageFile!.path));
                      final url = await ref.getDownloadURL();
                      details['imageUrl'] = url;
                    }

                    if (isEdit) {
                      await roomDoc.reference.update(details);
                    } else {
                      await _firestore
                          .collection('hostels')
                          .doc(_selectedHostelId)
                          .collection('rooms')
                          .add(details);
                    }

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e')),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Exports the list of rooms as a CSV file. Only supported on Web.
  void _exportRooms(List<QueryDocumentSnapshot> rooms) {
    final sb = StringBuffer();
    sb.writeln('Room Number,Price,Type,Occupied');
    for (var r in rooms) {
      final data = r.data() as Map<String, dynamic>;
      sb.writeln('${data['roomNumber']},${data['price']},${data['type']},${data['isOccupied'] == true ? 'Yes' : 'No'}');
    }
    final csv = sb.toString();

    if (kIsWeb) {
      final bytes = utf8.encode(csv);
      final blob = web.Blob([Uint8List.fromList(bytes)]);
      final url = web.Url.createObjectUrlFromBlob(blob);
      final anchor = web.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = 'rooms.csv';
      web.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      web.Url.revokeObjectUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export only supported on Web for now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.roomManagement ?? 'Room Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_selectedHostelId != null && ['manager', 'admin'].contains(_userRole))
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: loc?.addRoom ?? 'Add Room',
              onPressed: () => _showAddEditRoomDialog(),
            ),
        ],
      ),
      body: isMobile ? _buildMobileLayout(loc) : _buildDesktopLayout(loc),
    );
  }

  Widget _buildMobileLayout(AppLocalizations? loc) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: StreamBuilder<QuerySnapshot>(
            stream: _fetchManagerHostels(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('No hostels'));
              }
              return DropdownButton<String>(
                value: _selectedHostelId,
                hint: const Text('Select Hostel'),
                items: docs
                    .map((h) => DropdownMenuItem(
                          value: h.id,
                          child: Text(h['name'] as String? ?? ''),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onHostelSelected(val);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _search = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterStatus,
                items: ['All', 'Occupied', 'Available']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _filterStatus = val;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildRoomPanel(loc)),
      ],
    );
  }

  Widget _buildDesktopLayout(AppLocalizations? loc) {
    return Row(
      children: [
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _fetchManagerHostels(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('No hostels'));
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (ctx, index) {
                        final h = docs[index];
                        return ListTile(
                          title: Text(h['name'] as String? ?? ''),
                          selected: _selectedHostelId == h.id,
                          onTap: () => _onHostelSelected(h.id),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search',
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _search = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterStatus,
                          items: ['All', 'Occupied', 'Available']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterStatus = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(child: _buildRoomPanel(loc)),
      ],
    );
  }

  Widget _buildRoomPanel(AppLocalizations? loc) {
    if (_roomsStream == null) {
      return Center(child: Text(loc?.selectHostelToViewRooms ?? 'Select a hostel to view rooms'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _roomsStream!,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
                return Center(child: Text('No rooms found'));
        }

        var filtered = docs;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          filtered = docs.where((r) {
            final data = r.data() as Map<String, dynamic>;
            return (data['roomNumber']?.toString().toLowerCase().contains(q) ?? false) ||
                   (data['type']?.toString().toLowerCase().contains(q) ?? false);
          }).toList();
        }

        if (_filterStatus != 'All') {
          final occupied = _filterStatus == 'Occupied';
          filtered = filtered.where((r) => (r.data() as Map<String, dynamic>)['isOccupied'] == occupied).toList();
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (ctx, idx) {
            final room = filtered[idx];
            final data = room.data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Room ${data['roomNumber']}'),
              subtitle: Text('${loc?.price ?? 'Price'}: ${data['price'] ?? 'N/A'}'),
              trailing: Icon(data['isOccupied'] == true ? Icons.close : Icons.check),
              onTap: () => _showAddEditRoomDialog(roomDoc: room),
            );
          },
        );
      },
    );
  }
}
