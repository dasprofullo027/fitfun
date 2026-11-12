import 'package:flutter/material.dart';

class AppColors {
  // Soft Orange Theme requested by user
  static const Color primary = Color(0xFFFF7043);
  static const Color primaryContainer = Color(0xFFFF8A65);
  static const Color secondary = Color(0xFFE64A19);
  static const Color background = Color(0xFFFFF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF3EE);
  static const Color surfaceAlt = Color(0xFFFFF3EE);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF757575);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFD32F2F);

  // Harmonized accents
  static const Color cardBorder = Color(0xFFFFE0D4);
  static const Color cardShadow = Color(0x0F000000);
  static const Color chartLine = Color(0xFFFF7043);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
}

class AppConstants {
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double buttonHeight = 52.0;

  static const List<String> muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Full Body',
  ];

  static const List<String> fitnessGoals = [
    'Build Muscle',
    'Lose Weight',
    'Stay Fit',
    'Increase Endurance',
    'Strength Training',
  ];
}
