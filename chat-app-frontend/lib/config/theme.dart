import 'package:flutter/material.dart';

class AppTheme {
  // WhatsApp Dark Mode Colors
  static const Color primaryBackground = Color(0xFF111B21);
  static const Color secondaryBackground = Color(0xFF202C33);
  static const Color accentColor = Color(0xFF00A884);
  static const Color textPrimary = Color(0xFFE9EDEF);
  static const Color textSecondary = Color(0xFF8696A0);
  static const Color outgoingMessageBubble = Color(0xFF005C4B);
  static const Color incomingMessageBubble = Color(0xFF202C33);
  static const Color dividerColor = Color(0xFF2A3942);
  static const Color iconColor = Color(0xFF8696A0);
  static const Color errorColor = Color(0xFFE74C3C);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryBackground,
    scaffoldBackgroundColor: primaryBackground,
    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      surface: secondaryBackground,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: secondaryBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: textSecondary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const IconThemeData(
      color: iconColor,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
      bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondaryBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
    ),
    dividerColor: dividerColor,
    cardColor: secondaryBackground,
  );
}
