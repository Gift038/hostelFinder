import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  String? _selectedHostelId;
  Stream<QuerySnapshot>? _hostelsStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hostelsStream = _fetchManagerHostels();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _fetchManagerHostels() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('hostels').where('managerId', isEqualTo: user.uid).snapshots();
  }

  Future<void> _sendBroadcast() async {
    if (_selectedHostelId == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hostel and write a message.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await _firestore.collection('broadcasts').add({
        'hostelId': _selectedHostelId,
        'managerId': _auth.currentUser?.uid,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent successfully!')),
      );

      // Clear the form
      setState(() {
        _selectedHostelId = null;
        _messageController.clear();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send broadcast: ${e.toString()}')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Broadcast Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hostel Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: _hostelsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('You have no hostels to send broadcasts to.');
                }
                final hostels = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedHostelId,
                  hint: const Text('Select Hostel'),
                  onChanged: (value) => setState(() => _selectedHostelId = value),
                  items: hostels.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Message Field
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Broadcast Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            
            // Send Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Send Broadcast'),
                    onPressed: _sendBroadcast,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
} 