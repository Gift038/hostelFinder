import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({Key? key, required this.currentIndex}) : super(key: key);

  static const Color coffeeBrown = Color(0xFF4B2E05);
  static const Color lightCoffeeBrown = Color(0xFF9C7A5F);

  void _onNavTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/tenantPayment', (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/tenant_documents', (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.brown[100],
      type: BottomNavigationBarType.fixed,
      selectedItemColor: coffeeBrown,
      unselectedItemColor: lightCoffeeBrown,
      currentIndex: currentIndex,
      onTap: (index) => _onNavTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.house_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment),
          label: 'Payments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cases_rounded),
          label: 'Documents',
        ),
      ],
      selectedLabelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
    );
  }
} 