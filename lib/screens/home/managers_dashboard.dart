import 'package:flutter/material.dart';
import '../manager_dashboard/addresident_screen.dart';
import '../manager_dashboard/notification_screen.dart' as manager;
import '../manager_dashboard/bookings_request.dart';
import '../manager_dashboard/maintenance_repair.dart';
import '../manager_dashboard/room_management_screen.dart';
import '../manager_dashboard/payments_screen.dart';
import '../manager_dashboard/manager_profile_screen.dart';
import '../manager_dashboard/add_hostel_screen.dart';
import '../chat/conversations_screen.dart';
import '../manager_dashboard/tenants_listening.dart';
import '../manager_dashboard/broadcast_screen.dart';
import '../manager_dashboard/analytics_screen.dart';
import '../manager_dashboard/publish_addscreen.dart';
import '../manager_dashboard/room_matching.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth
import '../manager_dashboard/view_documents_screen.dart';
import '../manager_dashboard/expenses_screen.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ManagerDashboard());
}

const Color coffeeBrown = Color(0xFF4B2E05);
const Color lightCoffeeBrown = Color(0xFF9C7A5F);
const Color dirtyBrownWhite = Color(0xFFFAF3E3);

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manager Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.brown,
        ).copyWith(secondary: coffeeBrown, surface: Colors.white),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: coffeeBrown,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeBrown,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const DashboardScreen(),
      routes: {
        '/room_management': (_) => const RoomManagementScreen(),
        '/maintenance': (_) => const MaintenanceRepairsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const PaymentsScreen(),
    const AddResidentScreen(),
    const manager.NotificationScreen(),
    const ManagerProfileScreen(),
    const ConversationsScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manager\'s Dashboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.payment), label: 'Payments'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Residents'),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
        ],
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final managerId = FirebaseAuth.instance.currentUser?.uid;
    if (managerId == null) {
      return {
        'occupancyRate': 0.0,
        'totalRevenue': 0.0,
        'averageRent': 0.0,
        'recentActivity': <ActivityItem>[],
        'paidPercentage': 0.0,
      };
    }

    // 1. Fetch all hostels managed by this manager to calculate room stats
    final hostelsSnapshot = await FirebaseFirestore.instance
        .collection('hostels')
        .where('managerId', isEqualTo: managerId)
        .get();

    int totalRooms = 0;
    int occupiedRooms = 0;
    if (hostelsSnapshot.docs.isNotEmpty) {
      for (final hostelDoc in hostelsSnapshot.docs) {
        final data = hostelDoc.data();
        totalRooms += (data['totalRooms'] as num?)?.toInt() ?? 0;
        occupiedRooms += (data['occupiedRooms'] as num?)?.toInt() ?? 0;
      }
    }

    // 2. Fetch this month's successful payments to calculate revenue
    double totalRevenue = 0.0;
    int successfulPayments = 0;
    final now = DateTime.now();
    final startOfMonth = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    final endOfMonth = Timestamp.fromDate(DateTime(now.year, now.month + 1, 0));

    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('managerId', isEqualTo: managerId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .get();

    for (final paymentDoc in paymentsSnapshot.docs) {
      final data = paymentDoc.data();
      if (data['status'] == 'Success') {
        totalRevenue += (data['amount'] as num?)?.toDouble() ?? 0.0;
        successfulPayments++;
      }
    }

    final totalPayments = paymentsSnapshot.docs.length;
    final paidPercentage = totalPayments > 0
        ? (successfulPayments / totalPayments)
        : 0.0;

    // 3. Calculate occupancy rate and average rent
    final occupancyRate = totalRooms > 0
        ? (occupiedRooms / totalRooms) * 100
        : 0.0;
    final averageRent = occupiedRooms > 0 ? totalRevenue / occupiedRooms : 0.0;

    // 4. Fetch recent activities WITHOUT ordering in query to avoid composite index error
    final residentsSnapshot = await FirebaseFirestore.instance
        .collectionGroup('residents')
        .where('managerId', isEqualTo: managerId)
        .limit(20) // Fetch more and sort locally to get latest 5
        .get();

    // Sort locally by createdAt descending
    final sortedDocs = residentsSnapshot.docs.toList();
    sortedDocs.sort((a, b) {
      final aTimestamp = a.data()['createdAt'] as Timestamp?;
      final bTimestamp = b.data()['createdAt'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp);
    });

    final recentActivityDocs = sortedDocs.take(5);

    final recentActivity = recentActivityDocs.map((doc) {
      final data = doc.data();
      return ActivityItem(
        icon: Icons.person_add,
        title: 'New Resident: ${data['name'] ?? 'N/A'}',
        subtitle: 'Hostel: ${data['hostelName'] ?? 'N/A'}',
      );
    }).toList();

    return {
      'occupancyRate': occupancyRate,
      'totalRevenue': totalRevenue,
      'averageRent': averageRent,
      'recentActivity': recentActivity,
      'paidPercentage': paidPercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDashboardData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available.'));
        }

        final data = snapshot.data!;
        final occupancyRate = (data['occupancyRate'] as double?) ?? 0.0;
        final totalRevenue = (data['totalRevenue'] as double?) ?? 0.0;
        final averageRent = (data['averageRent'] as double?) ?? 0.0;
        final recentActivity = data['recentActivity'] as List<ActivityItem>;
        final paidPercentage = (data['paidPercentage'] as double?) ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QuickActions(),
              const SizedBox(height: 20),
              Overview(
                occupancyRate: occupancyRate,
                totalRevenue: totalRevenue,
                averageRent: averageRent,
              ),
              const SizedBox(height: 20),
              KeyMetrics(monthlyRevenue: totalRevenue),
              const SizedBox(height: 20),
              PaymentStatus(paidPercentage: paidPercentage),
              const SizedBox(height: 20),
              RecentActivity(activities: recentActivity),
            ],
          ),
        );
      },
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ActionButton(
              label: 'Analytics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),
            ActionButton(
              label: 'Broadcast Message',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BroadcastScreen()),
                );
              },
            ),
            ActionButton(
              label: 'Add Hostel',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddHostelScreen()),
                );
              },
            ),
            ActionButton(
              label: 'Add Resident',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddResidentScreen()),
                );
              },
            ),
            ActionButton(
              label: 'Booking Requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingsRequestScreen(),
                  ),
                );
              },
            ),
            ActionButton(
              label: 'Publish Add',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PublishAddScreen()),
                );
              },
            ),
            ActionButton(
              label: 'Room Management',
              onTap: () {
                Navigator.pushNamed(context, '/room_management');
              },
            ),
            ActionButton(
              label: 'Room Matching',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoomMatchingScreen()),
                );
              },
            ),
            ActionButton(
              label: 'Tenant Listing',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TenantListingScreen(),
                  ),
                );
              },
            ),
            ActionButton(
              label: 'Maintenance Requests',
              onTap: () {
                Navigator.pushNamed(context, '/maintenance');
              },
            ),
            ActionButton(
              label: 'View Documents',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewDocumentsScreen(),
                  ),
                );
              },
            ),
            ActionButton(
              label: 'Manage Expenses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const ActionButton({super.key, required this.label, this.onTap});

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color getButtonColor() {
      if (_isPressed || _isHovering) return coffeeBrown;
      return Colors.white;
    }

    Color getTextColor() {
      if (_isPressed || _isHovering) return Colors.white;
      return coffeeBrown;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: getButtonColor(),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: coffeeBrown),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: getTextColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class Overview extends StatelessWidget {
  final double occupancyRate;
  final double totalRevenue;
  final double averageRent;

  const Overview({
    super.key,
    required this.occupancyRate,
    required this.totalRevenue,
    required this.averageRent,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!;
    TextStyle valueStyle = Theme.of(
      context,
    ).textTheme.headlineSmall!.copyWith(color: coffeeBrown);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dirtyBrownWhite,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            'Occupancy Rate',
            '${occupancyRate.toStringAsFixed(1)}%',
            titleStyle,
            valueStyle,
          ),
          _buildInfoItem(
            'Total Revenue',
            '\$${totalRevenue.toStringAsFixed(2)}',
            titleStyle,
            valueStyle,
          ),
          _buildInfoItem(
            'Average Rent',
            '\$${averageRent.toStringAsFixed(2)}',
            titleStyle,
            valueStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String title,
    String value,
    TextStyle titleStyle,
    TextStyle valueStyle,
  ) {
    return Column(
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 6),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class KeyMetrics extends StatelessWidget {
  final double monthlyRevenue;

  const KeyMetrics({super.key, required this.monthlyRevenue});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dirtyBrownWhite,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Metrics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly Revenue:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                currencyFormat.format(monthlyRevenue),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentStatus extends StatelessWidget {
  final double paidPercentage;

  const PaymentStatus({super.key, required this.paidPercentage});

  @override
  Widget build(BuildContext context) {
    final percentage = (paidPercentage * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dirtyBrownWhite,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: paidPercentage,
            backgroundColor: Colors.brown.shade100,
            color: coffeeBrown,
            minHeight: 12,
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% Paid',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class RecentActivity extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivity({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dirtyBrownWhite,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            Text(
              'No recent activity.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...activities.map(
              (activity) => ListTile(
                leading: Icon(activity.icon, color: coffeeBrown),
                title: Text(activity.title),
                subtitle: Text(activity.subtitle),
              ),
            ),
        ],
      ),
    );
  }
}

class ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
