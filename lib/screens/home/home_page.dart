import 'package:flutter/material.dart';
import '../../widgets/hostel_card.dart';
import '../../widgets/service_card.dart';
import 'package:path_provider_android/messages.g.dart';
import 'tenants_dashboard.dart';
import 'managers_dashboard.dart';
import '../tenant_dashboard/notification_screen.dart';
import '../auth/register_account_screen.dart';
import 'sign_up_screen.dart';
import '../../screens/auth/register_account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final coffeeBrown = const Color(0xFF4B2E05);
  final lightCoffeeBrown = const Color(0xFF9C7A5F);

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
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManagerDashboard()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: false,
              centerTitle: true,
              title: Text(
                'HostelFinder',
                style: TextStyle(
                  color: coffeeBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                      color: coffeeBrown),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: ListView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  children: const [
                    HostelCard(
                      imagePath: 'assets/hostel1.jpg',
                      title: 'Makerere University Hostels',
                      subtitle: 'Find hostels near Makerere University',
                    ),
                    HostelCard(
                      imagePath: 'assets/hostel2.jpg',
                      title: 'Kyambogo University Hostels',
                      subtitle: 'Find hostels near Kyambogo University',
                    ),
                    HostelCard(
                      imagePath: 'assets/hostel3.jpg',
                      title: 'Uganda Christian University Hostels',
                      subtitle: 'Find hostels near UCU',
                    ),
                    HostelCard(
                      imagePath: 'assets/hostel1.jpg',
                      title: 'Busitema University Hostels',
                      subtitle: 'Find hostels near Busitema University',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'All Services',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: coffeeBrown),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ServiceCard(
                      icon: Icons.auto_awesome,
                      title: 'Smart Recommendations',
                      subtitle: 'Personalized hostel suggestions',
                      coffeeBrown: coffeeBrown,
                      lightCoffeeBrown: lightCoffeeBrown,
                    ),
                    SizedBox(height: 12),
                    ServiceCard(
                      icon: Icons.home_work,
                      title: 'Hostel Listings',
                      subtitle: 'Browse available hostels',
                      coffeeBrown: coffeeBrown,
                      lightCoffeeBrown: lightCoffeeBrown,
                    ),
                    SizedBox(height: 12),
                    ServiceCard(
                      icon: Icons.person,
                      title: 'Tenant Records',
                      subtitle: 'Manage tenant info',
                      coffeeBrown: coffeeBrown,
                      lightCoffeeBrown: lightCoffeeBrown,
                    ),
                    SizedBox(height: 12),
                    ServiceCard(
                      icon: Icons.build,
                      title: 'Maintenance Tracking',
                      subtitle: 'Track maintenance requests',
                      coffeeBrown: coffeeBrown,
                      lightCoffeeBrown: lightCoffeeBrown,
                    ),
                    SizedBox(height: 12),
                    ServiceCard(
                      icon: Icons.event_note,
                      title: 'Repair Scheduling',
                      subtitle: 'Schedule repairs',
                      coffeeBrown: coffeeBrown,
                      lightCoffeeBrown: lightCoffeeBrown,
                    ),
                    SizedBox(height: 12),
                    ServiceCard(
                      icon: Icons.announcement,
                      title: 'Announcements',
                      subtitle: 'Receive management updates',
                      coffeeBrown: coffeeBrown,
                      lightCoffeeBrown: lightCoffeeBrown,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Create Your Account',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: coffeeBrown),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up to access more features and manage your bookings easily.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: lightCoffeeBrown),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: coffeeBrown,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterAccountScreen()),
                          );
                        },
                        child: const Text('Create Account'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Tenant Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cases_rounded),
            label: "Manager Dashboard",
          ),
        ],
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
    );
  }
}
