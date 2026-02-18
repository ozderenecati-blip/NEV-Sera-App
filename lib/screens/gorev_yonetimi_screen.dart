import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GorevYonetimiScreen extends StatefulWidget {
  const GorevYonetimiScreen({super.key});

  @override
  State<GorevYonetimiScreen> createState() => _GorevYonetimiScreenState();
}

class _GorevYonetimiScreenState extends State<GorevYonetimiScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: const Color(0xFFD97706).withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Görev Yönetimi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Periyodik ve tek seferlik görevler,\nçalışanlara atama, öncelik belirleme\nYakında aktif olacak',
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
