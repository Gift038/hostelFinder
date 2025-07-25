import 'package:flutter/material.dart';

class TenantDocumentScreen extends StatelessWidget {
  const TenantDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final List<Map<String, dynamic>> documents = [
      {
        'icon': Icons.description,
        'title': 'Lease Agreement',
        'subtitle': 'Your signed lease document',
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Payment Receipts',
        'subtitle': 'All your payment receipts',
      },
      {
        'icon': Icons.insert_drive_file,
        'title': 'Other Documents',
        'subtitle': 'Relevant documents for your tenancy',
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: Colors.brown,
        elevation: 0,
        title: const Text('Documents'),
        leading: BackButton(color: coffeeBrown),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ListTile(
              leading: Icon(doc['icon'], color: coffeeBrown, size: 36),
              title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(doc['subtitle']),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: coffeeBrown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                child: const Text('View'),
              ),
            ),
          );
        },
      ),
    );
  }
} 