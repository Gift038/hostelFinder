import 'package:flutter/material.dart';

class MobileMoneyUSSDInstructionScreen extends StatelessWidget {
  const MobileMoneyUSSDInstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final Color tan = const Color(0xFFF8F5F2);
    final Color yellow = const Color(0xFFFFDD00);
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String phone = args != null && args['phone'] != null ? args['phone'] : '+256 000 000000';

    return Scaffold(
      backgroundColor: tan,
      appBar: AppBar(
        backgroundColor: tan,
        elevation: 0,
        foregroundColor: coffeeBrown,
        title: const Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B2E05))),
        centerTitle: true,
        leading: BackButton(color: coffeeBrown),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'The USSD instruction will be sent to the following phone number.',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            Text(
              phone,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black),
            ),
            const SizedBox(height: 18),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: coffeeBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text('Continue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 