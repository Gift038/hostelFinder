import 'package:flutter/material.dart';

class Overview extends StatelessWidget {
  const Overview({
    super.key,
    required this.occupancyRate,
    required this.totalRevenue,
    required this.averageRent,
  });

  final double occupancyRate;
  final double totalRevenue;
  final double averageRent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildOverviewItem(context, 'Occupancy Rate', '${occupancyRate.toStringAsFixed(1)}%'),
            const SizedBox(width: 20),
            _buildOverviewItem(context, 'Total Revenue', '₦${totalRevenue.toStringAsFixed(2)}'),
            const SizedBox(width: 20),
            _buildOverviewItem(context, 'Avg Rent per Room', '₦${averageRent.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 5),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
