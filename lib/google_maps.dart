import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' show sqrt, sin, cos, atan2, pi;

class ClusterItem {
  final LatLng position;
  final String id;
  final String title;
  final String snippet;
  final BitmapDescriptor icon;
  final bool isFavorite;

  ClusterItem({
    required this.position,
    required this.id,
    required this.title,
    required this.snippet,
    required this.icon,
    this.isFavorite = false,
  });
}

class Hostel {
  final String name;
  final double lat;
  final double lng;
  final String price;
  final String address;
  final String? contact;
  final String? facebook;
  final String? whatsapp;
  final String? tiktok;
  final String? instagram;
  final String? twitter;
  final String? email;
  final String? website;
  final String? status;
  final double? rating;
  final List<dynamic>? reviews;
  final List<String>? images;

  Hostel({
    required this.name,
    required this.lat,
    required this.lng,
    required this.price,
    required this.address,
    this.contact,
    this.facebook,
    this.whatsapp,
    this.tiktok,
    this.instagram,
    this.twitter,
    this.email,
    this.website,
    this.status,
    this.rating,
    this.reviews,
    this.images,
  });

  factory Hostel.fromFirestore(Map<String, dynamic> data) {
    return Hostel(
      name: data['name'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      price: data['price']?.toString() ?? '',
      address: data['address'] ?? '',
      contact: data['contact'],
      facebook: data['facebook'],
      whatsapp: data['whatsapp'],
      tiktok: data['tiktok'],
      instagram: data['instagram'],
      twitter: data['twitter'],
      email: data['email'],
      website: data['website'],
      status: data['status'],
      rating: (data['rating'] as num?)?.toDouble(),
      reviews: data['reviews'],
      images: List<String>.from(data['images'] ?? []),
    );
  }

  ClusterItem toClusterItem(BitmapDescriptor icon, bool isFavorite) {
    return ClusterItem(
      position: LatLng(lat, lng),
      id: name,
      title: name,
      snippet: price,
      icon: icon,
      isFavorite: isFavorite,
    );
  }
}

class FilterOptions {
  final RangeValues priceRange;
  final double? minRating;
  final Set<String> amenities;
  final String? status;
  final bool onlyFavorites;

  FilterOptions({
    required this.priceRange,
    this.minRating,
    required this.amenities,
    this.status,
    this.onlyFavorites = false,
  });
}

class GoogleMapsWidget extends StatefulWidget {
  const GoogleMapsWidget({
    super.key,
    this.height = 450,
    this.center,
    this.hostels,
  });
  final double height;
  final LatLng? center;
  final List<Hostel>? hostels;

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  static const LatLng _defaultCenter = LatLng(
    0.3476,
    32.5825,
  ); // Kampala, Uganda
  late CameraPosition _initialCameraPosition;
  GoogleMapController? _mapController;
  double _currentZoom = 14.0;
  Set<Marker> _markers = {};
  List<Hostel> _hostels = [];
  bool _loading = true;
  late TextEditingController _searchController;
  String _searchQuery = '';
  MapType _mapType = MapType.normal;
  Set<String> _favoriteHostels = {};
  double _userRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _submittingReview = false;

  BitmapDescriptor? _normalIcon;
  BitmapDescriptor? _favoriteIcon;
  BitmapDescriptor? _availableIcon;
  BitmapDescriptor? _fullIcon;
  bool _showOnlyFavorites = false;

  // Add theme variables
  bool _isDarkMode = false;
  static const String _lightMapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      }
    ]
  ''';

  static const String _darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#242f3e"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#242f3e"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#746855"}]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [{"color": "#263c3f"}]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#6b9a76"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#38414e"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#212a37"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#9ca5b3"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [{"color": "#746855"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#1f2835"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#f3d19c"}]
      },
      {
        "featureType": "transit",
        "elementType": "geometry",
        "stylers": [{"color": "#2f3948"}]
      },
      {
        "featureType": "transit.station",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#17263c"}]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#515c6d"}]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#17263c"}]
      }
    ]
  ''';

  List<Hostel> get _filteredHostels {
    if (_searchQuery.isEmpty &&
        !_filterOptions.onlyFavorites &&
        _filterOptions.minRating == null &&
        _filterOptions.status == null &&
        _filterOptions.amenities.isEmpty &&
        _filterOptions.priceRange.start == 0 &&
        _filterOptions.priceRange.end == 1000000) {
      return _hostels;
    }

    return _hostels.where((hostel) {
      // Apply text search filter
      final query = _searchQuery.toLowerCase();
      if (query.isNotEmpty &&
          !hostel.name.toLowerCase().contains(query) &&
          !hostel.price.toLowerCase().contains(query)) {
        return false;
      }

      // Apply price range filter
      final price =
          double.tryParse(hostel.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      if (price < _filterOptions.priceRange.start ||
          price > _filterOptions.priceRange.end) {
        return false;
      }

      // Apply rating filter
      if (_filterOptions.minRating != null &&
          (hostel.rating == null ||
              hostel.rating! < _filterOptions.minRating!)) {
        return false;
      }

      // Apply status filter
      if (_filterOptions.status != null &&
          (hostel.status == null ||
              hostel.status!.toLowerCase() != _filterOptions.status)) {
        return false;
      }

      // Apply favorites filter
      if (_filterOptions.onlyFavorites &&
          !_favoriteHostels.contains(hostel.name)) {
        return false;
      }

      // Note: This assumes you'll add an amenities field to your Hostel class
      // if (_filterOptions.amenities.isNotEmpty) {
      //   final hostelAmenities = hostel.amenities ?? [];
      //   if (!_filterOptions.amenities.every((amenity) => hostelAmenities.contains(amenity))) {
      //     return false;
      //   }
      // }

      return true;
    }).toList();
  }

  List<ClusterItem> _items = [];
  final double _clusterZoom = 14.0;

  FilterOptions _filterOptions = FilterOptions(
    priceRange: const RangeValues(0, 1000000), // Set your max price accordingly
    amenities: {},
    onlyFavorites: false,
  );

  final List<String> _availableAmenities = [
    'Wi-Fi',
    'Parking',
    'Kitchen',
    'Laundry',
    'Air Conditioning',
    'Security',
    'Common Room',
    '24/7 Reception',
  ];

  // Add measurement state variables
  bool _isMeasuring = false;
  final List<LatLng> _measurePoints = [];
  final Set<Polyline> _measureLines = {};
  final Set<Marker> _measureMarkers = {};
  double _totalDistance = 0.0;
  final Map<String, double> _hostelDistances = {};

  // Add search history variables
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;
  final int _maxHistoryItems = 10;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initialCameraPosition = CameraPosition(
      target: widget.center ?? _defaultCenter,
      zoom: 14.0,
    );
    _loadCustomMarkers();
    _loadMapStyle();
    _fetchHostels();
    _loadFavorites();
    _centerOnUser();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _reviewController.dispose();
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GoogleMapsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != null && widget.center != oldWidget.center) {
      _moveCamera(widget.center!);
    }
    if (widget.hostels != null && widget.hostels != oldWidget.hostels) {
      _hostels = widget.hostels!;
      _setMarkers();
    }
  }

  Future<void> _fetchHostels() async {
    if (widget.hostels != null) {
      setState(() {
        _hostels = widget.hostels!;
        _loading = false;
      });
      _setMarkers();
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hostels')
          .get();
      final hostels = snapshot.docs
          .map((doc) => Hostel.fromFirestore(doc.data()))
          .toList();
      setState(() {
        _hostels = hostels;
        _loading = false;
      });
      _setMarkers();
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      // Normal hostel marker (blue)
      _normalIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );

      // Favorite hostel marker (yellow)
      _favoriteIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueYellow,
      );

      // Available hostel marker (green)
      _availableIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );

      // Full hostel marker (red)
      _fullIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );

      setState(() {});
    } catch (e) {
      debugPrint('Error loading markers: $e');
      // Use default markers as fallback
      _normalIcon = BitmapDescriptor.defaultMarker;
      _favoriteIcon = BitmapDescriptor.defaultMarker;
      _availableIcon = BitmapDescriptor.defaultMarker;
      _fullIcon = BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _loadMapStyle() async {
    _updateMapTheme();
  }

  void _updateMapTheme() {
    if (mounted) {
      final isDark =
          MediaQuery.of(context).platformBrightness == Brightness.dark;
      if (isDark != _isDarkMode) {
        setState(() {
          _isDarkMode = isDark;
        });
      }
    }
  }

  void _toggleMapTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteHostels = prefs.getStringList('favoriteHostels')?.toSet() ?? {};
    });
  }

  Future<void> _toggleFavorite(String hostelName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteHostels.contains(hostelName)) {
        _favoriteHostels.remove(hostelName);
      } else {
        _favoriteHostels.add(hostelName);
      }
      prefs.setStringList('favoriteHostels', _favoriteHostels.toList());
    });
  }

  Future<void> _centerOnUser() async {
    if (widget.center != null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDeniedMessage('Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDeniedMessage('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationDeniedMessage('Location permission permanently denied.');
        return;
      }
      Position position = await Geolocator.getCurrentPosition();
      _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15.0,
      );
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );
      }
      setState(() {});
    } catch (e) {
      _showLocationDeniedMessage('Failed to get location.');
    }
  }

  void _showLocationDeniedMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _setMarkers() {
    final markers = <Marker>{};
    for (final item in _items) {
      markers.add(
        Marker(
          markerId: MarkerId(item.id),
          position: item.position,
          icon: item.icon,
          infoWindow: InfoWindow(
            title: item.title,
            snippet: item.snippet,
            onTap: () {
              final hostel = _hostels.firstWhere((h) => h.name == item.id);
              _showHostelDetails(hostel);
            },
          ),
        ),
      );
    }
    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapTheme();
    _setMarkers();
    if (widget.center != null) {
      _moveCamera(widget.center!);
    }
  }

  Future<void> _moveCamera(LatLng target) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15.0),
        ),
      );
    }
  }

  void _showHostelDetails(Hostel hostel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Image Gallery at the top
              if (hostel.images != null && hostel.images!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: _ImageGallery(
                    images: hostel.images!,
                    hostelName: hostel.name,
                  ),
                ),
              // Rest of the details in a scrollable container
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header with name and favorite button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hostel.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hostel.status != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            hostel.status?.toLowerCase() ==
                                                'available'
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        hostel.status!,
                                        style: TextStyle(
                                          color:
                                              hostel.status?.toLowerCase() ==
                                                  'available'
                                              ? Colors.green[900]
                                              : Colors.red[900],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _favoriteHostels.contains(hostel.name)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () => _toggleFavorite(hostel.name),
                            ),
                          ],
                        ),
                      ),
                      // Price and Rating section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                hostel.price,
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (hostel.rating != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hostel.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Location and Directions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hostel.address,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.directions),
                                label: const Text('Get Directions'),
                                onPressed: () => _openDirections(
                                  hostel.lat,
                                  hostel.lng,
                                  hostel.name,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 32),
                      // Contact Options
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (hostel.contact != null &&
                                hostel.contact!.isNotEmpty)
                              ListTile(
                                leading: const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                ),
                                title: Text(hostel.contact!),
                                trailing: const Icon(Icons.call),
                                onTap: () =>
                                    _launchUrl('tel:${hostel.contact}'),
                              ),
                            if (hostel.email != null &&
                                hostel.email!.isNotEmpty)
                              ListTile(
                                leading: const Icon(
                                  Icons.email,
                                  color: Colors.red,
                                ),
                                title: Text(hostel.email!),
                                trailing: const Icon(Icons.send),
                                onTap: () =>
                                    _launchUrl('mailto:${hostel.email}'),
                              ),
                            if (hostel.whatsapp != null &&
                                hostel.whatsapp!.isNotEmpty)
                              ListTile(
                                leading: Icon(
                                  Icons.message,
                                  color: Colors.green,
                                ),
                                title: const Text('WhatsApp'),
                                trailing: const Icon(Icons.chat),
                                onTap: () => _launchUrl(
                                  'https://wa.me/${hostel.whatsapp}',
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 32),
                      // Social Media Links
                      if (_hasSocialMedia(hostel))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Social Media',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  if (hostel.facebook != null &&
                                      hostel.facebook!.isNotEmpty)
                                    _SocialButton(
                                      icon: Icons.facebook,
                                      label: 'Facebook',
                                      color: Colors.blue,
                                      onTap: () => _launchUrl(hostel.facebook!),
                                    ),
                                  if (hostel.instagram != null &&
                                      hostel.instagram!.isNotEmpty)
                                    _SocialButton(
                                      icon: Icons.camera_alt,
                                      label: 'Instagram',
                                      color: Colors.purple,
                                      onTap: () =>
                                          _launchUrl(hostel.instagram!),
                                    ),
                                  if (hostel.twitter != null &&
                                      hostel.twitter!.isNotEmpty)
                                    _SocialButton(
                                      icon: Icons.alternate_email,
                                      label: 'Twitter',
                                      color: Colors.lightBlue,
                                      onTap: () => _launchUrl(hostel.twitter!),
                                    ),
                                  if (hostel.website != null &&
                                      hostel.website!.isNotEmpty)
                                    _SocialButton(
                                      icon: Icons.language,
                                      label: 'Website',
                                      color: Colors.teal,
                                      onTap: () => _launchUrl(hostel.website!),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 32),
                      // Reviews Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (hostel.reviews != null &&
                                hostel.reviews!.isNotEmpty) ...[
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: hostel.reviews!.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(hostel.reviews![index]),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            const Text(
                              'Add Your Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RatingBar.builder(
                              initialRating: _userRating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 28,
                              itemBuilder: (context, _) =>
                                  const Icon(Icons.star, color: Colors.amber),
                              onRatingUpdate: (rating) {
                                setState(() {
                                  _userRating = rating;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _reviewController,
                              decoration: const InputDecoration(
                                hintText: 'Write your review...',
                                border: OutlineInputBorder(),
                              ),
                              minLines: 3,
                              maxLines: 5,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submittingReview
                                    ? null
                                    : () => _submitReview(hostel),
                                child: _submittingReview
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Submit Review'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasSocialMedia(Hostel hostel) {
    return (hostel.facebook != null && hostel.facebook!.isNotEmpty) ||
        (hostel.instagram != null && hostel.instagram!.isNotEmpty) ||
        (hostel.twitter != null && hostel.twitter!.isNotEmpty) ||
        (hostel.website != null && hostel.website!.isNotEmpty);
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openDirections(double lat, double lng, String name) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _submitReview(Hostel hostel) async {
    final reviewText = _reviewController.text.trim();
    if (_userRating == 0.0 || reviewText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating and review.')),
      );
      return;
    }

    // Capture context-dependent variables before the async gap.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _submittingReview = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('hostels')
          .where('name', isEqualTo: hostel.name)
          .limit(1)
          .get();

      if (!mounted) return;

      if (doc.docs.isNotEmpty) {
        final docRef = doc.docs.first.reference;
        final data = doc.docs.first.data();
        final reviews = List<String>.from(data['reviews'] ?? []);
        final ratings = List<double>.from(data['ratings'] ?? []);
        reviews.add(reviewText);
        ratings.add(_userRating);
        final avgRating = ratings.isNotEmpty
            ? ratings.reduce((a, b) => a + b) / ratings.length
            : _userRating;
        await docRef.update({
          'reviews': reviews,
          'ratings': ratings,
          'rating': avgRating,
        });
      }

      if (!mounted) return;

      setState(() {
        _userRating = 0.0;
        _reviewController.clear();
        _submittingReview = false;
      });

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Review submitted!')),
      );
      _fetchHostels();
    } catch (e) {
      if (mounted) {
        setState(() {
          _submittingReview = false;
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to submit review.')),
        );
      }
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _showSuggestions = false;
          _searchSuggestions = [];
        } else {
          _showSuggestions = true;
          _updateSearchSuggestions(query);
        }
        _updateFilteredHostels();
      });
    });
  }

  void _updateSearchSuggestions(String query) {
   if (query.isEmpty) {
      _searchSuggestions = [];
      return;
   }

    // Combine history matches and hostel matches
    final Set<String> suggestions = {};

    // Add matching items from search history
    suggestions.addAll(
      _searchHistory.where((item) => item.toLowerCase().contains(query)),
    );

    // Add matching hostel names
    suggestions.addAll(
      _hostels
          .where(
            (hostel) =>
                hostel.name.toLowerCase().contains(query) ||
                hostel.price.toLowerCase().contains(query),
          )
          .map((hostel) => hostel.name),
    );

    // Add matching amenities or features
    final commonFeatures = [
      'Wi-Fi',
      'Parking',
      'Kitchen',
      'Laundry',
      'Air Conditioning',
      'Security',
      '24/7 Reception',
    ];
    suggestions.addAll(
      commonFeatures.where((feature) => feature.toLowerCase().contains(query)),
    );

    setState(() {
      _searchSuggestions = suggestions.take(5).toList();
    });
  }

  void _onSuggestionTapped(String suggestion) {
    setState(() {
      _searchController.text = suggestion;
      _searchQuery = suggestion;
      _showSuggestions = false;
      _addToSearchHistory(suggestion);
      _updateFilteredHostels();
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;

    setState(() {
      // Remove if exists (to move it to top)
      _searchHistory.remove(query);
      // Add to beginning of list
      _searchHistory.insert(0, query);
      // Keep only last N items
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory.removeLast();
      }
    });
    _saveSearchHistory();
  }

  void _removeFromSearchHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
    _saveSearchHistory();
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }

  void _updateClusterItems() async {
    final items = <ClusterItem>[];
    for (final hostel in _filteredHostels) {
      BitmapDescriptor icon;

      // Determine the appropriate icon based on favorite status and availability
      if (_favoriteHostels.contains(hostel.name)) {
        icon = _favoriteIcon ?? BitmapDescriptor.defaultMarker;
      } else if (hostel.status != null) {
        if (hostel.status!.toLowerCase() == 'full') {
          icon = _fullIcon ?? BitmapDescriptor.defaultMarker;
        } else if (hostel.status!.toLowerCase() == 'available') {
          icon = _availableIcon ?? BitmapDescriptor.defaultMarker;
        } else {
          icon = _normalIcon ?? BitmapDescriptor.defaultMarker;
        }
      } else {
        icon = _normalIcon ?? BitmapDescriptor.defaultMarker;
      }

      items.add(
        hostel.toClusterItem(icon, _favoriteHostels.contains(hostel.name)),
      );
    }

    setState(() {
      _items = items;
      _setMarkers();
    });
  }

  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
    if (_currentZoom <= _clusterZoom) {
      // When zoomed out, group nearby markers into clusters
      _updateClusters();
    } else {
      // When zoomed in, show individual markers
      _setMarkers();
    }
  }

  void _updateClusters() {
    final clusters = <Marker>{};
    final processed = <String>{};

    for (var i = 0; i < _items.length; i++) {
      if (processed.contains(_items[i].id)) continue;

      final nearbyMarkers = <ClusterItem>[_items[i]];
      processed.add(_items[i].id);

      // Find nearby markers within clustering distance
      for (var j = i + 1; j < _items.length; j++) {
        if (processed.contains(_items[j].id)) continue;

        final distance = _calculateHaversineDistance(
          _items[i].position,
          _items[j].position,
        );

        // If markers are within 100 meters, cluster them
        if (distance <= 100) {
          nearbyMarkers.add(_items[j]);
          processed.add(_items[j].id);
        }
      }

      if (nearbyMarkers.length == 1) {
        // Single marker, no clustering needed
        clusters.add(
          Marker(
            markerId: MarkerId(nearbyMarkers[0].id),
            position: nearbyMarkers[0].position,
            icon: nearbyMarkers[0].icon,
            infoWindow: InfoWindow(
              title: nearbyMarkers[0].title,
              snippet: nearbyMarkers[0].snippet,
            ),
          ),
        );
      } else {
        // Create a cluster marker
        final center = _calculateClusterCenter(nearbyMarkers);
        clusters.add(
          Marker(
            markerId: MarkerId('cluster_$i'),
            position: center,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: '${nearbyMarkers.length} Hostels',
              snippet: 'Zoom in to see details',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = clusters;
    });
  }

  LatLng _calculateClusterCenter(List<ClusterItem> items) {
    double lat = 0;
    double lng = 0;
    for (final item in items) {
      lat += item.position.latitude;
      lng += item.position.longitude;
    }
    return LatLng(lat / items.length, lng / items.length);
  }


  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Hostels',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterOptions = FilterOptions(
                            priceRange: const RangeValues(0, 1000000),
                            amenities: {},
                            onlyFavorites: false,
                          );
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Price Range:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RangeSlider(
                  values: _filterOptions.priceRange,
                  min: 0,
                  max: 1000000, // Adjust based on your price range
                  divisions: 100,
                  labels: RangeLabels(
                    _filterOptions.priceRange.start.round().toString(),
                    _filterOptions.priceRange.end.round().toString(),
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _filterOptions = FilterOptions(
                        priceRange: values,
                        minRating: _filterOptions.minRating,
                        amenities: _filterOptions.amenities,
                        status: _filterOptions.status,
                        onlyFavorites: _filterOptions.onlyFavorites,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Minimum Rating:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RatingBar.builder(
                  initialRating: _filterOptions.minRating ?? 0,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 28,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _filterOptions = FilterOptions(
                        priceRange: _filterOptions.priceRange,
                        minRating: rating > 0 ? rating : null,
                        amenities: _filterOptions.amenities,
                        status: _filterOptions.status,
                        onlyFavorites: _filterOptions.onlyFavorites,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _filterOptions.status,
                  hint: const Text('Any Status'),
                  isExpanded: true,
                  items: <String>['Any Status', 'Available', 'Full']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value == 'Any Status'
                              ? null
                              : value.toLowerCase(),
                          child: Text(value),
                        );
                      })
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _filterOptions = FilterOptions(
                        priceRange: _filterOptions.priceRange,
                        minRating: _filterOptions.minRating,
                        amenities: _filterOptions.amenities,
                        status: value == 'Any Status' ? null : value,
                        onlyFavorites: _filterOptions.onlyFavorites,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Amenities:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: _availableAmenities.map((amenity) {
                    final isSelected = _filterOptions.amenities.contains(
                      amenity,
                    );
                    return FilterChip(
                      label: Text(amenity),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          final newAmenities = Set<String>.from(
                            _filterOptions.amenities,
                          );
                          if (selected) {
                            newAmenities.add(amenity);
                          } else {
                            newAmenities.remove(amenity);
                          }
                          _filterOptions = FilterOptions(
                            priceRange: _filterOptions.priceRange,
                            minRating: _filterOptions.minRating,
                            amenities: newAmenities,
                            status: _filterOptions.status,
                            onlyFavorites: _filterOptions.onlyFavorites,
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show Only Favorites'),
                  value: _filterOptions.onlyFavorites,
                  onChanged: (bool value) {
                    setState(() {
                      _filterOptions = FilterOptions(
                        priceRange: _filterOptions.priceRange,
                        minRating: _filterOptions.minRating,
                        amenities: _filterOptions.amenities,
                        status: _filterOptions.status,
                        onlyFavorites: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text;
      _updateClusterItems();
    });
  }

  void _toggleMeasurement() {
    setState(() {
      _isMeasuring = !_isMeasuring;
      if (!_isMeasuring) {
        // Clear measurement data when turning off
        _measurePoints.clear();
        _measureLines.clear();
        _measureMarkers.clear();
        _totalDistance = 0.0;
      }
    });
  }

  double _calculateHaversineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // Earth's radius in meters

    // Convert to radians
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLat = (end.latitude - start.latitude) * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;

    // Haversine formula
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in meters
  }

  void _onMapTap(LatLng position) {
    if (!_isMeasuring) return;

    setState(() {
      _measurePoints.add(position);

      // Add marker for the point
      _measureMarkers.add(
        Marker(
          markerId: MarkerId('measure_${_measurePoints.length}'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: 'Point ${_measurePoints.length}',
            snippet: _measurePoints.length > 1
                ? 'Total Distance: ${_formatDistance(_totalDistance)}'
                : 'Tap to add another point',
          ),
        ),
      );

      // If we have at least 2 points, draw a line and calculate distance
      if (_measurePoints.length >= 2) {
        final start = _measurePoints[_measurePoints.length - 2];
        final end = _measurePoints[_measurePoints.length - 1];

        _measureLines.add(
          Polyline(
            polylineId: PolylineId('measure_${_measureLines.length}'),
            points: [start, end],
            color: Colors.purple,
            width: 3,
            patterns: [PatternItem.dash(20.0), PatternItem.gap(10.0)],
          ),
        );

        _totalDistance += _calculateHaversineDistance(start, end);
      }
    });
  }

  void _showDistanceToHostels(LatLng userLocation) async {
    _hostelDistances.clear();

    for (final hostel in _filteredHostels) {
      final distance = _calculateHaversineDistance(
        userLocation,
        LatLng(hostel.lat, hostel.lng),
      );
      _hostelDistances[hostel.name] = distance;
    }

    // Sort hostels by distance
    final sortedHostels = _filteredHostels.toList()
      ..sort(
        (a, b) => (_hostelDistances[a.name] ?? double.infinity).compareTo(
          _hostelDistances[b.name] ?? double.infinity,
        ),
      );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearest Hostels',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedHostels.length,
                itemBuilder: (context, index) {
                  final hostel = sortedHostels[index];
                  final distance = _hostelDistances[hostel.name] ?? 0;
                  final walkTime = _getEstimatedTime(distance, 'walking');
                  final driveTime = _getEstimatedTime(distance, 'driving');
                  return ListTile(
                    title: Text(hostel.name),
                    subtitle: Text(
                      '${_formatDistance(distance)}\n'
                      '🚶 $walkTime • 🚗 $driveTime',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.directions),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openDirections(
                          hostel.lat,
                          hostel.lng,
                          hostel.name,
                        );
                      },
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

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    }
  }

  String _getEstimatedTime(double distanceInMeters, String mode) {
    // Average speeds (meters per minute)
    const walkingSpeed = 83.3; // 5 km/h
    const drivingSpeed = 500; // 30 km/h

    final speed = mode == 'walking' ? walkingSpeed : drivingSpeed;
    final minutes = (distanceInMeters / speed).round();

    if (minutes < 60) {
      return '$minutes mins';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMins = minutes % 60;
      return '${hours}h ${remainingMins}m';
    }
  }

  void _updateFilteredHostels() {
    setState(() {
      _setMarkers();
      if (_mapController != null && _filteredHostels.isNotEmpty) {
        // Adjust map bounds to show all filtered hostels
        final bounds = _calculateBounds(_filteredHostels);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0), // 50.0 is padding
        );
      }
    });
  }

  LatLngBounds _calculateBounds(List<Hostel> hostels) {
    if (hostels.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = hostels[0].lat;
    double maxLat = hostels[0].lat;
    double minLng = hostels[0].lng;
    double maxLng = hostels[0].lng;

    for (final hostel in hostels) {
      if (hostel.lat < minLat) minLat = hostel.lat;
      if (hostel.lat > maxLat) maxLat = hostel.lat;
      if (hostel.lng < minLng) minLng = hostel.lng;
      if (hostel.lng > maxLng) maxLng = hostel.lng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final isWeb = kIsWeb;
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!(isWeb || isMobile)) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Interactive map is not supported on desktop.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Please use the mobile app or web version for maps.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final favoriteCount = _filteredHostels
        .where((h) => _favoriteHostels.contains(h.name))
        .length;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search hostels by name, price, or features...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _showSuggestions = false;
                                            _updateFilteredHostels();
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.history),
                                        onPressed: () {
                                          setState(() {
                                            _showSuggestions = true;
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => _onSearchChanged(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterPanel,
                        tooltip: 'Filter Options',
                      ),
                    ],
                  ),
                  if (_showSuggestions) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchSuggestions.isNotEmpty)
                            ...List.generate(
                              _searchSuggestions.length,
                              (index) => ListTile(
                                leading: Icon(
                                  _searchHistory.contains(
                                        _searchSuggestions[index],
                                      )
                                      ? Icons.history
                                      : Icons.search,
                                  color: Colors.grey,
                                ),
                                title: Text(_searchSuggestions[index]),
                                onTap: () => _onSuggestionTapped(
                                  _searchSuggestions[index],
                                ),
                              ),
                            )
                          else if (_searchHistory.isNotEmpty)
                            ...List.generate(
                              _searchHistory.length.clamp(0, 3),
                              (index) => ListTile(
                                leading: const Icon(
                                  Icons.history,
                                  color: Colors.grey,
                                ),
                                title: Text(_searchHistory[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => _removeFromSearchHistory(
                                    _searchHistory[index],
                                  ),
                                ),
                                onTap: () =>
                                    _onSuggestionTapped(_searchHistory[index]),
                              ),
                            ),
                          if (_searchHistory.isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.delete_outline),
                              title: const Text('Clear Search History'),
                              onTap: _clearSearchHistory,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (favoriteCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '$favoriteCount favorite${favoriteCount == 1 ? '' : 's'} on map',
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: Icon(
                        _showOnlyFavorites
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 16,
                      ),
                      label: Text(
                        _showOnlyFavorites ? 'Show All' : 'Show Only Favorites',
                      ),
                      onPressed: () {
                        setState(() {
                          _showOnlyFavorites = !_showOnlyFavorites;
                          _filterOptions = FilterOptions(
                            priceRange: _filterOptions.priceRange,
                            minRating: _filterOptions.minRating,
                            amenities: _filterOptions.amenities,
                            status: _filterOptions.status,
                            onlyFavorites: _showOnlyFavorites,
                          );
                        });
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _initialCameraPosition,
                markers: {..._markers, ..._measureMarkers},
                polylines: _measureLines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onCameraMove: _onCameraMove,
                mapType: _mapType,
                onTap: _onMapTap,
                style: _isDarkMode ? _darkMapStyle : _lightMapStyle,
              ),
            ),
          ],
        ),
        Positioned(
          top: 24,
          right: 24,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'mapTypeToggle',
                mini: true,
                onPressed: () {
                  setState(() {
                    _mapType = _mapType == MapType.normal
                        ? MapType.satellite
                        : _mapType == MapType.satellite
                        ? MapType.terrain
                        : _mapType == MapType.terrain
                        ? MapType.hybrid
                        : MapType.normal;
                  });
                },
                tooltip: 'Toggle Map Type',
                child: Icon(Icons.layers),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'themeToggle',
                mini: true,
                onPressed: _toggleMapTheme,
                tooltip: _isDarkMode
                    ? 'Switch to Light Theme'
                    : 'Switch to Dark Theme',
                child: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              ),
              const SizedBox(height: 8),
              if (favoriteCount > 0)
                FloatingActionButton(
                  heroTag: 'toggleFavorites',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _showOnlyFavorites = !_showOnlyFavorites;
                      _filterOptions = FilterOptions(
                        priceRange: _filterOptions.priceRange,
                        minRating: _filterOptions.minRating,
                        amenities: _filterOptions.amenities,
                        status: _filterOptions.status,
                        onlyFavorites: _showOnlyFavorites,
                      );
                    });
                    _applyFilters();
                  },
                  tooltip: _showOnlyFavorites
                      ? 'Show All Hostels'
                      : 'Show Only Favorites',
                  backgroundColor: _showOnlyFavorites ? Colors.red : null,
                  child: Icon(
                    _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 24,
          left: 24,
          child: FloatingActionButton(
            heroTag: 'centerOnUser',
            mini: true,
            onPressed: _centerOnUser,
            tooltip: 'Center on User Location',
            child: Icon(Icons.my_location),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isMeasuring) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Distance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_formatDistance(_totalDistance)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add points',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FloatingActionButton(
                heroTag: 'measure',
                onPressed: _toggleMeasurement,
                tooltip: _isMeasuring
                    ? 'Cancel Measurement'
                    : 'Measure Distance',
                child: Icon(_isMeasuring ? Icons.close : Icons.straighten),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'nearestHostels',
                onPressed: () async {
                  // Capture the context before the async gap to show the snackbar.
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    final position = await Geolocator.getCurrentPosition();
                    if (mounted) {
                      _showDistanceToHostels(
                        LatLng(position.latitude, position.longitude),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Could not get current location'),
                        ),
                      );
                    }
                  }
                },
                tooltip: 'Show Nearest Hostels',
                child: const Icon(Icons.near_me),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(26),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add the _ImageGallery widget definition
class _ImageGallery extends StatefulWidget {
  final List<String> images;
  final String hostelName;

  const _ImageGallery({required this.images, required this.hostelName});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _pageController.animateToPage(
        _currentImageIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.images.length - 1) {
      _pageController.animateToPage(
        _currentImageIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.error)),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(77),
                            Colors.transparent,
                            Colors.black.withAlpha(77),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.images.length > 1) ...[
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(
                      _currentImageIndex == entry.key ? 230 : 102,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _previousImage,
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _nextImage,
            ),
          ),
        ],
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(widget.hostelName),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
