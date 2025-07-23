import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tenant_dashboard/profile_screen.dart'; 

class TenantListingScreen extends StatefulWidget {
  const TenantListingScreen({super.key});

  @override
  _TenantListingScreenState createState() => _TenantListingScreenState();
}

class _TenantListingScreenState extends State<TenantListingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<QueryDocumentSnapshot>> _tenantsFuture;

  @override
  void initState() {
    super.initState();
    _tenantsFuture = _fetchTenants();
  }

  Future<List<QueryDocumentSnapshot>> _fetchTenants() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    final managerHostelsSnapshot = await _firestore
        .collection('hostels')
        .where('managerId', isEqualTo: user.uid)
        .get();

    if (managerHostelsSnapshot.docs.isEmpty) {
      return [];
    }

    Set<String> tenantIds = {}; // Use a Set for automatic uniqueness
    for (var hostelDoc in managerHostelsSnapshot.docs) {
      final roomsSnapshot = await hostelDoc.reference.collection('rooms').get();
      for (var roomDoc in roomsSnapshot.docs) {
        final tenantId = roomDoc.data()['tenantId'] as String?;
        if (tenantId != null) {
          tenantIds.add(tenantId);
        }
      }
    }

    if (tenantIds.isEmpty) {
      return [];
    }

    // Fetch tenant details in chunks to avoid firestore limitation on 'whereIn'
    List<QueryDocumentSnapshot> tenantDocs = [];
    final tenantIdList = tenantIds.toList();
    for (var i = 0; i < tenantIdList.length; i += 30) {
      // Firestore `whereIn` supports up to 30 elements in a single query
      var chunk = tenantIdList.sublist(i, i + 30 > tenantIdList.length ? tenantIdList.length : i + 30);
      if (chunk.isNotEmpty) {
        final tenantsSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        tenantDocs.addAll(tenantsSnapshot.docs);
      }
    }
        
    return tenantDocs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Listing'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _tenantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tenants found.'));
          }
          final tenants = snapshot.data!;
          return ListView.builder(
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              final tenantData = tenant.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(tenantData['fullName']?[0] ?? 'T'),
                  ),
                  title: Text(tenantData['fullName'] ?? 'N/A'),
                  subtitle: Text('Email: ${tenantData['email'] ?? 'N/A'}'),
                  trailing: ElevatedButton(
                    child: const Text('View Profile'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: tenant.id),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
