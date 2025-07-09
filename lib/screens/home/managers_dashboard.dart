import 'package:flutter/material.dart';
import '../manager_dashboard/addresident_screen.dart';
import '../manager_dashboard/notification_screen.dart' as manager;
import '../manager_dashboard/bookings_request.dart';
import '../manager_dashboard/maintenance_repair.dart';
import '../manager_dashboard/room_management_screen.dart';
import '../manager_dashboard/payments_screen.dart';
import '../tenant_dashboard/notification_screen.dart' as tenant;
import '../auth/register_account_screen.dart';
// import '../manager_dashboard/publish_add_screen.dart';

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
        ).copyWith(
          secondary: coffeeBrown,
          surface: Colors.white,
          background: Colors.white,
        ),
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
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager\'s Dashboard'),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.brown[100],
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: coffeeBrown,
        unselectedItemColor: lightCoffeeBrown,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Residents'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          QuickActions(),
          SizedBox(height: 20),
          Overview(),
          SizedBox(height: 20),
          KeyMetrics(),
          SizedBox(height: 20),
          PaymentStatus(),
          SizedBox(height: 20),
          RecentActivity(),
        ],
      ),
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
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: coffeeBrown,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
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
                  MaterialPageRoute(builder: (_) => const BookingsRequestScreen()),
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
                Navigator.pushNamed(context, '/room_matching');
              },
            ),
            ActionButton(
              label: 'Tenant Listing',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) =>
                      const AlertDialog(content: Text('Tenant Listing')),
                );
              },
            ),
            ActionButton(
              label: 'Maintenance Requests',
              onTap: () {
                Navigator.pushNamed(context, '/maintenance');
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: getButtonColor(),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: coffeeBrown.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _isPressed = true;
              });
              Future.delayed(const Duration(milliseconds: 100), () {
                setState(() {
                  _isPressed = false;
                });
                if (widget.onTap != null) widget.onTap!();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: TextStyle(
                  color: getTextColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Overview extends StatelessWidget {
  const Overview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: coffeeBrown,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: OverviewCard(title: 'Occupancy Rate', value: '85%'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: OverviewCard(title: 'Average Rent', value: 'Ugx 750,000'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const OverviewCard(title: 'Total Revenue', value: 'Ugx 20,000,000'),
      ],
    );
  }
}

class OverviewCard extends StatelessWidget {
  final String title;
  final String value;

  const OverviewCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: coffeeBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: coffeeBrown),
            ),
          ],
        ),
      ),
    );
  }
}

class KeyMetrics extends StatelessWidget {
  const KeyMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: coffeeBrown,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Revenue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: coffeeBrown,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ugx 5,000,000',
                  style: TextStyle(color: coffeeBrown),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Last 6 months: +15%',
                  style: TextStyle(color: coffeeBrown),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 100,
                  color: coffeeBrown,
                  alignment: Alignment.center,
                  child: const Text(
                    'Line Chart Placeholder',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentStatus extends StatelessWidget {
  const PaymentStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: coffeeBrown,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('90% Paid', style: TextStyle(color: coffeeBrown)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.9,
                  valueColor: const AlwaysStoppedAnimation<Color>(coffeeBrown),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This month: +5%',
                  style: TextStyle(color: coffeeBrown),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: coffeeBrown,
          ),
        ),
        SizedBox(height: 10),
        ActivityItem(
          icon: Icons.person_add,
          title: 'New Resident: Ethan Carter',
          subtitle: 'Room 203',
        ),
        ActivityItem(
          icon: Icons.plumbing,
          title: 'Maintenance: Leaky Faucet',
          subtitle: 'Room 101',
        ),
        ActivityItem(
          icon: Icons.payment,
          title: 'Payment Received: Ugx 750,000',
          subtitle: 'Room 205',
        ),
      ],
    );
  }
}

class ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ActivityItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: coffeeBrown,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: coffeeBrown)),
      subtitle: Text(subtitle, style: const TextStyle(color: coffeeBrown)),
    );
  }
}

class PublishAddScreen extends StatefulWidget {
  const PublishAddScreen({Key? key}) : super(key: key);

  @override
  State<PublishAddScreen> createState() => _PublishAddScreenState();
}

class _PublishAddScreenState extends State<PublishAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish Add')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Image'),
                    onPressed: () async {
                      // Placeholder for image picker
                      setState(() {
                        _imagePath = 'assets/hostel1.jpg';
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  if (_imagePath != null)
                    Text('Image selected', style: TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Published: ${_titleController.text}\n${_descController.text}${_imagePath != null ? '\nImage: $_imagePath' : ''}'),
                      ),
                    );
                    _titleController.clear();
                    _descController.clear();
                    setState(() => _imagePath = null);
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
