import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<Map<String, dynamic>> _analyticsDataFuture;

  @override
  void initState() {
    super.initState();
    _analyticsDataFuture = _fetchAnalyticsData();
  }

  // NOTE: In a production app, this fetching logic would be heavily optimized,
  // likely using Cloud Functions to aggregate data into a separate 'analytics'
  // collection. The current implementation is for demonstration and will be slow.
  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Fetch hostels to calculate occupancy
    int totalRooms = 0;
    int occupiedRooms = 0;
    final hostelsSnapshot = await FirebaseFirestore.instance
        .collection('hostels')
        .where('managerId', isEqualTo: user.uid)
        .get();

    for (var doc in hostelsSnapshot.docs) {
      totalRooms += (doc.data()['totalRooms'] as num?)?.toInt() ?? 0;
      occupiedRooms += (doc.data()['occupiedRooms'] as num?)?.toInt() ?? 0;
    }

    // Fetch payments for revenue chart
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('managerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Success')
        .get();

    Map<String, double> monthlyRevenue = {};
    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final date = (data['date'] as Timestamp).toDate();
      final monthKey = DateFormat('yyyy-MM').format(date);
      monthlyRevenue.update(
        monthKey,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    // Fetch maintenance requests for type breakdown
    final maintenanceSnapshot = await FirebaseFirestore.instance
        .collection('maintenance_requests')
        .where('managerId', isEqualTo: user.uid)
        .get();
    Map<String, int> maintenanceCounts = {};
    for (var doc in maintenanceSnapshot.docs) {
      final type = doc.data()['issueType'] as String? ?? 'Other';
      maintenanceCounts.update(type, (value) => value + 1, ifAbsent: () => 1);
    }

    return {
      'monthlyRevenue': monthlyRevenue,
      'totalRooms': totalRooms,
      'occupiedRooms': occupiedRooms,
      'maintenanceCounts': maintenanceCounts,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Reporting')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data for analytics.'));
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _RevenueChart(revenueData: data['monthlyRevenue']),
              const SizedBox(height: 24),
              _OccupancyChart(
                occupied: data['occupiedRooms'],
                total: data['totalRooms'],
              ),
              const SizedBox(height: 24),
              _MaintenanceChart(maintenanceData: data['maintenanceCounts']),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final Map<String, double> revenueData;
  const _RevenueChart({required this.revenueData});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final sortedKeys = revenueData.keys.toList()..sort();
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), revenueData[sortedKeys[i]]!));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Revenue',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: spots.isEmpty
                  ? const Center(child: Text('No revenue data.'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccupancyChart extends StatelessWidget {
  final int occupied;
  final int total;
  const _OccupancyChart({required this.occupied, required this.total});

  @override
  Widget build(BuildContext context) {
    final double percentage = total > 0 ? (occupied / total) * 100 : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Occupancy Rate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: occupied.toDouble(),
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: Theme.of(context).colorScheme.primary,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: (total - occupied).toDouble(),
                      title: '',
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Occupied: $occupied / $total Rooms'),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceChart extends StatelessWidget {
  final Map<String, int> maintenanceData;
  const _MaintenanceChart({required this.maintenanceData});

  @override
  Widget build(BuildContext context) {
    final barGroups = <BarChartGroupData>[];
    int i = 0;
    maintenanceData.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              width: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
      i++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Requests by Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: barGroups.isEmpty
                  ? const Center(child: Text('No maintenance data.'))
                  : BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
