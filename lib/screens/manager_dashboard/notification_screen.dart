import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  // Color scheme
  static const Color coffeeBrown = Color(0xFF4B2E19); // Dark coffee brown
  static const Color dashboarcofffeebrownlight = Colors.white;

  static const List<String> notifications = [
    'The gym equipment is broken',
    'The elevator is not working',
    'The wifi is slow',
  ];

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> notifications = [
    'The gym equipment is broken',
    'The elevator is not working',
    'The wifi is slow',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF3E3),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: NotificationScreen.coffeeBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: notifications
                  .map((note) => ListTile(
                        title: Text(note, style: const TextStyle(color: NotificationScreen.coffeeBrown)),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a notification...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NotificationScreen.coffeeBrown,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notification sent: \'${_controller.text}\'')),
                      );
                      _controller.clear();
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
