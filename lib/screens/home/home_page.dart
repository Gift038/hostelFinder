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
import 'package:provider/provider.dart';
import '../../main.dart';

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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _currentIndex = index;
    });

    if (userProvider.role.isEmpty) {
      // Show animated create account card
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Material(
              color: Colors.transparent,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                color: Colors.brown[100],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1, color: coffeeBrown, size: 56),
                      const SizedBox(height: 20),
                      Text(
                        'Create an Account',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: coffeeBrown),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You need to register as a Tenant or Manager to access the dashboard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17),
                      ),
                      const SizedBox(height: 28),
                      _AnimatedCreateAccountButton(coffeeBrown: coffeeBrown),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TenantsDashboardScreen()),
        );
        break;
      case 2:
        if (userProvider.role == 'Hostel Manager') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManagerDashboard()),
          );
        }
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

class _AnimatedCreateAccountButton extends StatefulWidget {
  final Color coffeeBrown;
  const _AnimatedCreateAccountButton({required this.coffeeBrown});

  @override
  State<_AnimatedCreateAccountButton> createState() => _AnimatedCreateAccountButtonState();
}

class _AnimatedCreateAccountButtonState extends State<_AnimatedCreateAccountButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.93);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (details) {
        _onTapUp(details);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterAccountScreen()),
        );
      },
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          decoration: BoxDecoration(
            color: widget.coffeeBrown,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.coffeeBrown.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
