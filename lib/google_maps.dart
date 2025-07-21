import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Hostel {
  final String name;
  final double lat;
  final double lng;
  final String price;
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

  Hostel({
    required this.name,
    required this.lat,
    required this.lng,
    required this.price,
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
  });

  factory Hostel.fromFirestore(Map<String, dynamic> data) {
    return Hostel(
      name: data['name'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      price: data['price']?.toString() ?? '',
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
    );
  }
}

class GoogleMapsWidget extends StatefulWidget {
  const GoogleMapsWidget({super.key, this.height = 450, this.center, this.hostels});
  final double height;
  final LatLng? center;
  final List<Hostel>? hostels;

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  static const LatLng _defaultCenter = LatLng(0.3476, 32.5825); // Kampala, Uganda
  late CameraPosition _initialCameraPosition;
  GoogleMapController? _mapController;
  double _currentZoom = 14.0;
  Set<Marker> _markers = {};
  BitmapDescriptor? _hostelIcon;
  String? _mapStyle;
  List<Hostel> _hostels = [];
  bool _loading = true;
  late TextEditingController _searchController;
  String _searchQuery = '';
  MapType _mapType = MapType.normal;
  Set<String> _favoriteHostels = {};
  bool _locationDenied = false;
  double _userRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _submittingReview = false;

  List<Hostel> get _filteredHostels {
    if (_searchQuery.isEmpty) return _hostels;
    final query = _searchQuery.toLowerCase();
    return _hostels.where((hostel) {
      return hostel.name.toLowerCase().contains(query) ||
          hostel.price.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initialCameraPosition = CameraPosition(target: widget.center ?? _defaultCenter, zoom: 14.0);
    _loadCustomMarker();
    _loadMapStyle();
    _fetchHostels();
    _loadFavorites();
    _centerOnUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reviewController.dispose();
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
      final snapshot = await FirebaseFirestore.instance.collection('hostels').get();
      final hostels = snapshot.docs.map((doc) => Hostel.fromFirestore(doc.data())).toList();
      setState(() {
        _hostels = hostels;
        _loading = false;
      });
      _setMarkers();
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _loadCustomMarker() async {
    _hostelIcon = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    setState(() {});
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = '''
    [
      {"elementType": "geometry","stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.stroke","stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},
      {"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
      {"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
      {"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},
      {"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},
      {"featureType": "road","elementType": "geometry","stylers": [{"color": "#38414e"}]},
      {"featureType": "road","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},
      {"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},
      {"featureType": "road.highway","elementType": "geometry","stylers": [{"color": "#746855"}]},
      {"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},
      {"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},
      {"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},
      {"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
      {"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},
      {"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},
      {"featureType": "water","elementType": "labels.text.stroke","stylers": [{"color": "#17263c"}]}
    ]
    ''';
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
        setState(() { _locationDenied = true; });
        _showLocationDeniedMessage('Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationDenied = true; });
          _showLocationDeniedMessage('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _locationDenied = true; });
        _showLocationDeniedMessage('Location permission permanently denied.');
        return;
      }
      Position position = await Geolocator.getCurrentPosition();
      _initialCameraPosition = CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15.0);
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
      }
      setState(() {});
    } catch (e) {
      setState(() { _locationDenied = true; });
      _showLocationDeniedMessage('Failed to get location.');
    }
  }

  void _showLocationDeniedMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  void _setMarkers() {
    final markers = <Marker>{};
    for (final hostel in _filteredHostels) {
      BitmapDescriptor icon = _hostelIcon ?? BitmapDescriptor.defaultMarker;
      if (hostel.status != null) {
        if (hostel.status!.toLowerCase() == 'full') {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        } else if (hostel.status!.toLowerCase() == 'available') {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }
      }
      markers.add(Marker(
        markerId: MarkerId(hostel.name),
        position: LatLng(hostel.lat, hostel.lng),
        icon: icon,
        infoWindow: InfoWindow(
          title: hostel.name,
          snippet: hostel.price + (hostel.status != null ? ' (${hostel.status})' : ''),
          onTap: () => _showHostelDetails(hostel),
        ),
      ));
    }
    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_mapStyle != null) {
      controller.setMapStyle(_mapStyle);
    }
    _setMarkers();
    if (widget.center != null) {
      _moveCamera(widget.center!);
    }
  }

  Future<void> _moveCamera(LatLng target) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 15.0)));
    }
  }

  void _showHostelDetails(Hostel hostel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(hostel.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(_favoriteHostels.contains(hostel.name) ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                    onPressed: () => _toggleFavorite(hostel.name),
                  ),
                ],
              ),
              Text('Price: ${hostel.price}'),
              if (hostel.status != null) ...[
                const SizedBox(height: 4),
                Text('Status: ${hostel.status}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
              if (hostel.rating != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${hostel.rating!.toStringAsFixed(1)} / 5.0'),
                  ],
                ),
              ],
              if (hostel.reviews != null && hostel.reviews!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Reviews:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...hostel.reviews!.map((review) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text('- $review'),
                )),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.directions),
                label: Text('Get Directions'),
                onPressed: () => _openDirections(hostel.lat, hostel.lng, hostel.name),
              ),
              const SizedBox(height: 16),
              Text('Leave a Review:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: _userRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 28,
                itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    _userRating = rating;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  hintText: 'Write your review...',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submittingReview ? null : () => _submitReview(hostel),
                  child: _submittingReview ? CircularProgressIndicator() : Text('Submit Review'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Contact:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.phone, size: 18),
                  const SizedBox(width: 8),
                  hostel.contact != null && hostel.contact!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl('tel:${hostel.contact}'),
                          child: Text(hostel.contact!, style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Facebook:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.facebook, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  hostel.facebook != null && hostel.facebook!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl(hostel.facebook!),
                          child: Text('View Page', style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
              const SizedBox(height: 8),
              Text('WhatsApp:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.chat, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  hostel.whatsapp != null && hostel.whatsapp!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl('https://wa.me/${hostel.whatsapp}'),
                          child: Text('Chat on WhatsApp', style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
              const SizedBox(height: 8),
              Text('TikTok:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.music_note, size: 18, color: Colors.purple),
                  const SizedBox(width: 8),
                  hostel.tiktok != null && hostel.tiktok!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl(hostel.tiktok!),
                          child: Text('View TikTok', style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Instagram:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.camera_alt, size: 18, color: Colors.pink),
                  const SizedBox(width: 8),
                  hostel.instagram != null && hostel.instagram!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl(hostel.instagram!),
                          child: Text('View Instagram', style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Twitter/X:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.alternate_email, size: 18, color: Colors.lightBlue),
                  const SizedBox(width: 8),
                  hostel.twitter != null && hostel.twitter!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl(hostel.twitter!),
                          child: Text('View Twitter/X', style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.email, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  hostel.email != null && hostel.email!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl('mailto:${hostel.email!}'),
                          child: Text(hostel.email!, style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Website:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.language, size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  hostel.website != null && hostel.website!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _launchUrl(hostel.website!),
                          child: Text('Visit Website', style: TextStyle(color: Colors.blue)),
                        )
                      : Text('Not available'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating and review.')),
      );
      return;
    }
    setState(() { _submittingReview = true; });
    try {
      final doc = await FirebaseFirestore.instance.collection('hostels').where('name', isEqualTo: hostel.name).limit(1).get();
      if (doc.docs.isNotEmpty) {
        final docRef = doc.docs.first.reference;
        final data = doc.docs.first.data();
        final reviews = List<String>.from(data['reviews'] ?? []);
        final ratings = List<double>.from(data['ratings'] ?? []);
        reviews.add(reviewText);
        ratings.add(_userRating);
        final avgRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : _userRating;
        await docRef.update({
          'reviews': reviews,
          'ratings': ratings,
          'rating': avgRating,
        });
      }
      setState(() {
        _userRating = 0.0;
        _reviewController.clear();
        _submittingReview = false;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted!')),
      );
      _fetchHostels();
    } catch (e) {
      setState(() { _submittingReview = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review.')),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _setMarkers();
    });
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
    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    if (!(isWeb || isMobile)) {
      // Desktop fallback: show static image or message
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Interactive map is not supported on desktop.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('Please use the mobile app or web version for maps.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    // Show interactive map for web and mobile
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search hostels by name or price...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged();
                          },
                        )
                      : null,
                ),
                onChanged: (_) => _onSearchChanged(),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: ClipRRect(
                  child: GoogleMap(
                    initialCameraPosition: _initialCameraPosition,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: _onMapCreated,
                    onCameraMove: (position) {
                      _currentZoom = position.zoom;
                    },
                     mapType: _mapType,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_loading)
          Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          top: 24,
          right: 24,
          child: FloatingActionButton(
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
            child: Icon(Icons.layers),
            tooltip: 'Toggle Map Type',
          ),
        ),
        Positioned(
          top: 24,
          left: 24,
          child: FloatingActionButton(
            heroTag: 'centerOnUser',
            mini: true,
            onPressed: _centerOnUser,
            child: Icon(Icons.my_location),
            tooltip: 'Center on User Location',
          ),
        ),
      ],
    );
  }
}