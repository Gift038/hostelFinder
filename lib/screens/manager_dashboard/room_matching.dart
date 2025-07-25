import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomMatchingScreen extends StatefulWidget {
  const RoomMatchingScreen({super.key});

  @override
  _RoomMatchingScreenState createState() => _RoomMatchingScreenState();
}

class _RoomMatchingScreenState extends State<RoomMatchingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _unassignedTenants = [];
  DocumentSnapshot? _tenant1;
  DocumentSnapshot? _tenant2;
  List<String> _sharedInterests = [];

  @override
  void initState() {
    super.initState();
    _fetchUnassignedTenants();
  }

  Future<void> _fetchUnassignedTenants() async {
    // This is a simplified query. In a real app, you might need a more
    // efficient way to find unassigned tenants.
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'tenant')
        .where('assignedRoom', isNull: true)
        .get();
    setState(() {
      _unassignedTenants = snapshot.docs;
    });
  }

  void _compareTenants() {
    if (_tenant1 == null || _tenant2 == null) {
      setState(() {
        _sharedInterests = [];
      });
      return;
    }

    final data1 = _tenant1!.data() as Map<String, dynamic>;
    final data2 = _tenant2!.data() as Map<String, dynamic>;

    final interests1 = List<String>.from(data1['interests'] ?? []);
    final interests2 = List<String>.from(data2['interests'] ?? []);

    setState(() {
      _sharedInterests = interests1
          .where((interest) => interests2.contains(interest))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roommate Matching')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tenant Selection
            Row(
              children: [
                Expanded(
                  child: _buildTenantDropdown(
                    1,
                    (val) => setState(() {
                      _tenant1 = val;
                      _compareTenants();
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTenantDropdown(
                    2,
                    (val) => setState(() {
                      _tenant2 = val;
                      _compareTenants();
                    }),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Comparison View
            if (_tenant1 != null && _tenant2 != null)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Shared Interests',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _sharedInterests.isEmpty
                        ? const Text('No shared interests found.')
                        : Wrap(
                            spacing: 8.0,
                            children: _sharedInterests
                                .map((interest) => Chip(label: Text(interest)))
                                .toList(),
                          ),
                    const Divider(height: 32),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildTenantProfile(_tenant1!)),
                          const VerticalDivider(width: 32),
                          Expanded(child: _buildTenantProfile(_tenant2!)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(child: Text('Select two tenants to compare.')),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantDropdown(
    int number,
    ValueChanged<DocumentSnapshot?> onChanged,
  ) {
    return DropdownButtonFormField<DocumentSnapshot>(
      hint: Text('Select Tenant $number'),
      onChanged: onChanged,
      items: _unassignedTenants.map((doc) {
        return DropdownMenuItem(
          value: doc,
          child: Text(
            (doc.data() as Map<String, dynamic>)['fullName'] ?? 'N/A',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTenantProfile(DocumentSnapshot tenant) {
    final data = tenant.data() as Map<String, dynamic>;
    final interests = List<String>.from(data['interests'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['fullName'] ?? 'N/A',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Interests:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8.0,
          children: interests
              .map((interest) => Chip(label: Text(interest)))
              .toList(),
        ),
      ],
    );
  }
}
