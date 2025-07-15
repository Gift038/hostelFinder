import 'dart:async';

import 'package:flutter/material.dart';
import 'home_page.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  final Color coffeeBrown = const Color(0xFF4B2E05);
  final Color lightBrown = const Color(0xFFD7CCC8);
  final Color backgroundOverlay = Colors.black.withAlpha(64);

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOutCubic),
    );

    // Auto-navigate to HomeScreen after 20 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7BFA6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(218),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: coffeeBrown.withAlpha(46),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Icon(
                  Icons.home_rounded,
                  color: coffeeBrown,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'HostelFinder',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: coffeeBrown,
                letterSpacing: 1.2,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: coffeeBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Get Started', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
