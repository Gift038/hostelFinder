import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';

  Map<String, dynamic> _calculateResolutionAnalytics(
    List<QueryDocumentSnapshot> requests,
  ) {
    final completed = requests.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'Completed' &&
          data['timestamp'] != null &&
          data['completedAt'] != null;
    }).toList();
    if (completed.isEmpty) {
      return {'average': 0, 'min': 0, 'max': 0, 'count': 0};
    }
    final durations = completed.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final created = (data['timestamp'] as Timestamp).toDate();
      final completedAt = (data['completedAt'] as Timestamp).toDate();
      return completedAt.difference(created).inMinutes;
    }).toList();
    final avg = durations.reduce((a, b) => a + b) / durations.length;
    final min = durations.reduce((a, b) => a < b ? a : b);
    final max = durations.reduce((a, b) => a > b ? a : b);
    return {'average': avg, 'min': min, 'max': max, 'count': completed.length};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('maintenance_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No maintenance requests.'));
          }
          final requests = snapshot.data!.docs;
          final analytics = _calculateResolutionAnalytics(requests);
          final filteredRequests = requests.where((request) {
            final data = request.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            final manager = (data['managerId'] ?? '').toString().toLowerCase();
            final tenant = (data['tenantId'] ?? '').toString().toLowerCase();
            final matchesStatus =
                _selectedStatus == 'All' || status == _selectedStatus;
            final matchesSearch =
                _searchQuery.isEmpty ||
                manager.contains(_searchQuery) ||
                tenant.contains(_searchQuery);
            return matchesStatus && matchesSearch;
          }).toList();
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AnalyticsStat(
                        label: 'Avg (min)',
                        value: analytics['average'].toStringAsFixed(1),
                      ),
                      _AnalyticsStat(
                        label: 'Min (min)',
                        value: analytics['min'].toString(),
                      ),
                      _AnalyticsStat(
                        label: 'Max (min)',
                        value: analytics['max'].toString(),
                      ),
                      _AnalyticsStat(
                        label: 'Completed',
                        value: analytics['count'].toString(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search by manager or tenant ID',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(
                            () => _searchQuery = value.trim().toLowerCase(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      items: ['All', 'Pending', 'In Progress', 'Completed']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: filteredRequests.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    final data = request.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    final created = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : null;
                    final completedAt = data['completedAt'] != null
                        ? (data['completedAt'] as Timestamp).toDate()
                        : null;
                    return ListTile(
                      leading: Icon(
                        Icons.build,
                        color: status == 'Completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(data['issueType'] ?? 'No Title'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manager: ${data['managerId'] ?? 'N/A'}'),
                          Text('Tenant: ${data['tenantId'] ?? 'N/A'}'),
                          Text('Status: $status'),
                          if (created != null)
                            Text(
                              'Created: ${DateFormat.yMMMd().add_jm().format(created)}',
                            ),
                          if (completedAt != null)
                            Text(
                              'Completed: ${DateFormat.yMMMd().add_jm().format(completedAt)}',
                            ),
                        ],
                      ),
                      trailing:
                          status == 'Completed' &&
                              created != null &&
                              completedAt != null
                          ? Text(
                              '${completedAt.difference(created).inMinutes} min',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
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
}

class _AnalyticsStat extends StatelessWidget {
  final String label;
  final String value;
  const _AnalyticsStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
