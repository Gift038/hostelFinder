import 'package:flutter/material.dart';
import '../../widgets/hostel_card.dart';
import '../../widgets/hostel_list_tile.dart';
import '../tenant_dashboard/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../tenant_dashboard/payment_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

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
  bool _loadingSearch = false;
  List<Map<String, dynamic>> _searchResults = [];

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
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(),
          ),
        );
        break;
      case 3:
        Navigator.pushNamed(context, '/tenant_documents');
        break;
    }
  }

  Future<List<Map<String, dynamic>>> _loadHostels() async {
    try {
      // Try Firestore first
      final snapshot = await FirebaseFirestore.instance.collection('hostels').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (_) {}
    // Fallback to JSON
    final String jsonString = await rootBundle.loadString('assets/hostels_updated.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _loadHostelsFromFirestore(String query) async {
    final snapshot = await FirebaseFirestore.instance.collection('hostels').get();
    final hostels = snapshot.docs.map((doc) => doc.data()).toList();
    final lowerQuery = query.toLowerCase();
    return hostels.where((hostel) {
      final name = (hostel['name'] ?? '').toString().toLowerCase();
      final location = (hostel['location'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery) || location.contains(lowerQuery);
    }).toList();
  }

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
        _searchQuery = query;
        _loadingSearch = true;
      });
      _searchController.clear();
      final filtered = await _loadHostelsFromFirestore(query);
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

  void _handleUniversitySearch() {
    final university = _universityController.text.trim();
    if (university.isNotEmpty) {
      setState(() {
        _selectedUniversity = university;
      });
      _universityController.clear();
    }
  }

  void _clearUniversitySearch() {
    setState(() {
      _selectedUniversity = '';
    });
    _universityController.clear();
  }

  Widget _buildMapCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: _selectedUniversity.isNotEmpty
            ? _buildUniversityMapContent()
            : _buildDefaultMapContent(),
      ),
    );
  }

  Widget _buildDefaultMapContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.map,
          size: 64,
          color: coffeeBrown,
        ),
        const SizedBox(height: 16),
        Text(
          'Google Maps',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: coffeeBrown,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Interactive map will be displayed here',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUniversityMapContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: coffeeBrown.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: coffeeBrown),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedUniversity,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: coffeeBrown,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearUniversitySearch,
                child: Icon(Icons.close, color: coffeeBrown),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.map, size: 32, color: coffeeBrown),
                    const SizedBox(width: 8),
                    Text(
                      'University Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: coffeeBrown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, color: coffeeBrown, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Map showing $_selectedUniversity',
                          style: TextStyle(
                            color: coffeeBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nearby Hostels:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: coffeeBrown,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNearbyHostelItem('Student Hub', '0.5 km away', 'UGX 500,000'),
                        _buildNearbyHostelItem('Campus Living', '0.8 km away', 'UGX 400,000'),
                        _buildNearbyHostelItem('University Residence', '1.2 km away', 'UGX 550,000'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyHostelItem(String name, String distance, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: coffeeBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.home, color: coffeeBrown, size: 20),
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  distance,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: coffeeBrown,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                color: coffeeBrown.withOpacity(0.1),
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
                              'UGX ${hostel['min_price'] ?? hostel['price'] ?? ''}/month',
                              hostel['rating'] != null ? '${hostel['rating']} ★ (${hostel['reviews'] ?? 0} reviews)' : '',
                              (hostel['hostelImages'] != null && (hostel['hostelImages'] as List).isNotEmpty)
                                  ? hostel['hostelImages'][0]
                                  : (hostel['imageUrls'] != null && (hostel['imageUrls'] as List).isNotEmpty)
                                      ? hostel['imageUrls'][0]
                                      : '',
                              hostelId: hostel['id'] ?? hostel['docId'],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(String name, String location, String price, String rating, String imagePath, {String? hostelId}) {
    return GestureDetector(
      onTap: () {
        if (hostelId != null) {
          Navigator.pushNamed(
            context,
            '/virtual-tours',
            arguments: hostelId,
          );
        }
      },
      child: Container(
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
              child: imagePath.isNotEmpty
                  ? Image.network(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: Center(
                        child: Text('Image goes here', style: TextStyle(color: Colors.grey[700], fontSize: 10)),
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
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
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
              style: const TextStyle(
                color: Color(0xFF4B2E05),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: const Color(0xFF4B2E05),
      ),
      backgroundColor: const Color(0xFFF8F5F2),
      body: CustomScrollView(
        slivers: [
          // University Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: coffeeBrown.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: coffeeBrown.withOpacity(0.1),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: coffeeBrown.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: coffeeBrown.withOpacity(0.1),
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
                          hintText: _isSearching ? 'Search for more hostels...' : 'Search for hostels...',
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
                      onTap: _handleSearch,
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
          _isSearching
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverToBoxAdapter(
                  child: SizedBox(
                    height: 150,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('hostels').limit(10).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text('Error loading hostels.'));
                        }
                        final hostels = snapshot.data!.docs;
                        return ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: hostels.length,
                          itemBuilder: (context, index) {
                            final hostel = hostels[index].data() as Map<String, dynamic>;
                            final images = (hostel['hostelImages'] ?? hostel['imageUrls'] ?? []) as List?;
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/virtual-tours',
                                  arguments: hostels[index].id,
                                );
                              },
                              child: HostelCard(
                                imagePath: (images != null && images.isNotEmpty) ? images[0] : '',
                                title: hostel['name'] ?? '',
                                subtitle: hostel['location'] ?? '',
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMapCard(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.brown[100],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: coffeeBrown,
        unselectedItemColor: lightCoffeeBrown,
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.house_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cases_rounded),
            label: "Documents",
          ),
        ],
      ),
    );
  }
}
