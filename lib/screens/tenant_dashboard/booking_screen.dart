import 'package:flutter/material.dart';

const Color coffeeBrown = Color(0xFF4B2E19);
const Color lightCoffeeBrown = Color(0xFFD7CCC8);
const Color darkBlue = Color(0xFF003366);

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? moveInDate;
  DateTime? moveOutDate;
  int months = 1;
  int roomRate = 0;
  int serviceFee = 0;
  int total = 0;
  String roomType = 'Single Room';

  @override
  void initState() {
    super.initState();
    moveInDate ??= DateTime.now();
    moveOutDate ??= DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String roomType = args != null && args['roomType'] != null ? args['roomType'] : 'Unknown';
    total = (roomRate * months) + serviceFee;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: coffeeBrown,
        title: Text('Book this space', style: TextStyle(fontWeight: FontWeight.bold, color: coffeeBrown)),
        centerTitle: true,
        leading: BackButton(color: coffeeBrown),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Room image
          Image.asset(
            'assets/hostel1.jpg',
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Type
                Text('Room Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: lightCoffeeBrown, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(roomType, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: coffeeBrown)),
                ),
                const SizedBox(height: 28),
                // Move-in Date
                Text('Move-in Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown)),
                const SizedBox(height: 10),
                _CalendarPicker(
                  selectedDate: moveInDate!,
                  onDateSelected: (date) {
                    setState(() {
                      moveInDate = date;
                      moveOutDate = DateTime(moveInDate!.year, moveInDate!.month + months, moveInDate!.day);
                    });
                  },
                  color: lightCoffeeBrown,
                ),
                const SizedBox(height: 28),
                // Move-out Date
                Text('Move-out Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown)),
                const SizedBox(height: 10),
                _CalendarPicker(
                  selectedDate: moveOutDate!,
                  onDateSelected: (date) {
                    setState(() {
                      moveOutDate = date;
                      months = (date.year - moveInDate!.year) * 12 + (date.month - moveInDate!.month);
                      if (months < 1) months = 1;
                    });
                  },
                  color: lightCoffeeBrown,
                ),
                const SizedBox(height: 28),
                // Summary of Charges
                Text('Summary of Charges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Duration of Stay', style: TextStyle(fontSize: 16)),
                    Text('$months month${months > 1 ? 's' : ''}', style: TextStyle(fontSize: 16, color: coffeeBrown)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Room Rate', style: TextStyle(fontSize: 16)),
                    Text('UGX $roomRate/month', style: TextStyle(fontSize: 16, color: coffeeBrown)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service Fee', style: TextStyle(fontSize: 16)),
                    Text('UGX $serviceFee', style: TextStyle(fontSize: 16, color: coffeeBrown)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('UGX $total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: coffeeBrown)),
                  ],
                ),
                const SizedBox(height: 28),
                _BookNowButton(coffeeBrown: coffeeBrown, lightCoffeeBrown: lightCoffeeBrown, darkBlue: darkBlue),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Color color;
  const _CalendarPicker({required this.selectedDate, required this.onDateSelected, required this.color});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month - 1, 1);
    final lastDay = DateTime(now.year, now.month + 12, 0);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: coffeeBrown,
        ),
      ),
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: firstDay,
        lastDate: lastDay,
        onDateChanged: onDateSelected,
        currentDate: DateTime.now(),
        selectableDayPredicate: (date) => date.isAfter(now.subtract(const Duration(days: 1))),
      ),
    );
  }
}

class _BookNowButton extends StatefulWidget {
  final Color coffeeBrown;
  final Color lightCoffeeBrown;
  final Color darkBlue;
  const _BookNowButton({required this.coffeeBrown, required this.lightCoffeeBrown, required this.darkBlue});

  @override
  State<_BookNowButton> createState() => _BookNowButtonState();
}

class _BookNowButtonState extends State<_BookNowButton> {
  bool _isHovered = false;
  final Color brown = const Color(0xFF8D6E63); // Brown color for default

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/tenantPayment');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: _isHovered ? widget.coffeeBrown : brown,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.coffeeBrown.withAlpha(20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Book Now',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
