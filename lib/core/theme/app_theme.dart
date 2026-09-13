import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAppTheme() {
  const cream = AppTokens.cream;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppTokens.night,
    colorScheme: const ColorScheme.dark(
      surface: AppTokens.surface,
      primary: AppTokens.magenta,
      secondary: AppTokens.cyan,
      error: AppTokens.coral,
      onSurface: cream,
      onPrimary: AppTokens.night,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'serif',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: cream,
        height: 1.15,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: cream,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: cream, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, color: AppTokens.creamMuted, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.nightAlt,
      hintStyle: const TextStyle(color: AppTokens.creamMuted),
      labelStyle: const TextStyle(color: AppTokens.creamMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTokens.cyan.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.cyan, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.coral, width: 1.4),
      ),
    ),
  );
}
