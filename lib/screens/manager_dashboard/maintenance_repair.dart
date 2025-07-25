import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MaintenanceRepairsScreen extends StatefulWidget {
  const MaintenanceRepairsScreen({super.key});

  @override
  MaintenanceRepairsScreenState createState() =>
      MaintenanceRepairsScreenState();
}

class MaintenanceRepairsScreenState extends State<MaintenanceRepairsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _statusAll = 'All';
  static const String _statusPending = 'Pending';
  static const String _statusInProgress = 'In Progress';
  static const String _statusCompleted = 'Completed';

  String _selectedStatus = _statusAll;
  String _searchQuery = '';

  Stream<QuerySnapshot> _fetchMaintenanceRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore.collection('users').doc(user.uid).snapshots().asyncExpand((userDoc) {
      final role = userDoc.data()?['role'] ?? 'manager';
      Query query = _firestore.collection('maintenance_requests');

      if (role == 'tenant') {
        query = query.where('tenantId', isEqualTo: user.uid);
      } else if (role == 'manager') {
        query = query.where('managerId', isEqualTo: user.uid);
      }
      // Admin sees all requests, so no additional filter is needed.

      return query.orderBy('timestamp', descending: true).snapshots();
    });
  }

  Future<void> _updateRequestStatus(String docId, String newStatus) async {
    try {
      final Map<String, dynamic> updateData = {'status': newStatus};
      if (newStatus == _statusCompleted) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }
      await _firestore
          .collection('maintenance_requests')
          .doc(docId)
          .update(updateData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request status updated to $newStatus.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _confirmAndUpdateStatus(String docId, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text(
          'Are you sure you want to mark this request as $newStatus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateRequestStatus(docId, newStatus);
    }
  }

  Stream<QuerySnapshot> _fetchComments(String requestId) {
    return _firestore
        .collection('maintenance_requests')
        .doc(requestId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> _addComment(String requestId, String text) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;
    await _firestore
        .collection('maintenance_requests')
        .doc(requestId)
        .collection('comments')
        .add({
          'text': text.trim(),
          'authorName': user.displayName ?? 'Manager',
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Map<String, dynamic> _calculateResolutionAnalytics(
    List<QueryDocumentSnapshot> requests,
  ) {
    final completed = requests.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == _statusCompleted &&
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

  Widget statusChip(String status) {
    Color color;
    switch (status) {
      case _statusPending:
        color = Colors.red;
        break;
      case _statusInProgress:
        color = Colors.orange;
        break;
      case _statusCompleted:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status),
      backgroundColor: color.withAlpha(51),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance & Repairs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by room or tenant',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim().toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: [
                    _statusAll,
                    _statusPending,
                    _statusInProgress,
                    _statusCompleted
                  ]
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchMaintenanceRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Failed to load requests: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
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
                  final status = data['status'] ?? _statusPending;
                  final room = (data['roomNumber'] ?? '')
                      .toString()
                      .toLowerCase();
                  final tenant = (data['tenantName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final matchesStatus =
                      _selectedStatus == _statusAll || status == _selectedStatus;
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      room.contains(_searchQuery) ||
                      tenant.contains(_searchQuery);
                  return matchesStatus && matchesSearch;
                }).toList();
                if (filteredRequests.isEmpty) {
                  return const Center(
                    child: Text('No requests match your filter/search.'),
                  );
                }
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
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = filteredRequests[index];
                          final data = request.data() as Map<String, dynamic>;
                          final status = data['status'] ?? _statusPending;
                          final timestamp = data['timestamp'];
                          String dateStr = '';
                          if (timestamp != null && timestamp is Timestamp) {
                            dateStr = DateFormat.yMMMd().add_jm().format(
                              timestamp.toDate(),
                            );
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ExpansionTile(
                              title: Text(
                                data['issueType'] ?? 'No Title',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Text('Room: ${data['roomNumber']}'),
                                  const SizedBox(width: 8),
                                  statusChip(status),
                                  const SizedBox(width: 8),
                                  if (dateStr.isNotEmpty)
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Description:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['description'] ??
                                            'No description provided.',
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Reported by: ${data['tenantName'] ?? 'N/A'}',
                                      ),
                                      if (data['imageUrl'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Image.network(
                                            data['imageUrl'],
                                            height: 120,
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Comments:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: _fetchComments(request.id),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Text(
                                              'Loading comments...',
                                            );
                                          }
                                          final comments = snapshot.data!.docs;
                                          if (comments.isEmpty) {
                                            return const Text(
                                              'No comments yet.',
                                            );
                                          }
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Divider(height: 24),
                                              ...comments.map((doc) {
                                                final data =
                                                    doc.data()
                                                        as Map<String, dynamic>;
                                                final author =
                                                    data['authorName'] ??
                                                    'Unknown';
                                                final text = data['text'] ?? '';
                                                final ts = data['timestamp'];
                                                String dateStr = '';
                                                if (ts != null &&
                                                    ts is Timestamp) {
                                                  dateStr = DateFormat.yMMMd()
                                                      .add_jm()
                                                      .format(ts.toDate());
                                                }
                                                final isManager = author
                                                    .toLowerCase()
                                                    .contains('manager');
                                                final bubbleColor = isManager
                                                    ? Colors.brown[50]
                                                    : Colors.blue[50];
                                                final textColor = isManager
                                                    ? Colors.brown[900]
                                                    : Colors.blue[900];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6.0,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor:
                                                            isManager
                                                            ? Colors.brown
                                                            : Colors.blue,
                                                        child: Text(
                                                          author.isNotEmpty
                                                              ? author[0]
                                                                    .toUpperCase()
                                                              : '?',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: bubbleColor,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                author,
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      textColor,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              Text(
                                                                text,
                                                                style: TextStyle(
                                                                  color:
                                                                      textColor,
                                                                ),
                                                              ),
                                                              if (dateStr
                                                                  .isNotEmpty)
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .bottomRight,
                                                                  child: Text(
                                                                    dateStr,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      _AddCommentField(
                                        requestId: request.id,
                                        onAdd: _addComment,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (status == _statusPending)
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _confirmAndUpdateStatus(
                                                    request.id,
                                                    _statusInProgress,
                                                  ),
                                              child: const Text(
                                                'Start Progress',
                                              ),
                                            ),
                                          if (status == _statusInProgress)
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _confirmAndUpdateStatus(
                                                    request.id,
                                                    _statusCompleted,
                                                  ),
                                              child: const Text(
                                                'Mark as Completed',
                                              ),
                                            ),
                                          if (status == _statusCompleted)
                                            Text(
                                              'Completed',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCommentField extends StatefulWidget {
  final String requestId;
  final Future<void> Function(String requestId, String text) onAdd;
  const _AddCommentField({required this.requestId, required this.onAdd});

  @override
  State<_AddCommentField> createState() => _AddCommentFieldState();
}

class _AddCommentFieldState extends State<_AddCommentField> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              minLines: 1,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending || _controller.text.trim().isEmpty
                  ? null
                  : () async {
                      final text = _controller.text;
                      if (text.trim().isEmpty) return;
                      setState(() => _isSending = true);
                      await widget.onAdd(widget.requestId, text);
                      if (!mounted) return;
                      _controller.clear();
                      setState(() => _isSending = false);
                    },
            ),
          ),
        ],
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
