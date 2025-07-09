import 'package:flutter/material.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final List<Map<String, dynamic>> _requests = [
    {
      'title': 'Leaky Faucet',
      'description': 'Room 101 - Faucet is leaking.',
      'resolved': false,
    },
    {
      'title': 'Broken Window',
      'description': 'Room 203 - Window needs replacement.',
      'resolved': false,
    },
  ];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  void _addRequest() {
    if (_titleController.text.isNotEmpty && _descController.text.isNotEmpty) {
      setState(() {
        _requests.add({
          'title': _titleController.text,
          'description': _descController.text,
          'resolved': false,
        });
        _titleController.clear();
        _descController.clear();
      });
      Navigator.pop(context);
    }
  }

  void _showAddRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Maintenance Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addRequest,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleResolved(int index) {
    setState(() {
      _requests[index]['resolved'] = !_requests[index]['resolved'];
    });
  }

  void _deleteRequest(int index) {
    setState(() {
      _requests.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];
          return Card(
            child: ListTile(
              title: Text(req['title']),
              subtitle: Text(req['description']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      req['resolved'] ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: req['resolved'] ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleResolved(index),
                    tooltip: req['resolved'] ? 'Mark as unresolved' : 'Mark as resolved',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRequest(index),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRequestDialog,
        tooltip: 'Add Maintenance Request',
        child: const Icon(Icons.add),
      ),
    );
  }
}