import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class Hostel {
  final String name;
  final double lat;
  final double lng;
  final String price;
  Hostel({required this.name, required this.lat, required this.lng, required this.price});

  factory Hostel.fromFirestore(Map<String, dynamic> data) {
    return Hostel(
      name: data['name'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      price: data['price']?.toString() ?? '',
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
  Set<Marker> _markers = {};
  BitmapDescriptor? _hostelIcon;
  String? _mapStyle;
  List<Hostel> _hostels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialCameraPosition = CameraPosition(target: widget.center ?? _defaultCenter, zoom: 14.0);
    _loadCustomMarker();
    _loadMapStyle();
    _fetchHostels();
    _centerOnUser();
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

  Future<void> _centerOnUser() async {
    if (widget.center != null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition();
      _initialCameraPosition = CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15.0);
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
      }
      setState(() {});
    } catch (e) {
      // Ignore and use default
    }
  }

  void _setMarkers() {
    final markers = <Marker>{};
    for (final hostel in _hostels) {
      markers.add(Marker(
        markerId: MarkerId(hostel.name),
        position: LatLng(hostel.lat, hostel.lng),
        icon: _hostelIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: hostel.name, snippet: hostel.price),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }
} 