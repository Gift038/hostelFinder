import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert'; // for utf8
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  RoomManagementScreenState createState() => RoomManagementScreenState();
}

class RoomManagementScreenState extends State<RoomManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedHostelId;
  Stream<QuerySnapshot>? _roomsStream;
  String _search = '';
  String _filterStatus = 'All';
  final Set<String> _selectedRooms = {};
  bool _isMobile = false;
  String _userRole = 'manager'; // default, will fetch from Firestore

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = doc.data()?['role'] ?? 'manager';
      });
    }
  }

  Stream<QuerySnapshot> _fetchManagerHostels() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('hostels')
        .where('managerId', isEqualTo: user.uid)
        .snapshots();
  }

  void _onHostelSelected(String hostelId) {
    setState(() {
      _selectedHostelId = hostelId;
      _roomsStream = _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('rooms')
          .snapshots();
      _selectedRooms.clear();
    });
  }

  void _showAddEditRoomDialog({DocumentSnapshot? roomDoc}) {
    if (_userRole != 'manager' && _userRole != 'admin') return;
    final isEdit = roomDoc != null;
    final roomData = isEdit ? roomDoc.data() as Map<String, dynamic> : {};
    final numberController = TextEditingController(
      text: roomData['roomNumber']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: roomData['price']?.toString() ?? '',
    );
    final typeController = TextEditingController(text: roomData['type'] ?? '');
    final amenities = <String>{...(roomData['amenities'] ?? [])};
    final tenantController = TextEditingController(
      text: roomData['tenant'] ?? '',
    );
    XFile? imageFile;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEdit
                ? AppLocalizations.of(context)!.editRoom
                : AppLocalizations.of(context)!.addRoom,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.roomNumber,
                  ),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.price,
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: typeController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.roomType,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      ['Wi-Fi', 'A/C', 'Gym', 'Pool', 'Study Room', 'Kitchen']
                          .map(
                            (a) => FilterChip(
                              label: Text(a),
                              selected: amenities.contains(a),
                              onSelected: (v) => setDialogState(
                                () =>
                                    v ? amenities.add(a) : amenities.remove(a),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tenantController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.tenantOptional,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(AppLocalizations.of(context)!.pickImage),
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setDialogState(() => imageFile = picked);
                    }
                  },
                ),
                if (imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.file(File(imageFile!.path), height: 80),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                String? imageUrl;
                if (imageFile != null) {
                  final user = _auth.currentUser;
                  if (user != null && _selectedHostelId != null) {
                    final ref = FirebaseStorage.instance.ref().child(
                      'room_images/${_selectedHostelId}_${numberController.text}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    );
                    final uploadTask = await ref.putFile(File(imageFile!.path));
                    imageUrl = await uploadTask.ref.getDownloadURL();
                  }
                }
                final data = {
                  'roomNumber': numberController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'type': typeController.text,
                  'isOccupied': roomData['isOccupied'] ?? false,
                  'amenities': amenities.toList(),
                  'tenant': tenantController.text,
                  if (imageUrl != null) 'imageUrl': imageUrl,
                };
                try {
                  if (isEdit) {
                    await roomDoc.reference.update(data);
                    await FirebaseAnalytics.instance.logEvent(
                      name: 'edit_room',
                      parameters: {'roomId': roomDoc.id},
                    );
                  } else {
                    await _firestore
                        .collection('hostels')
                        .doc(_selectedHostelId)
                        .collection('rooms')
                        .add(data);
                    await FirebaseAnalytics.instance.logEvent(name: 'add_room');
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? AppLocalizations.of(context)!.roomUpdated
                            : AppLocalizations.of(context)!.roomAdded,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${AppLocalizations.of(context)!.error}: $e',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                isEdit
                    ? AppLocalizations.of(context)!.save
                    : AppLocalizations.of(context)!.add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRoom(DocumentSnapshot roomDoc) async {
    if (_userRole != 'manager' && _userRole != 'admin') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteRoom),
        content: Text(AppLocalizations.of(context)!.deleteRoomConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await roomDoc.reference.delete();
        final deletedRoom = roomDoc.data();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.roomDeleted),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.undo,
              onPressed: () async {
                await _firestore
                    .collection('hostels')
                    .doc(_selectedHostelId)
                    .collection('rooms')
                    .add(deletedRoom as Map<String, dynamic>);
              },
            ),
          ),
        );
        await FirebaseAnalytics.instance.logEvent(
          name: 'delete_room',
          parameters: {'roomId': roomDoc.id},
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  void _toggleRoomStatus(DocumentSnapshot roomDoc, bool isOccupied) async {
    if (_userRole != 'manager' && _userRole != 'admin') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isOccupied
              ? AppLocalizations.of(context)!.markAsVacant
              : AppLocalizations.of(context)!.markAsOccupied,
        ),
        content: Text(
          AppLocalizations.of(context)!.markRoomConfirm(
            isOccupied
                ? AppLocalizations.of(context)!.vacant
                : AppLocalizations.of(context)!.occupied,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await roomDoc.reference.update({'isOccupied': !isOccupied});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.roomMarkedAs(
                isOccupied
                    ? AppLocalizations.of(context)!.vacant
                    : AppLocalizations.of(context)!.occupied,
              ),
            ),
          ),
        );
        await FirebaseAnalytics.instance.logEvent(
          name: 'toggle_room_status',
          parameters: {'roomId': roomDoc.id, 'isOccupied': !isOccupied},
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  void _exportRooms(List<QueryDocumentSnapshot> rooms) async {
    final csv = StringBuffer();
    csv.writeln('Room Number,Price,Type,Occupied');
    for (final room in rooms) {
      final d = room.data() as Map<String, dynamic>;
      csv.writeln(
        '${d['roomNumber']},${d['price']},${d['type']},${d['isOccupied'] ? 'Yes' : 'No'}',
      );
    }
    final csvString = csv.toString();
    if (kIsWeb) {
      // Web: download using AnchorElement
      final bytes = utf8.encode(csvString);
      final blob = web.Blob([bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'rooms.csv';
      web.document.body!.appendChild(anchor);
      anchor.click();
      web.document.body!.removeChild(anchor);
      web.URL.revokeObjectURL(url);
    } else {
      // Mobile: save to file and share (scaffold)
      // Use path_provider and share packages
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/rooms.csv');
      // await file.writeAsString(csvString);
      // await Share.shareFiles([file.path], text: 'Room list');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.exportedCsv)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.roomManagement),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_selectedHostelId != null)
            if (_userRole == 'manager' || _userRole == 'admin')
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: AppLocalizations.of(context)!.addRoom,
                onPressed: () => _showAddEditRoomDialog(),
              ),
        ],
      ),
      body: _isMobile
          ? Column(
              children: [
                // Hostel Dropdown
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fetchManagerHostels(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No hostels found. Add a hostel from your dashboard.',
                            ),
                          ),
                        );
                      }
                      final hostels = snapshot.data!.docs;
                      return DropdownButton<String>(
                        value: _selectedHostelId,
                        hint: Text(AppLocalizations.of(context)!.selectHostel),
                        items: hostels
                            .map(
                              (h) => DropdownMenuItem(
                                value: h.id,
                                child: Text(h['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          if (id != null) {
                            _onHostelSelected(id);
                          }
                        },
                      );
                    },
                  ),
                ),
                Expanded(child: _buildRoomPanel()),
              ],
            )
          : Row(
              children: [
                // Hostel List Panel
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border(right: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fetchManagerHostels(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No hostels found. Add a hostel from your dashboard.',
                            ),
                          ),
                        );
                      }
                      final hostels = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: hostels.length,
                        itemBuilder: (context, index) {
                          final hostel = hostels[index];
                          return ListTile(
                            title: Text(hostel['name']),
                            selected: _selectedHostelId == hostel.id,
                            onTap: () => _onHostelSelected(hostel.id),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Room Details Panel
                Expanded(child: _buildRoomPanel()),
              ],
            ),
    );
  }

  Widget _buildRoomPanel() {
    return _selectedHostelId == null
        ? Center(
            child: Text(AppLocalizations.of(context)!.selectHostelToViewRooms),
          )
        : StreamBuilder<QuerySnapshot>(
            stream: _roomsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.noRoomsFound,
                  ),
                );
              }
              var rooms = snapshot.data!.docs;
              // Search/filter
              if (_search.isNotEmpty) {
                final lowerCaseSearch = _search.toLowerCase();
                rooms = rooms.where((r) {
                  final d = r.data() as Map<String, dynamic>;
                  return (d['roomNumber']?.toString().toLowerCase() ?? '').contains(lowerCaseSearch) ||
                      (d['type']?.toString().toLowerCase() ?? '').contains(lowerCaseSearch);
                }).toList();
              }
              if (_filterStatus != 'All') {
                rooms = rooms
                    .where(
                      (r) =>
                          (r['isOccupied'] ?? false) ==
                          (_filterStatus == 'Occupied'),
                    )
                    .toList();
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.searchByRoomNumberOrType,
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterStatus,
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(AppLocalizations.of(context)!.all),
                            ),
                            DropdownMenuItem(
                              value: 'Occupied',
                              child: Text(
                                AppLocalizations.of(context)!.occupied,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Vacant',
                              child: Text(AppLocalizations.of(context)!.vacant),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterStatus = v!),
                        ),
                        const SizedBox(width: 8),
                        if (rooms.isNotEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: Text(AppLocalizations.of(context)!.export),
                            onPressed: () => _exportRooms(rooms),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final roomData = room.data() as Map<String, dynamic>;
                        final isOccupied = roomData['isOccupied'] ?? false;
                        final isSelected = _selectedRooms.contains(room.id);
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedRooms.add(room.id);
                                } else {
                                  _selectedRooms.remove(room.id);
                                }
                              }),
                              semanticLabel: isSelected
                                  ? AppLocalizations.of(context)!.deselectRoom
                                  : AppLocalizations.of(context)!.selectRoom,
                            ),
                            title: Text('Room ${roomData['roomNumber'] ?? ''}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.price}: ${roomData['price'] ?? AppLocalizations.of(context)!.na}',
                                ),
                                if (roomData['type'] != null)
                                  Text(
                                    '${AppLocalizations.of(context)!.type}: ${roomData['type']}',
                                  ),
                                if (roomData['amenities'] != null &&
                                    (roomData['amenities'] as List).isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    children: (roomData['amenities'] as List)
                                        .map<Widget>(
                                          (a) => Chip(label: Text(a)),
                                        )
                                        .toList(),
                                  ),
                                if (roomData['tenant'] != null &&
                                    roomData['tenant'].toString().isNotEmpty)
                                  Text(
                                    '${AppLocalizations.of(context)!.tenant}: ${roomData['tenant']}',
                                  ),
                                if (roomData['imageUrl'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Image.network(
                                      roomData['imageUrl'],
                                      height: 40,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.broken_image),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    isOccupied
                                        ? AppLocalizations.of(context)!.occupied
                                        : AppLocalizations.of(context)!.vacant,
                                  ),
                                  backgroundColor: isOccupied
                                      ? Colors.red[100]
                                      : Colors.green[100],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    semanticLabel: AppLocalizations.of(
                                      context,
                                    )!.editRoom,
                                  ),
                                  onPressed: () =>
                                      _showAddEditRoomDialog(roomDoc: room),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    semanticLabel: AppLocalizations.of(
                                      context,
                                    )!.deleteRoom,
                                  ),
                                  onPressed: () => _confirmDeleteRoom(room),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isOccupied
                                        ? Icons.meeting_room
                                        : Icons.check_circle,
                                    semanticLabel: isOccupied
                                        ? AppLocalizations.of(
                                            context,
                                          )!.markAsVacant
                                        : AppLocalizations.of(
                                            context,
                                          )!.markAsOccupied,
                                  ),
                                  onPressed: () =>
                                      _toggleRoomStatus(room, isOccupied),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedRooms.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: Text(
                              AppLocalizations.of(context)!.deleteSelected,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(context)!.deleteRooms,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.deleteSelectedRoomsConfirm,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        AppLocalizations.of(context)!.delete,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                for (final id in _selectedRooms) {
                                  try {
                                    await _firestore
                                        .collection('hostels')
                                        .doc(_selectedHostelId)
                                        .collection('rooms')
                                        .doc(id)
                                        .delete();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${AppLocalizations.of(context)!.errorDeletingRoom}: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                                setState(() => _selectedRooms.clear());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.selectedRoomsDeleted,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: Text(
                              AppLocalizations.of(
                                context,
                              )!.markSelectedAsVacant,
                            ),
                            onPressed: () async {
                              for (final id in _selectedRooms) {
                                try {
                                  await _firestore
                                      .collection('hostels')
                                      .doc(_selectedHostelId)
                                      .collection('rooms')
                                      .doc(id)
                                      .update({'isOccupied': false});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${AppLocalizations.of(context)!.errorUpdatingRoom}: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                              setState(() => _selectedRooms.clear());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.selectedRoomsMarkedAsVacant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
  }
}
