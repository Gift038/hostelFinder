import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final Color tan = const Color(0xFFF8F5F2);
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final int total = args != null && args['total'] != null ? args['total'] : 0;

    return Scaffold(
      backgroundColor: tan,
      appBar: AppBar(
        backgroundColor: tan,
        elevation: 0,
        foregroundColor: coffeeBrown,
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: BackButton(color: coffeeBrown),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Choose payment method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 24),
            _PaymentMethodCard(
              icon: Icons.account_balance,
              title: 'Bank Transfer',
              subtitle: 'Pay directly from your bank account',
              onTap: () {},
              coffeeBrown: coffeeBrown,
              lightCoffeeBrown: lightCoffeeBrown,
              showArrow: false,
            ),
            const SizedBox(height: 16),
            _PaymentMethodCard(
              icon: Icons.smartphone,
              title: 'Mobile Money',
              subtitle: 'Pay with your mobile money account',
              onTap: () {},
              coffeeBrown: coffeeBrown,
              lightCoffeeBrown: lightCoffeeBrown,
              showArrow: true,
            ),
            const SizedBox(height: 16),
            _PaymentMethodCard(
              icon: Icons.credit_card,
              title: 'Card',
              subtitle: 'Pay with your credit or debit card',
              onTap: () {},
              coffeeBrown: coffeeBrown,
              lightCoffeeBrown: lightCoffeeBrown,
              showArrow: true,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: coffeeBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: Text('Pay UGX $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color coffeeBrown;
  final Color lightCoffeeBrown;
  final bool showArrow;
  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.coffeeBrown,
    required this.lightCoffeeBrown,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: coffeeBrown.withAlpha((255 * 0.04).toInt()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: coffeeBrown, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: coffeeBrown)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 15, color: lightCoffeeBrown)),
                ],
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right, color: Colors.black38, size: 28),
          ],
        ),
      ),
    );
  }
}
