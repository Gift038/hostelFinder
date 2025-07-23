import 'package:flutter/material.dart';
import '../../widgets/hostel_card.dart';
import '../tenant_dashboard/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../tenant_dashboard/payment_history.dart';
import '../../google_maps.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../chat/conversations_screen.dart';
// ignore: duplicate_import
import '../../google_maps.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../tenant_dashboard/broadcast_messages_screen.dart';
import '../tenant_dashboard/submit_maintenance_screen.dart';
import '../tenant_dashboard/published_ads_screen.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TenantsDashboardScreen extends StatefulWidget {
  const TenantsDashboardScreen({super.key});

  @override
  State<TenantsDashboardScreen> createState() => _TenantsDashboardScreenState();
}

class _TenantsDashboardScreenState extends State<TenantsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final Color coffeeBrown = const Color(0xFF4B2E05);
  final Color lightCoffeeBrown = const Color(0xFF9C7A5F);

  late ScrollController _scrollController;
  late AnimationController _autoScrollController;
  late Animation<double> _scrollAnimation;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();

  int _currentIndex = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedUniversity = '';
  LatLng? _universityCenter;
  List<Hostel>? _filteredHostels;
  List<Map<String, dynamic>> _searchResults = [];
  bool _loadingSearch = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _autoScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _scrollAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _autoScrollController, curve: Curves.linear),
    );

    _autoScrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final value = _scrollAnimation.value;

      final scrollPos = value < 0.5
          ? (value * 2) * maxScroll
          : (1 - (value - 0.5) * 2) * maxScroll;

      _scrollController.jumpTo(scrollPos);
    });

    _autoScrollController.repeat();
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
      case 3:
        Navigator.pushNamed(context, '/tenant_documents');
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConversationsScreen()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BroadcastMessagesScreen(),
          ),
        );
        break;
      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubmitMaintenanceScreen(),
          ),
        );
        break;
      case 7:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublishedAdsScreen()),
        );
        break;
    }
  }

  Future<List<Map<String, dynamic>>> _loadHostels() async {
    try {
      // Try Firestore first
      final snapshot = await FirebaseFirestore.instance
          .collection('hostels')
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (_) {}
    // Fallback to JSON
    final String jsonString = await rootBundle.loadString(
      'assets/hostels_updated.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  void _handleSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
        _searchQuery = query;
        _loadingSearch = true;
      });
      _searchController.clear();
      final hostels = await _loadHostels();
      final filtered = hostels.where((hostel) {
        final name = (hostel['name'] ?? '').toString().toLowerCase();
        final location = (hostel['location'] ?? '').toString().toLowerCase();
        return name.contains(query) || location.contains(query);
      }).toList();
      setState(() {
        _searchResults = filtered;
        _loadingSearch = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
    });
  }

  void _handleUniversitySearch() async {
    final university = _universityController.text.trim();
    if (university.isNotEmpty) {
      setState(() {
        _selectedUniversity = university;
      });
      _universityController.clear();
      // Geocode university
      try {
        List<Location> locations = await locationFromAddress(university);
        if (locations.isNotEmpty) {
          final LatLng center = LatLng(
            locations[0].latitude,
            locations[0].longitude,
          );
          // Fetch all hostels from Firestore
          final snapshot = await FirebaseFirestore.instance
              .collection('hostels')
              .get();
          final allHostels = snapshot.docs
              .map((doc) => Hostel.fromFirestore(doc.data()))
              .toList();
          // Filter hostels within 2km
          final filtered = allHostels.where((hostel) {
            final d = Geolocator.distanceBetween(
              hostel.lat,
              hostel.lng,
              center.latitude,
              center.longitude,
            );
            return d <= 2000;
          }).toList();
          setState(() {
            _universityCenter = center;
            _filteredHostels = filtered;
          });
        } else {
          setState(() {
            _universityCenter = null;
            _filteredHostels = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('University not found.')),
          );
        }
      } catch (e) {
        setState(() {
          _universityCenter = null;
          _filteredHostels = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('University not found.')));
      }
    }
  }

  void _clearUniversitySearch() {
    setState(() {
      _selectedUniversity = '';
    });
    _universityController.clear();
  }

  Widget _buildMapCard() {
    if (kIsWeb) {
      // Show a static image or placeholder for web
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 300,
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 64, color: coffeeBrown),
                const SizedBox(height: 16),
                Text(
                  'Map not supported on web',
                  style: TextStyle(fontSize: 18, color: coffeeBrown),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please use the mobile app for interactive maps.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.zero,
            child: GoogleMapsWidget(
              height: 450,
              center: _universityCenter,
              hostels: _filteredHostels,
            ),
          );
        } else {
          // Desktop platforms: show a static image or placeholder
          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.zero,
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: coffeeBrown),
                    const SizedBox(height: 16),
                    Text(
                      'Map not supported on desktop',
                      style: TextStyle(fontSize: 18, color: coffeeBrown),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please use the mobile app for interactive maps.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        // Platform not found (e.g., in tests)
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Center(child: Text('Map not supported on this platform')),
          ),
        );
      }
    }
  }

  Widget _buildSearchResultsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: coffeeBrown.withAlpha(25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: coffeeBrown),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search Results for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: coffeeBrown,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Icon(Icons.close, color: coffeeBrown),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingSearch
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? const Center(child: Text('No hostels found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final hostel = _searchResults[i];
                        return _buildSearchResultItem(
                          hostel['name'] ?? '',
                          hostel['location'] ?? '',
                          'UGX ${hostel['min_price'] ?? ''}/month',
                          hostel['rating'] != null
                              ? '${hostel['rating']} ★ (${hostel['reviews'] ?? 0} reviews)'
                              : '',
                          (hostel['hostelImages'] != null &&
                                  (hostel['hostelImages'] as List).isNotEmpty)
                              ? hostel['hostelImages'][0]
                              : '',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(
    String name,
    String location,
    String price,
    String rating,
    String imagePath,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: Center(
                child: Text(
                  'Image goes here',
                  style: TextStyle(color: Colors.grey[700], fontSize: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: coffeeBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      rating,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return Text(
              'Welcome, ${userProvider.name.isNotEmpty ? userProvider.name : 'Tenant'}',
              style: Theme.of(context).textTheme.titleLarge,
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return CustomScrollView(
            slivers: [
              // University Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: coffeeBrown.withAlpha(77)),
                      boxShadow: [
                        BoxShadow(
                          color: coffeeBrown.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _universityController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your destination university...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                            onSubmitted: (_) => _handleUniversitySearch(),
                          ),
                        ),
                        if (_selectedUniversity.isNotEmpty)
                          GestureDetector(
                            onTap: _clearUniversitySearch,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _handleUniversitySearch,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: coffeeBrown,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // General Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: coffeeBrown.withAlpha(77)),
                      boxShadow: [
                        BoxShadow(
                          color: coffeeBrown.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: _isSearching
                                  ? 'Search for more hostels...'
                                  : 'Search for hostels...',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                            onSubmitted: (_) => _handleSearch(),
                          ),
                        ),
                        if (_isSearching)
                          GestureDetector(
                            onTap: _clearSearch,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _handleSearch(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: coffeeBrown,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _isSearching
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildSearchResultsCard(),
                      ),
                    )
                  : SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hostel Listings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: coffeeBrown,
                          ),
                        ),
                      ),
                    ),
              // For hostel listings, use GridView for wide screens
              if (!_isSearching && isWide)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: 6, // Example for demo, replace with real data
                      itemBuilder: (context, index) => const HostelCard(
                        imagePath: 'assets/hostel1.jpg',
                        title: 'Modern Hostel',
                        subtitle: 'Near University',
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildMapCard(),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.house_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.payment), label: 'Payments'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(
            icon: Icon(Icons.cases_rounded),
            label: 'Documents',
          ),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(
            icon: Icon(Icons.campaign),
            label: 'Announcements',
          ),
          NavigationDestination(icon: Icon(Icons.build), label: 'Maintenance'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Browse Ads'),
        ],
      ),
    );
  }
}
