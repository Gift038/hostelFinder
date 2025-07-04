import 'package:flutter/material.dart';
import 'dart:async';

class VirtualToursScreen extends StatelessWidget {
  const VirtualToursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String hostelName = args != null && args['hostelName'] != null ? args['hostelName'] : 'Virtual Tours';
    final List rooms = args != null && args['rooms'] != null ? args['rooms'] : [];
    final List amenities = args != null && args['amenities'] != null ? args['amenities'] : [];
    final String location = args != null && args['location'] != null ? args['location'] : '';
    final String details = args != null && args['details'] != null ? args['details'] : '';
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
          // Hostel Images Carousel Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _HostelImageCarousel(
                  images: (args != null && args['hostelImages'] != null && (args['hostelImages'] as List).isNotEmpty)
                      ? List<String>.from(args['hostelImages'])
                      : [
                          'assets/hostel1.jpg',
                          'assets/hostel2.jpg',
                          'assets/hostel3.jpg',
                          'assets/hostel4.jpeg',
                          'assets/hostel5.jpg',
                          'assets/hostel6.jpg',
                        ],
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
                        border: Border.all(color: coffeeBrown.withOpacity(0.2)),
                      ),
                              child: Center(
                                child: Text(
                          'Google Map Placeholder\n(${location.isNotEmpty ? location : 'Hostel Location'})',
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
    // Use at least 6 images for demonstration; fallback to a default set if not enough provided
    final imgs = (widget.room['images'] as List<String>?) ?? [];
    if (imgs.length >= 6) return imgs;
    // Add placeholder images if less than 6
    return [
      ...imgs,
      'assets/hostel1.jpg',
      'assets/hostel2.jpg',
      'assets/hostel3.jpg',
      'assets/hostel4.jpeg',
      'assets/hostel5.jpg',
      'assets/hostel1.jpg',
    ].take(6).toList();
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
              height: 120,
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: ClipRRect(
                      key: ValueKey(_currentImage),
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        images[_currentImage],
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
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
                          color: idx == _currentImage ? coffeeBrown : lightCoffeeBrown.withOpacity(0.4),
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
  const _BookNowButton({required this.coffeeBrown, required this.lightCoffeeBrown, this.roomType, this.enabled = true});

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
                Navigator.pushNamed(context, '/booking', arguments: {
                  if (widget.roomType != null) 'roomType': widget.roomType,
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
                color: Colors.brown.withOpacity(0.1),
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
            child: Image.asset(
              widget.images[_current],
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
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