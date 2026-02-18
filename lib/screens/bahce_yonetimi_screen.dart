import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BahceYonetimiScreen extends StatefulWidget {
  const BahceYonetimiScreen({super.key});

  @override
  State<BahceYonetimiScreen> createState() => _BahceYonetimiScreenState();
}

class _BahceYonetimiScreenState extends State<BahceYonetimiScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.park,
            size: 80,
            color: const Color(0xFFD97706).withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Bahçe Yönetimi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bahçe tanımlama, parsel, sıra ve saksı yönetimi\nYakında aktif olacak',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }
}
