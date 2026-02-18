import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyWorkReportScreen extends StatefulWidget {
  const DailyWorkReportScreen({super.key});

  @override
  State<DailyWorkReportScreen> createState() => _DailyWorkReportScreenState();
}

class _DailyWorkReportScreenState extends State<DailyWorkReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 80,
            color: const Color(0xFFD97706).withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Günlük İş Raporu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Günlük yapılan işler, fotoğraflar,\nadmin onayı ve kilitleme\nYakında aktif olacak',
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
