import 'package:flutter/material.dart';

class BankCardPaymentScreen extends StatefulWidget {
  const BankCardPaymentScreen({super.key});

  @override
  State<BankCardPaymentScreen> createState() => _BankCardPaymentScreenState();
}

class _BankCardPaymentScreenState extends State<BankCardPaymentScreen> {
  final Color coffeeBrown = const Color(0xFF4B2E05);
  final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
  final Color tan = const Color(0xFFF8F5F2);
  final _formKey = GlobalKey<FormState>();

  String cardNumber = '';
  String cardholderName = '';
  String expiryDate = '';
  String cvv = '';
  String amount = '';

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
                  // Card number
                  Text('Card number', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: ' ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: coffeeBrown, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                  child: Icon(Icons.credit_card, color: lightCoffeeBrown),
                                ),
                                // Add more icons for Visa/Mastercard/JCB if desired
                              ],
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Enter card number' : null,
                          onChanged: (v) => cardNumber = v,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Cardholder name
                  Text('Cardholder name', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: ' ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: coffeeBrown, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter cardholder name' : null,
                    onChanged: (v) => cardholderName = v,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 4),
                  Text('Should be exactly the same as the name on your card', style: TextStyle(color: lightCoffeeBrown, fontSize: 13)),
                  const SizedBox(height: 18),
                  // Expiry and CVV
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expiry date', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: 'MM/YY',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: coffeeBrown, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.datetime,
                              validator: (v) => v == null || v.isEmpty ? 'Enter expiry date' : null,
                              onChanged: (v) => expiryDate = v,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CVV / CVC code', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: ' ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: coffeeBrown, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: Icon(Icons.credit_card, color: lightCoffeeBrown),
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              validator: (v) => v == null || v.isEmpty ? 'Enter CVV' : null,
                              onChanged: (v) => cvv = v,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Amount
                  Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, color: coffeeBrown)),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: coffeeBrown, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixText: 'UGX ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v == null || v.isEmpty ? 'Enter amount' : null,
                    onChanged: (v) => amount = v,
                  ),
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
                  // Continue button
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
                            '/bank_card_confirm',
                            arguments: {
                              'card': cardNumber,
                              'amount': amount,
                              'currency': 'UGX',
                            },
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