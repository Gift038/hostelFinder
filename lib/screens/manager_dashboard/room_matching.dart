import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  String selectedFilter = 'Interests';
  final List<String> filters = ['Interests', 'Schedules', 'Preferences'];
  final TextEditingController searchController = TextEditingController();

  // Example: Current user's gender
  final String currentUserGender = 'female'; // or 'male'

  // Example resident data with gender
  final List<Map<String, dynamic>> residents = [
    {
      'name': 'John Doe',
      'avatar': 'https://randomuser.me/api/portraits/men/1.jpg',
      'gender': 'male',
      'interests': ['Hiking', 'Reading'],
    },
    {
      'name': 'Alex Smith',
      'avatar': 'https://randomuser.me/api/portraits/men/2.jpg',
      'gender': 'male',
      'interests': ['Gaming', 'Movies'],
    },
    {
      'name': 'Jane Lee',
      'avatar': 'https://randomuser.me/api/portraits/women/1.jpg',
      'gender': 'female',
      'interests': ['Cooking', 'Music'],
    },
    {
      'name': 'Emily Clark',
      'avatar': 'https://randomuser.me/api/portraits/women/2.jpg',
      'gender': 'female',
      'interests': ['Music', 'Reading'],
    },
  ];

  // Example available rooms
  final List<String> availableRooms = ['101', '102', '201', '202', '301'];
  Map<String, String> residentRoomAssignments = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // Filter residents by gender
    List<Map<String, dynamic>> matchedResidents = residents
        .where((r) => r['gender'] == currentUserGender)
        .toList();

    // Optional: filter by search
    String search = searchController.text.toLowerCase();
    if (search.isNotEmpty) {
      matchedResidents = matchedResidents
          .where((r) => r['name'].toLowerCase().contains(search))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Room Management & Matching'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search residents',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Filter chips
            Row(
              children: filters.map((filter) {
                final isSelected = filter == selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    selectedColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Residents list (matched by gender)
            Expanded(
              child: matchedResidents.isEmpty
                  ? const Center(child: Text('No residents match your gender.'))
                  : ListView.builder(
                      itemCount: matchedResidents.length,
                      itemBuilder: (context, index) {
                        final resident = matchedResidents[index];
                        final assignedRoom = residentRoomAssignments[resident['name']];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(resident['avatar']),
                          ),
                          title: Text(resident['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Shared Interests: ${resident['interests'].join(', ')}'),
                              if (assignedRoom != null)
                                Text('Assigned Room: $assignedRoom', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: assignedRoom,
                                hint: const Text('Select Room'),
                                items: availableRooms.map((room) {
                                  return DropdownMenuItem(
                                    value: room,
                                    child: Text(room),
                                  );
                                }).toList(),
                                onChanged: (room) {
                                  setState(() {
                                    residentRoomAssignments[resident['name']] = room!;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                tooltip: 'Assign Room',
                                onPressed: assignedRoom == null
                                    ? null
                                    : () async {
                                        try {
                                          // Persist assignment to Firestore (assumes resident['id'] exists)
                                          await _firestore.collection('residents').doc(resident['id']).update({
                                            'assigned_room': assignedRoom,
                                          });
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${resident['name']} assigned to room $assignedRoom')),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: '
                                                + e.toString())),
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
