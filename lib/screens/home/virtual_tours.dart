//virtual_tours.dart file
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class VirtualToursScreen extends StatelessWidget {
  const VirtualToursScreen({super.key});

  Future<Map<String, dynamic>?> _fetchHostelById(String hostelId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('hostels').doc(hostelId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // Add the document ID to the data map for reference
          return {...data, 'id': doc.id};
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    // If args is a String, treat as hostelId; else, fallback to old Map logic
    if (args is String) {
      final String hostelId = args;
      return FutureBuilder<Map<String, dynamic>?>(
        future: _fetchHostelById(hostelId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Scaffold(
              body: Center(child: Text('Hostel not found.')),
            );
          }
          final hostel = snapshot.data!;
          // Map Firestore fields to expected args
          final String hostelName = hostel['name'] ?? 'Virtual Tours';
          final List rooms = hostel['rooms'] ?? [];
          final List amenities = hostel['amenities'] ?? [];
          final String location = hostel['location'] ?? '';
          final String details = hostel['details'] ?? '';
          final List hostelImages = (hostel['hostelImages'] ?? hostel['imageUrls'] ?? []) as List;
          final Color coffeeBrown = const Color(0xFF4B2E05);
          final Color lightCoffeeBrown = const Color(0xFF9C7A5F);

          return Scaffold(
            appBar: AppBar(
              title: Text(hostelName),
              backgroundColor: const Color(0xFFF8F5F2),
              foregroundColor: coffeeBrown,
            ),
            backgroundColor: const Color(0xFFF8F5F2),
            body: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _HostelImageCarousel(
                        images: hostelImages.isNotEmpty ? List<String>.from(hostelImages) : [],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hostelName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: coffeeBrown,
                            ),
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              details,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text('Room Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: coffeeBrown)),
                          const SizedBox(height: 12),
                          ...rooms.map<Widget>((room) => _RoomOptionCard(room: room, coffeeBrown: coffeeBrown, lightCoffeeBrown: lightCoffeeBrown, showBooking: false)),
                          const SizedBox(height: 24),
                          Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: coffeeBrown)),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AmenityCheckbox(
                                label: 'Swimming Pool',
                                checked: amenities.contains('Swimming Pool'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Gym',
                                checked: amenities.contains('Gym'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Parking Space',
                                checked: amenities.contains('Parking Space'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Wi-Fi',
                                checked: amenities.contains('Wi-Fi'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Laundry Room',
                                checked: amenities.contains('Laundry Room'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Hang Line',
                                checked: amenities.contains('Hang Line'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Study Room',
                                checked: amenities.contains('Study Room'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Shared Kitchen',
                                checked: amenities.contains('Shared Kitchen'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Playground',
                                checked: amenities.contains('Playground'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                              const SizedBox(height: 2),
                              _AmenityCheckbox(
                                label: 'Enhanced Security',
                                checked: amenities.contains('Enhanced Security'),
                                coffeeBrown: coffeeBrown,
                                lightCoffeeBrown: lightCoffeeBrown,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: coffeeBrown)),
                          const SizedBox(height: 12),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: coffeeBrown.withAlpha(51)),
                            ),
                            child: Center(
                              child: Text(
                                'Google Map Placeholder\n( ${location.isNotEmpty ? location : 'Hostel Location'})',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: coffeeBrown, fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    // Fallback: old logic (for dev/testing)
    final Map? mapArgs = args as Map?;
    final String hostelName = mapArgs != null && mapArgs['hostelName'] != null ? mapArgs['hostelName'] : 'Virtual Tours';
    final List rooms = mapArgs != null && mapArgs['rooms'] != null ? mapArgs['rooms'] : [];
    final List amenities = mapArgs != null && mapArgs['amenities'] != null ? mapArgs['amenities'] : [];
    final String location = mapArgs != null && mapArgs['location'] != null ? mapArgs['location'] : '';
    final String details = mapArgs != null && mapArgs['details'] != null ? mapArgs['details'] : '';
    final List hostelImages = (mapArgs != null && mapArgs['hostelImages'] != null) ? mapArgs['hostelImages'] : [];
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);

    return Scaffold(
      appBar: AppBar(
        title: Text(hostelName),
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: coffeeBrown,
      ),
      backgroundColor: const Color(0xFFF8F5F2),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _HostelImageCarousel(
                  images: hostelImages.isNotEmpty ? List<String>.from(hostelImages) : [],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Card(
              color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
                    child: Padding(
                padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                      hostelName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: coffeeBrown,
                      ),
                          ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        details,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text('Room Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: coffeeBrown)),
                    const SizedBox(height: 12),
                    ...rooms.map<Widget>((room) => _RoomOptionCard(room: room, coffeeBrown: coffeeBrown, lightCoffeeBrown: lightCoffeeBrown, showBooking: false)),
                    const SizedBox(height: 24),
                    Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: coffeeBrown)),
                          const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AmenityCheckbox(
                          label: 'Swimming Pool',
                          checked: amenities.contains('Swimming Pool'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Gym',
                          checked: amenities.contains('Gym'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Parking Space',
                          checked: amenities.contains('Parking Space'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Wi-Fi',
                          checked: amenities.contains('Wi-Fi'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Laundry Room',
                          checked: amenities.contains('Laundry Room'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Hang Line',
                          checked: amenities.contains('Hang Line'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Study Room',
                          checked: amenities.contains('Study Room'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Shared Kitchen',
                          checked: amenities.contains('Shared Kitchen'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Playground',
                          checked: amenities.contains('Playground'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                        ),
                        const SizedBox(height: 2),
                        _AmenityCheckbox(
                          label: 'Enhanced Security',
                          checked: amenities.contains('Enhanced Security'),
                          coffeeBrown: coffeeBrown,
                          lightCoffeeBrown: lightCoffeeBrown,
                              ),
                      ],
                            ),
                    const SizedBox(height: 24),
                    Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: coffeeBrown)),
                    const SizedBox(height: 12),
                            Container(
                      height: 200,
                              width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: coffeeBrown.withAlpha(51)),
                      ),
                              child: Center(
                                child: Text(
                          'Google Map Placeholder\n( ${location.isNotEmpty ? location : 'Hostel Location'})',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: coffeeBrown, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
                );
  }
}

class _RoomOptionCard extends StatefulWidget {
  final Map room;
  final Color coffeeBrown;
  final Color lightCoffeeBrown;
  final bool showBooking;
  const _RoomOptionCard({required this.room, required this.coffeeBrown, required this.lightCoffeeBrown, required this.showBooking});

  @override
  State<_RoomOptionCard> createState() => _RoomOptionCardState();
}

class _RoomOptionCardState extends State<_RoomOptionCard> {
  int _currentImage = 0;
  Timer? _timer;

  List<String> get images {
    // Fix: Always cast to List<String> even if Firestore returns List<dynamic>
    final imgsRaw = widget.room['images'];
    if (imgsRaw is List) {
      return imgsRaw.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _currentImage = (_currentImage + 1) % images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final coffeeBrown = widget.coffeeBrown;
    final lightCoffeeBrown = widget.lightCoffeeBrown;
    final int available = room['available'] ?? 0;
    final int total = room['total'] ?? 0;
    final bool fullyBooked = available == 0;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated image carousel
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: ClipRRect(
                      key: ValueKey(_currentImage),
                      borderRadius: BorderRadius.circular(12),
                      child: images.isNotEmpty
                          ? Image.network(
                        images[_currentImage],
                        width: double.infinity,
                              height: 180,
                        fit: BoxFit.cover,
                            )
                          : Container(
                              width: double.infinity,
                              height: 180,
                              color: Colors.grey[300],
                              child: Center(child: Text('No Images', style: TextStyle(color: Colors.grey[700]))),
                      ),
                    ),
                  ),
                  // Dots indicator
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (idx) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: idx == _currentImage ? coffeeBrown : lightCoffeeBrown.withAlpha(102),
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    room['type'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: coffeeBrown),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: fullyBooked ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fullyBooked ? 'Fully Booked' : 'Available',
                    style: TextStyle(
                      color: fullyBooked ? Colors.red : Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (room['price'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'UGX ${room['price']}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: lightCoffeeBrown),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (room['desc'] != null) ...[
              const SizedBox(height: 4),
              Text(
                room['desc'],
                style: TextStyle(fontSize: 13, color: lightCoffeeBrown),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.meeting_room, color: coffeeBrown, size: 18),
                const SizedBox(width: 4),
                Text('Available: $available / $total', style: TextStyle(fontSize: 13, color: fullyBooked ? Colors.red : coffeeBrown, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            _BookNowButton(
              coffeeBrown: coffeeBrown,
              lightCoffeeBrown: lightCoffeeBrown,
              roomType: room['type'],
              enabled: !fullyBooked,
              price: room['price'],
              room: room,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookNowButton extends StatefulWidget {
  final Color coffeeBrown;
  final Color lightCoffeeBrown;
  final String? roomType;
  final bool enabled;
  final int? price;
  final Map? room;
  const _BookNowButton({required this.coffeeBrown, required this.lightCoffeeBrown, this.roomType, this.enabled = true, this.price, this.room});

  @override
  State<_BookNowButton> createState() => _BookNowButtonState();
}

class _BookNowButtonState extends State<_BookNowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.enabled
            ? () {
                Navigator.pushNamed(context, '/payment', arguments: {
                  'total': widget.price ?? 0,
                  'roomType': widget.roomType,
                  'room': widget.room,
                });
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: widget.enabled
                ? (_isHovered ? widget.coffeeBrown : widget.lightCoffeeBrown)
                : Colors.grey[400],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withAlpha(25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Book Now',
            style: TextStyle(
              color: widget.enabled ? Colors.white : Colors.grey[200],
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmenityCheckbox extends StatelessWidget {
  final String label;
  final bool checked;
  final Color coffeeBrown;
  final Color lightCoffeeBrown;
  const _AmenityCheckbox({required this.label, required this.checked, required this.coffeeBrown, required this.lightCoffeeBrown});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          color: checked ? coffeeBrown : lightCoffeeBrown,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: checked ? coffeeBrown : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HostelImageCarousel extends StatefulWidget {
  final List<String> images;
  const _HostelImageCarousel({required this.images});

  @override
  State<_HostelImageCarousel> createState() => _HostelImageCarouselState();
}

class _HostelImageCarouselState extends State<_HostelImageCarousel> {
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _current = (_current + 1) % widget.images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 180,
              color: Colors.grey[300],
              child: Center(child: Text('Image goes here', style: TextStyle(color: Colors.grey[700]))),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == index ? Colors.white : Colors.white54,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              ),
            ),
          ),
        ],
            ),
    );
  }
} 