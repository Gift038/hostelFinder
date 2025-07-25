import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewDocumentsScreen extends StatefulWidget {
  const ViewDocumentsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ViewDocumentsScreenState createState() => _ViewDocumentsScreenState();
}

class _ViewDocumentsScreenState extends State<ViewDocumentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> _fetchTenantsWithDocuments() async {
    final managerId = FirebaseAuth.instance.currentUser?.uid;
    if (managerId == null) {
      return []; // Not logged in
    }

    // For this example, we'll fetch all tenants for the manager.
    final tenantsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'tenant')
        .where('managerId', isEqualTo: managerId)
        .get();

    return tenantsSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tenant Documents')),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _fetchTenantsWithDocuments(),
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

              return ListTile(
                title: Text(tenantData['fullName'] ?? 'N/A'),
                subtitle: Text(tenantData['email'] ?? 'N/A'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TenantDocumentListScreen(tenantId: tenant.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TenantDocumentListScreen extends StatelessWidget {
  final String tenantId;

  const TenantDocumentListScreen({super.key, required this.tenantId});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Re-throw to be caught by the UI layer
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(tenantId)
            .collection('documents')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No documents uploaded.'));
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final docData = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(docData['fileName'] ?? 'Untitled'),
                  subtitle: Text(
                    'Uploaded on: ${docData['uploadedAt'].toDate()}',
                  ),
                  onTap: () async {
                    try {
                      await _launchURL(docData['downloadURL']);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
