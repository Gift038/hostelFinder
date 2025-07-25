import 'package:flutter/material.dart';

class MobileMoneyPaymentScreen extends StatefulWidget {
  const MobileMoneyPaymentScreen({super.key});

  @override
  State<MobileMoneyPaymentScreen> createState() => _MobileMoneyPaymentScreenState();
}

class _MobileMoneyPaymentScreenState extends State<MobileMoneyPaymentScreen> {
  final Color coffeeBrown = const Color(0xFF4B2E05);
  final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
  final Color tan = const Color(0xFFF8F5F2);
  final _formKey = GlobalKey<FormState>();

  String amount = '';
  String phone = '';

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: coffeeBrown.withAlpha(7),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // See all payment methods link
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'See all payment methods',
                        style: TextStyle(color: lightCoffeeBrown, fontWeight: FontWeight.w500, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Payment method card
                  Text('Payment method', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tan,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: coffeeBrown,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.smartphone, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Mobile Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: coffeeBrown)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Phone number input
                  Text('Phone number', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: '+256 7XX XXX XXX',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: coffeeBrown, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Enter your phone number' : null,
                    onChanged: (v) => setState(() => phone = v),
                  ),
                  const SizedBox(height: 18),
                  // Amount
                  Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: coffeeBrown, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixText: 'UGX',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Enter amount' : null,
                    onChanged: (v) => setState(() => amount = v),
                  ),
                  const SizedBox(height: 4),
                  Text('35,728 - 3,747,262 UGX', style: TextStyle(color: lightCoffeeBrown, fontSize: 14)),
                  const SizedBox(height: 24),
                  // To be deposited
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('To be deposited', style: TextStyle(color: lightCoffeeBrown, fontWeight: FontWeight.w600)),
                        Text('${amount.isEmpty ? '0.00' : amount} UGX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Continue button (disabled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coffeeBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          Navigator.pushNamed(
                            context,
                            '/mobile_money_ussd',
                            arguments: {'phone': phone},
                          );
                        }
                      },
                      child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 