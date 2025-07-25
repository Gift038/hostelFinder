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
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B2E05))),
        centerTitle: true,
        leading: BackButton(color: coffeeBrown),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Choose payment method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: coffeeBrown),
            ),
            const SizedBox(height: 24),
            _PaymentMethodCard(
              icon: Icons.credit_card,
              title: 'Bank Card',
              processingTime: 'Instant - 30 minutes',
              fee: '0 %',
              coffeeBrown: coffeeBrown,
              lightCoffeeBrown: lightCoffeeBrown,
              iconColor: Colors.white,
              iconBgColor: coffeeBrown,
              onTap: () {
                Navigator.pushNamed(context, '/bank_card_payment');
              },
            ),
            const SizedBox(height: 16),
            _PaymentMethodCard(
              icon: Icons.smartphone,
              title: 'Mobile Money',
              processingTime: 'Instant - 30 minutes',
              fee: '0 %',
              coffeeBrown: coffeeBrown,
              lightCoffeeBrown: lightCoffeeBrown,
              iconColor: Colors.white,
              iconBgColor: coffeeBrown,
              onTap: () {
                Navigator.pushNamed(context, '/mobile_money_payment');
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color coffeeBrown;
  final Color lightCoffeeBrown;
  final String processingTime;
  final String fee;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color iconBgColor;
  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.coffeeBrown,
    required this.lightCoffeeBrown,
    required this.processingTime,
    required this.fee,
    this.onTap,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
            width: 48,
            height: 48,
              decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 28),
            ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown)),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Processing time ', style: TextStyle(color: lightCoffeeBrown)),
                      TextSpan(text: processingTime, style: TextStyle(color: coffeeBrown)),
                ],
              ),
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text('Fee $fee', style: TextStyle(color: lightCoffeeBrown, fontSize: 15)),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
