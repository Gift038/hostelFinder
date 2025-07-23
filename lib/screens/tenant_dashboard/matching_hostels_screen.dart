import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // Uncomment if you add Google Maps
// import 'package:firebase_analytics/firebase_analytics.dart'; // Uncomment if you add analytics

class MatchingHostelsScreen extends StatefulWidget {
  const MatchingHostelsScreen({super.key});

  @override
  State<MatchingHostelsScreen> createState() => _MatchingHostelsScreenState();
}

class _MatchingHostelsScreenState extends State<MatchingHostelsScreen> {
  final int _limit = 10;
  DocumentSnapshot? _lastDoc;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _sortBy = 'min_price';
  bool _showMap = false;
  final Set<String> _favorites = {};
  // For multi-select
  List<String> _selectedPrograms = [];
  List<String> _selectedAmenities = [];

  // Haversine formula for distance in km
  double _distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final double price = args?['price'] ?? 500000;
    final bool wheelchair = args?['wheelchair'] ?? false;
    final bool noDisability = args?['noDisability'] ?? false;
    final bool shuttle = args?['shuttle'] ?? false;
    final bool noShuttle = args?['noShuttle'] ?? false;
    final bool studyRoom = args?['studyRoom'] ?? false;
    final bool gym = args?['gym'] ?? false;
    final bool pool = args?['pool'] ?? false;
    final bool ac = args?['ac'] ?? false;
    final bool wifi = args?['wifi'] ?? false;
    final bool electrical = args?['electrical'] ?? false;
    final bool guestPolicy = args?['guestPolicy'] ?? false;
    final bool petFriendly = args?['petFriendly'] ?? false;
    final String program = args?['program'] ?? '';
    final double distance = args?['distance'] ?? 5;
    final double refLat = args?['refLat'] ?? 0.3476;
    final double refLng = args?['refLng'] ?? 32.5825;
    // For multi-select
    _selectedPrograms =
        args?['selectedPrograms'] ?? (program.isNotEmpty ? [program] : []);
    _selectedAmenities = args?['selectedAmenities'] ?? [];

    Query query = FirebaseFirestore.instance.collection('hostels');
    query = query.where('min_price', isLessThanOrEqualTo: price);
    if (wheelchair) query = query.where('wheelchair', isEqualTo: true);
    if (shuttle) query = query.where('shuttle', isEqualTo: true);
    if (studyRoom) query = query.where('studyRoom', isEqualTo: true);
    if (gym) query = query.where('gym', isEqualTo: true);
    if (pool) query = query.where('pool', isEqualTo: true);
    if (ac) query = query.where('ac', isEqualTo: true);
    if (wifi) query = query.where('wifi', isEqualTo: true);
    if (electrical) query = query.where('electrical', isEqualTo: true);
    if (guestPolicy) query = query.where('guestPolicy', isEqualTo: true);
    if (petFriendly) query = query.where('petFriendly', isEqualTo: true);
    // Multi-select programs
    for (final p in _selectedPrograms) {
      query = query.where('programs', arrayContains: p);
    }
    // Multi-select amenities (scaffold)
    for (final a in _selectedAmenities) {
      query = query.where('amenities', arrayContains: a);
    }
    query = query.orderBy(_sortBy);
    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!).limit(_limit);
    } else {
      query = query.limit(_limit);
    }

    List<String> activeFilters = [
      if (price != 500000) '≤ UGX $price',
      if (distance != 5) '≤ ${distance.toStringAsFixed(0)} km',
      if (wheelchair) 'Wheelchair',
      if (noDisability) 'No Disability',
      if (shuttle) 'Shuttle',
      if (noShuttle) 'No Shuttle',
      if (studyRoom) 'Study Room',
      if (gym) 'Gym',
      if (pool) 'Pool',
      if (ac) 'A/C',
      if (wifi) 'Wi-Fi',
      if (electrical) 'Electrical',
      if (guestPolicy) 'Guest Policy',
      if (petFriendly) 'Pet-Friendly',
      ..._selectedPrograms,
      ..._selectedAmenities,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: Colors.brown,
        elevation: 0,
        title: const Text('Matching Hostels'),
        leading: BackButton(color: coffeeBrown),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'Show List' : 'Show Map',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'min_price',
                child: Text('Sort by Price'),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Text('Sort by Rating'),
              ),
              const PopupMenuItem(
                value: 'distance',
                child: Text('Sort by Distance'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (activeFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: activeFilters
                    .map((f) => Chip(label: Text(f)))
                    .toList(),
              ),
            ),
          Expanded(
            child: _showMap
                ? Center(
                    child: Text('Map view coming soon!'),
                  ) // Scaffold for Google Maps
                : StreamBuilder<QuerySnapshot>(
                    stream: query.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var docs = snapshot.data?.docs ?? [];
                      if (noShuttle) {
                        docs = docs
                            .where((d) => !(d['shuttle'] ?? false))
                            .toList();
                      }
                      if (noDisability) {
                        docs = docs
                            .where((d) => !(d['wheelchair'] ?? false))
                            .toList();
                      }
                      docs = docs.where((d) {
                        if (d['coordinates'] != null &&
                            d['coordinates']['lat'] != null &&
                            d['coordinates']['lng'] != null) {
                          final lat = d['coordinates']['lat'] as double;
                          final lng = d['coordinates']['lng'] as double;
                          final dist = _distanceBetween(
                            refLat,
                            refLng,
                            lat,
                            lng,
                          );
                          return dist <= distance;
                        }
                        return true;
                      }).toList();
                      if (_sortBy == 'distance') {
                        docs.sort((a, b) {
                          final aDist = a['coordinates'] != null
                              ? _distanceBetween(
                                  refLat,
                                  refLng,
                                  a['coordinates']['lat'] ?? 0,
                                  a['coordinates']['lng'] ?? 0,
                                )
                              : 9999.0;
                          final bDist = b['coordinates'] != null
                              ? _distanceBetween(
                                  refLat,
                                  refLng,
                                  b['coordinates']['lat'] ?? 0,
                                  b['coordinates']['lng'] ?? 0,
                                )
                              : 9999.0;
                          return aDist.compareTo(bDist);
                        });
                      }
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('No hostels match your filters.'),
                              SizedBox(height: 8),
                              Text(
                                'Try relaxing your filters or search in a wider area.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final hostel =
                                    docs[i].data() as Map<String, dynamic>;
                                final imageUrl =
                                    hostel['imageUrls'] != null &&
                                        (hostel['imageUrls'] as List).isNotEmpty
                                    ? hostel['imageUrls'][0]
                                    : null;
                                final isFavorite = _favorites.contains(
                                  docs[i].id,
                                );
                                return GestureDetector(
                                  onTap: () {
                                    // Analytics: log hostel view (scaffold)
                                    // FirebaseAnalytics.instance.logEvent(name: 'view_hostel', parameters: {'hostelId': docs[i].id});
                                    Navigator.pushNamed(
                                      context,
                                      '/hostel_detail',
                                      arguments: hostel,
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                          child: imageUrl != null
                                              ? Image.network(
                                                  imageUrl,
                                                  width: 90,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        progress,
                                                      ) {
                                                        if (progress == null) {
                                                          return child;
                                                        }
                                                        return Container(
                                                          width: 90,
                                                          height: 90,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stack,
                                                      ) => Container(
                                                        width: 90,
                                                        height: 90,
                                                        color: Colors.grey[300],
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons
                                                          .image_not_supported_outlined,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        hostel['name'] ?? '',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        isFavorite
                                                            ? Icons.favorite
                                                            : Icons
                                                                  .favorite_border,
                                                        color: isFavorite
                                                            ? Colors.red
                                                            : Colors.grey,
                                                        semanticLabel:
                                                            isFavorite
                                                            ? 'Remove from favorites'
                                                            : 'Add to favorites',
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (isFavorite) {
                                                            _favorites.remove(
                                                              docs[i].id,
                                                            );
                                                            // Remove from Firestore user favorites (scaffold)
                                                          } else {
                                                            _favorites.add(
                                                              docs[i].id,
                                                            );
                                                            // Add to Firestore user favorites (scaffold)
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    // Admin/manager tools (scaffold)
                                                    // if (isAdminOrManager) ...[
                                                    //   IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                                                    //   IconButton(icon: Icon(Icons.delete), onPressed: () {}),
                                                    // ]
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                if (hostel['rating'] != null)
                                                  Text(
                                                    '${hostel['rating']}',
                                                    style: TextStyle(
                                                      color: coffeeBrown,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                if (hostel['location'] != null)
                                                  Text(
                                                    hostel['location'],
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                if (hostel['min_price'] != null)
                                                  Text(
                                                    'UGX ${hostel['min_price']}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_hasMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ElevatedButton(
                                onPressed: _isLoadingMore
                                    ? null
                                    : () async {
                                        setState(() => _isLoadingMore = true);
                                        if (docs.isNotEmpty) {
                                          setState(() => _lastDoc = docs.last);
                                        } else {
                                          setState(() => _hasMore = false);
                                        }
                                        setState(() => _isLoadingMore = false);
                                        // Analytics: log load more (scaffold)
                                        // FirebaseAnalytics.instance.logEvent(name: 'load_more_hostels');
                                      },
                                child: _isLoadingMore
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Load More'),
                              ),
                            ),
                          if (!_hasMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No more results.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.brown[100],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: coffeeBrown,
        unselectedItemColor: lightCoffeeBrown,
        currentIndex: 0,
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.house_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
            icon: Icon(Icons.cases_rounded),
            label: "Documents",
          ),
        ],
      ),
    );
  }
}
