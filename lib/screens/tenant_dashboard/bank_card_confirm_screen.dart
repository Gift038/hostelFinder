import 'package:flutter/material.dart';

class BankCardConfirmScreen extends StatelessWidget {
  const BankCardConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final Color tan = const Color(0xFFF8F5F2);
    final Color yellow = const Color(0xFFFFDD00);
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String card = args != null && args['card'] != null ? args['card'] : '4070 43•• •••• 9271';
    final String amount = args != null && args['amount'] != null ? args['amount'] : '0.00';
    final String currency = args != null && args['currency'] != null ? args['currency'] : 'UGX';
    String accountNumber = '';

    String maskedCard = card;
    if (card.length >= 10) {
      maskedCard = card.replaceRange(6, card.length - 4, '•• •••• ');
    }

    return Scaffold(
      backgroundColor: tan,
      appBar: AppBar(
        backgroundColor: tan,
        elevation: 0,
        foregroundColor: coffeeBrown,
        title: const Text('Confirm Deposit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B2E05))),
        centerTitle: true,
        leading: BackButton(color: coffeeBrown),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment method
            Text('Payment method', style: TextStyle(color: lightCoffeeBrown, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(maskedCard, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: coffeeBrown)),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.grey[300]),
            // Amount
            Text('Amount', style: TextStyle(color: lightCoffeeBrown, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('$amount $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
            const SizedBox(height: 18),
            Divider(color: Colors.grey[300]),
            // Commission
            Text('Commission', style: TextStyle(color: lightCoffeeBrown, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('No commission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black)),
            const SizedBox(height: 18),
            Divider(color: Colors.grey[300]),
            // To account
            Text('To account', style: TextStyle(color: lightCoffeeBrown, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter account number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: coffeeBrown, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => accountNumber = v,
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.grey[300]),
            // To be deposited
            Container(
              margin: const EdgeInsets.symmetric(vertical: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('To be deposited', style: TextStyle(color: lightCoffeeBrown, fontWeight: FontWeight.w600)),
                  Text('$amount $currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown)),
                ],
              ),
            ),
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
                child: const Text('Confirm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 