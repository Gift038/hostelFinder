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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Use the passed arguments, with fallbacks
    final String hostelName = args?['hostelName'] ?? 'Unknown Hostel';
    final String roomType = args?['roomType'] ?? 'Unknown Room';
    final num roomPrice = args?['roomPrice'] ?? 0;
    roomRate = roomPrice.toInt(); // Update the state variable

    total = (roomRate * months) + serviceFee;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Book $hostelName',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Room image
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: const Center(
              child: Text(
                'Image goes here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Text(
                    roomType,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Move-in Date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _CalendarPicker(
                  selectedDate: moveInDate!,
                  onDateSelected: (date) {
                    setState(() {
                      moveInDate = date;
                      moveOutDate = DateTime(
                        moveInDate!.year,
                        moveInDate!.month + months,
                        moveInDate!.day,
                      );
                    });
                  },
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 28),
                Text(
                  'Move-out Date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _CalendarPicker(
                  selectedDate: moveOutDate!,
                  onDateSelected: (date) {
                    setState(() {
                      moveOutDate = date;
                      months =
                          (date.year - moveInDate!.year) * 12 +
                          (date.month - moveInDate!.month);
                      if (months < 1) months = 1;
                    });
                  },
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 28),
                Text(
                  'Summary of Charges',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Duration of Stay'),
                    Text(
                      '$months month${months > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Room Rate'),
                    Text(
                      'UGX $roomRate/month',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service Fee'),
                    Text(
                      'UGX $serviceFee',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'UGX $total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _BookNowButton(
                  coffeeBrown: Theme.of(context).colorScheme.primary,
                  lightCoffeeBrown: Theme.of(context).colorScheme.secondary,
                  darkBlue: Theme.of(context).colorScheme.primary,
                ),
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
  const _CalendarPicker({
    required this.selectedDate,
    required this.onDateSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month - 1, 1);
    final lastDay = DateTime(now.year, now.month + 12, 0);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: coffeeBrown),
      ),
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: firstDay,
        lastDate: lastDay,
        onDateChanged: onDateSelected,
        currentDate: DateTime.now(),
        selectableDayPredicate: (date) =>
            date.isAfter(now.subtract(const Duration(days: 1))),
      ),
    );
  }
}

class _BookNowButton extends StatefulWidget {
  final Color coffeeBrown;
  final Color lightCoffeeBrown;
  final Color darkBlue;
  const _BookNowButton({
    required this.coffeeBrown,
    required this.lightCoffeeBrown,
    required this.darkBlue,
  });

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
