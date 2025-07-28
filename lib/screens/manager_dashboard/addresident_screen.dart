import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddResidentScreen extends StatefulWidget {
  const AddResidentScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddResidentScreenState createState() => _AddResidentScreenState();
}

class _AddResidentScreenState extends State<AddResidentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedHostelId;
  String? _selectedRoomId;
  String? _selectedTenantId;

  Map<String, dynamic>? _tenantPaymentStatus;

  // Use ValueNotifier to rebuild the button state
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  bool _isLoading = false;

  Stream<QuerySnapshot>? _hostelsStream;
  Stream<QuerySnapshot>? _roomsStream;
  Stream<QuerySnapshot>? _tenantsStream;

  @override
  void initState() {
    super.initState();
    _hostelsStream = _fetchManagerHostels();
    _tenantsStream = _fetchUnassignedTenants();
  }

  void _validateForm() {
    _isFormValid.value =
        _selectedHostelId != null &&
        _selectedRoomId != null &&
        _selectedTenantId != null;
  }

  Stream<QuerySnapshot> _fetchManagerHostels() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('hostels')
        .where('managerId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot> _fetchUnassignedTenants() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'tenant')
        .snapshots();
  }

  void _onHostelSelected(String? hostelId) {
    setState(() {
      _selectedHostelId = hostelId;
      _selectedRoomId = null; // Reset room selection
      _selectedTenantId = null; // Also reset tenant
      _tenantPaymentStatus = null;
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
      _validateForm();
    });
  }

  Future<void> _fetchTenantPaymentStatus(String tenantId) async {
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (paymentsSnapshot.docs.isNotEmpty) {
      setState(() {
        _tenantPaymentStatus = paymentsSnapshot.docs.first.data();
      });
    } else {
      setState(() {
        _tenantPaymentStatus = null;
      });
    }
  }

  Future<void> _assignResident() async {
    _validateForm();
    if (!_isFormValid.value) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    setState(() => _isLoading = true);
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final batch = _firestore.batch();

      // Update the room's status
      final roomRef = _firestore
          .collection('hostels')
          .doc(_selectedHostelId)
          .collection('rooms')
          .doc(_selectedRoomId);
      batch.update(roomRef, {
        'isOccupied': true,
        'tenantId': _selectedTenantId,
      });

      // Update the user's assigned hostel and room
      final userRef = _firestore.collection('users').doc(_selectedTenantId);
      batch.update(userRef, {
        'assignedHostel': _selectedHostelId,
        'assignedRoom': _selectedRoomId,
      });

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Resident successfully assigned!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // Reset the form
      setState(() {
        _selectedHostelId = null;
        _selectedRoomId = null;
        _selectedTenantId = null;
        _roomsStream = null;
        _isLoading = false;
        _validateForm();
      });
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to assign resident: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Resident to Room')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assignment Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  // Hostel Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: _hostelsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No hostels found. Please add a hostel first.',
                        );
                      }
                      final hostels = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: _selectedHostelId,
                        hint: const Text('Select Hostel'),
                        decoration: const InputDecoration(
                          labelText: 'Hostel',
                          prefixIcon: Icon(Icons.home_work),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _onHostelSelected,
                        items: hostels.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(data['name'] ?? 'Unnamed Hostel'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Room Dropdown
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedHostelId == null
                        ? const SizedBox.shrink()
                        : StreamBuilder<QuerySnapshot>(
                            stream: _roomsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const ListTile(
                                  leading: Icon(
                                    Icons.room_preferences,
                                    color: Colors.grey,
                                  ),
                                  title: Text(
                                    'No vacant rooms available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                              final rooms = snapshot.data!.docs;
                              return DropdownButtonFormField<String>(
                                value: _selectedRoomId,
                                hint: const Text('Select Vacant Room'),
                                decoration: const InputDecoration(
                                  labelText: 'Room',
                                  prefixIcon: Icon(Icons.king_bed),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() => _selectedRoomId = value);
                                  _validateForm();
                                },
                                items: rooms.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text('Room ${data['roomNumber']}'),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Tenant Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: _tenantsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No tenants found.');
                      }
                      final tenants = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        // Client-side filter for unassigned tenants
                        return data['assignedHostel'] == null;
                      }).toList();

                      if (tenants.isEmpty) {
                        return const ListTile(
                          leading: Icon(Icons.person_off, color: Colors.grey),
                          title: Text(
                            'No unassigned tenants available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedTenantId,
                        hint: const Text('Select Tenant'),
                        decoration: const InputDecoration(
                          labelText: 'Tenant',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => _selectedTenantId = value);
                          _validateForm();
                        },
                        items: tenants.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(data['fullName'] ?? 'Unnamed Tenant'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Assign Button
                  ValueListenableBuilder<bool>(
                    valueListenable: _isFormValid,
                    builder: (context, isValid, child) {
                      return FilledButton.icon(
                        onPressed: (isValid && !_isLoading)
                            ? _assignResident
                            : null,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Assign Resident'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    },
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
