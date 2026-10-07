import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const background = Color(0xFFF5F7FB);
  static const surface = Colors.white;
  static const ink = Color(0xFF1D2433);
  static const muted = Color(0xFF6B7280);
  static const primary = Color(0xFF365CF6);
  static const primarySoft = Color(0xFFECEFFF);
  static const positive = Color(0xFF229A67);
  static const negative = Color(0xFFD14B4B);
  static const warning = Color(0xFFE49A27);
  static const navy = Color(0xFF182033);
  static const border = Color(0xFFE3E8F0);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light, surface: AppColors.surface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Arial',
    cardTheme: const CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.border), borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: AppColors.primarySoft, elevation: 0),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.navy,
      indicatorColor: Color(0xFF2F3B5C),
      selectedIconTheme: IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Color(0xFFBBC3D5)),
      selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: Color(0xFFBBC3D5)),
    ),
  );
}
