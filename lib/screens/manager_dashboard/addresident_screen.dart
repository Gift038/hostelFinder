import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddResidentScreen extends StatefulWidget {
  const AddResidentScreen({super.key});

  @override
  State<AddResidentScreen> createState() => _AddResidentScreenState();
}

class _AddResidentScreenState extends State<AddResidentScreen> {
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedRoomType = 'Single Room';
  String _selectedCapacity = '1';
  bool _isAvailable = true;
  DateTime? _moveInDate;

  String _searchText = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define color scheme
  final Color coffeeBrown = const Color(0xFF4B2E19); // Dark coffee brown
  final Color coffeeBrownLight = const Color(0xFFD7CCC8); // Light brown for accents
  final Color dashboardWhite = Colors.white; // White background

  Future<void> _pickMoveInDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _moveInDate = picked);
    }
  }

  Future<void> _saveResident({String? id}) async {
    final roomNumber = _roomNumberController.text.trim();
    final price = _priceController.text.trim();

    if (roomNumber.isEmpty || price.isEmpty || _moveInDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final data = {
      'room_number': roomNumber,
      'room_type': _selectedRoomType,
      'capacity': _selectedCapacity,
      'price': price,
      'available': _isAvailable,
      'move_in_date': _moveInDate,
      'created_at': FieldValue.serverTimestamp(),
    };
    try {
      if (id == null) {
        await _firestore.collection('residents').add(data);
      } else {
        await _firestore.collection('residents').doc(id).update(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id == null ? "Resident added" : "Resident updated"),
        ),
      );
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: '
            + e.toString())),
      );
    }
  }

  void _clearForm() {
    _roomNumberController.clear();
    _priceController.clear();
    _selectedRoomType = 'Single Room';
    _selectedCapacity = '1';
    _isAvailable = true;
    _moveInDate = null;
    setState(() {});
  }

  Future<void> _deleteResident(String id) async {
    try {
      await _firestore.collection('residents').doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Resident deleted")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: '
            + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dashboardWhite,
      appBar: AppBar(
        title: const Text('Add Resident'),
        backgroundColor: coffeeBrown,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Scrollable form area
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField("Room Number", _roomNumberController),
                    _buildDropdown(
                      "Room Type",
                      ['Single Room', 'Double Room'],
                      _selectedRoomType,
                      (v) {
                        setState(() => _selectedRoomType = v!);
                      },
                    ),
                    _buildDropdown(
                      "Capacity",
                      ['1', '2', '3', '4', '5'],
                      _selectedCapacity,
                      (v) {
                        setState(() => _selectedCapacity = v!);
                      },
                    ),
                    _buildTextField(
                      "Price per staying period",
                      _priceController,
                    ),
                    _buildDatePicker(),
                    _buildAvailabilityToggle(),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: coffeeBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () => _saveResident(),
                        child: const Text("Save Resident"),
                      ),
                    ),
                    const Divider(height: 30),
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            // Scrollable list area
            Expanded(flex: 3, child: _buildResidentsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        tileColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          _moveInDate == null
              ? "Select Move-in Date"
              : DateFormat('yyyy-MM-dd').format(_moveInDate!),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: _pickMoveInDate,
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return SwitchListTile(
      title: const Text("Room Available"),
      value: _isAvailable,
      onChanged: (value) => setState(() => _isAvailable = value),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search by Room Number",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => setState(() => _searchText = value.trim()),
    );
  }

  Widget _buildResidentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('residents')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading residents");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final room = data['room_number'].toString().toLowerCase();
          return room.contains(_searchText.toLowerCase());
        }).toList();

        if (docs.isEmpty) return const Text("No matching residents found");

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              color: coffeeBrownLight,
              child: ListTile(
                tileColor: coffeeBrownLight,
                title: Text("Room "+data['room_number'], style: TextStyle(color: coffeeBrown)),
                subtitle: Text(
                  "${data['room_type']} | Capacity: ${data['capacity']} | Price: ${data['price']} | Available: ${data['available'] ? "Yes" : "No"}\nMove-in: ${DateFormat('yyyy-MM-dd').format((data['move_in_date'] as Timestamp).toDate())}",
                  style: TextStyle(color: coffeeBrown),
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        _roomNumberController.text = data['room_number'];
                        _priceController.text = data['price'];
                        _selectedRoomType = data['room_type'];
                        _selectedCapacity = data['capacity'];
                        _isAvailable = data['available'];
                        _moveInDate = (data['move_in_date'] as Timestamp)
                            .toDate();
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteResident(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
