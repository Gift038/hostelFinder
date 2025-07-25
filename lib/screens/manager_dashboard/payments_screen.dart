import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  //ignore: library_private_types_in_public_api
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<Map<String, dynamic>> _paymentsDataFuture;

  @override
  void initState() {
    super.initState();
    _paymentsDataFuture = _fetchPaymentsData();
  }

  Future<Map<String, dynamic>> _fetchPaymentsData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'revenue': 0.0,
        'outstanding': 0.0,
        'transactions': <QueryDocumentSnapshot>[],
      };
    }

    double totalRevenue = 0.0;
    double totalOutstanding = 0.0;

    // 1. Get all payments for the current manager
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('managerId', isEqualTo: user.uid)
        .get();

    final allTransactions = paymentsSnapshot.docs;

    for (var paymentDoc in allTransactions) {
      final data = paymentDoc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final status = data['status'] as String?;
      final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (status == 'Success' &&
          date.month == DateTime.now().month &&
          date.year == DateTime.now().year) {
        totalRevenue += amount;
      }
      if (status == 'Pending' || status == 'Failed') {
        totalOutstanding += amount;
      }
    }

    // Sort transactions by date
    allTransactions.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aDate = (aData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bDate = (bData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return {
      'revenue': totalRevenue,
      'outstanding': totalOutstanding,
      'transactions': allTransactions,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _paymentsDataFuture = _fetchPaymentsData();
            }),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _paymentsDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No payment data available.'));
          }

          final data = snapshot.data!;
          final double revenue = data['revenue'];
          final double outstanding = data['outstanding'];
          final List<QueryDocumentSnapshot> transactions =
              data['transactions'] as List<QueryDocumentSnapshot>;

          return Column(
            children: [
              // Summary Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard(
                      'Revenue (This Month)',
                      currencyFormat.format(revenue),
                      Colors.green,
                    ),
                    _buildSummaryCard(
                      'Outstanding',
                      currencyFormat.format(outstanding),
                      Colors.red,
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Transaction List
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No transactions yet.'))
                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final doc = transactions[index];
                          final paymentData =
                              doc.data() as Map<String, dynamic>;
                          final status = paymentData['status'] ?? 'N/A';
                          final date =
                              (paymentData['date'] as Timestamp?)?.toDate() ??
                              DateTime.now();

                          return ListTile(
                            leading: Icon(
                              status == 'Success'
                                  ? Icons.check_circle
                                  : (status == 'Pending'
                                        ? Icons.hourglass_empty
                                        : Icons.cancel),
                              color: status == 'Success'
                                  ? Colors.green
                                  : (status == 'Pending'
                                        ? Colors.orange
                                        : Colors.red),
                            ),
                            title: Text(
                              'Amount: ${currencyFormat.format(paymentData['amount'] ?? 0)}',
                            ),
                            subtitle: Text(
                              'Tenant: ${paymentData['tenantName'] ?? 'N/A'}\nDate: ${DateFormat.yMMMd().format(date)}',
                            ),
                            trailing: Text(status),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
