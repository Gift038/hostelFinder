import 'package:flutter/material.dart';
import '../../widgets/hostel_card.dart';
import '../../widgets/hostel_list_tile.dart';
import '../tenant_dashboard/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../tenant_dashboard/payment_history.dart';

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

  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tenant\'s Dashboard',
          style: const TextStyle(
            color: Color(0xFF4B2E05),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: const Color(0xFF4B2E05),
      ),
      backgroundColor: const Color(0xFFF8F5F2),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.brown[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search for hostels',
                    icon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
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
          SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/search_filter',
                        arguments: {'university': 'Makerere University'},
                      );
                    },
                    child: const HostelCard(
                      imagePath: 'assets/hostel1.jpg',
                      title: 'Makerere University Hostels',
                      subtitle: 'Find hostels near Makerere University',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/search_filter',
                        arguments: {'university': 'Kyambogo University'},
                      );
                    },
                    child: const HostelCard(
                      imagePath: 'assets/hostel2.jpg',
                      title: 'Kyambogo University Hostels',
                      subtitle: 'Find hostels near Kyambogo University',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/search_filter',
                        arguments: {'university': 'Uganda Christian University'},
                      );
                    },
                    child: const HostelCard(
                      imagePath: 'assets/hostel3.jpg',
                      title: 'Uganda Christian University Hostels',
                      subtitle: 'Find hostels near UCU',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/search_filter',
                        arguments: {'university': 'Victoria University'},
                      );
                    },
                    child: const HostelCard(
                      imagePath: 'assets/hostel5.jpg',
                      title: 'Victoria University Hostels',
                      subtitle: 'Find hostels near Victoria University',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/search_filter',
                        arguments: {'university': 'Ndejje University'},
                      );
                    },
                    child: const HostelCard(
                      imagePath: 'assets/hostel6.jpg',
                      title: 'Ndejje University Hostels',
                      subtitle: 'Find hostels near Ndejje University',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/search_filter',
                        arguments: {'university': 'Busitema University'},
                      );
                    },
                    child: const HostelCard(
                      imagePath: 'assets/hostel4.jpg',
                      title: 'Busitema University Hostels',
                      subtitle: 'Find hostels near Busitema University',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Section 1: Makerere University Hostels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Makerere University Hostels',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(121, 85, 72, 1),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hostels near Makerere University',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              HostelListTile(
                imagePath: 'assets/hostel1.jpg',
                name: 'The Student Hub',
                rating: 4.8,
                reviews: 120,
                price: 500000,
                details: 'Wandegeya',
                type: 'Gender Type: Mixed - Both female and male',
              ),
              HostelListTile(
                imagePath: 'assets/hostel2.jpg',
                name: 'Campus Living',
                rating: 4.6,
                reviews: 95,
                price: 400000,
                details: 'Kikoni',
                type: 'Gender Type: Single - Only Males',
              ),
              HostelListTile(
                imagePath: 'assets/hostel3.jpg',
                name: 'University Residence',
                rating: 4.5,
                reviews: 150,
                price: 550000,
                details: 'Makerere University',
                type: 'Gender Type: Single - Only Females',
              ),
              // Section 2: Victoria University Hostels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Victoria University Hostels',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hostels near Victoria University',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              HostelListTile(
                imagePath: 'assets/hostel1.jpg',
                name: 'Scholars Inn',
                rating: 4.9,
                reviews: 135,
                price: 600000,
                details: 'Victoria University',
                type: 'Gender Type: Mixed - Both female and male',
              ),
              HostelListTile(
                imagePath: 'assets/hostel4.jpeg',
                name: 'Academic Suites',
                rating: 4.7,
                reviews: 110,
                price: 700000,
                details: 'Victoria University',
                type: 'Gender Type: Single - Only Females',
              ),
              HostelListTile(
                imagePath: 'assets/hostel1.jpg',
                name: 'Victoria Residence',
                rating: 4.4,
                reviews: 90,
                price: 650000,
                details: 'Victoria University',
                type: 'Gender Type: Single - Only Males',
              ),
            ]),
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
