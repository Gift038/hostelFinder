// hostel_list_tile.dart file
import 'package:flutter/material.dart';

class HostelListTile extends StatefulWidget {
  final String imagePath;
  final String name;
  final double rating;
  final int reviews;
  final int price;
  final String details;
  final String type;

  const HostelListTile({
    super.key,
    required this.imagePath,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.details,
    required this.type,
  });

  @override
  State<HostelListTile> createState() => _HostelListTileState();
}

class _HostelListTileState extends State<HostelListTile> {
  bool _isHovered = false;
  final Color coffeeBrown = const Color(0xFF4B2E05);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: _isHovered ? coffeeBrown : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Details
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _isHovered ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '\u2022 ${widget.reviews} reviews',
                            style: TextStyle(
                              color: _isHovered ? Colors.white70 : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _isHovered ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.type,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.details,
                        style: TextStyle(
                          color: const Color(0xFF9C7A5F),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Starting at Ugx ${widget.price}',
                        style: TextStyle(
                          color: _isHovered ? Colors.white70 : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () {
                          // TODO: Pass hostel ID and fetch rooms/images from Firestore
                          // on the virtual tours screen.
                          Navigator.pushNamed(
                            context,
                            '/virtual-tours',
                            arguments: {
                              'hostelName': widget.name,
                              'rooms': [], // Pass empty list to avoid hardcoded data
                            },
                          );
                        },
                        child: Text(
                          'Virtual Tour',
                          style: TextStyle(
                            color: const Color(0xFF9C7A5F),
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.imagePath.isNotEmpty
                      ? Image.network(
                    widget.imagePath,
                    width: 80,
                    height: 70,
                    fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 70,
                          color: Colors.grey[300],
                          child: Center(
                            child: Text('Image goes here', style: TextStyle(color: Colors.grey[700], fontSize: 10)),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
