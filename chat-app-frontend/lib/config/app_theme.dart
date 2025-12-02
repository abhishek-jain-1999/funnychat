import 'package:flutter/material.dart';

/// FlashChat Ultra-Dark Modern Theme
/// Design Philosophy: Pure black backgrounds with neon accents
class AppColors {
  // Primary Neon Accents (Theme Variants)
  static const Color amber = Color(0xFFFFB800);
  static const Color neonYellow = Color(0xFFFACC15);
  static const Color neonGreen = Color(0xFF4ADE80);
  static const Color neonCyan = Color(0xFF22D3EE);

  // Background Colors (Ultra-Dark)
  static const Color backgroundBase = Color(0xFF000000);
  static const Color backgroundCard = Color(0xFF080808);
  static const Color backgroundSubtle = Color(0xFF121212);
  static const Color backgroundBorder = Color(0xFF1A1A1A);
  static const Color backgroundHover = Color(0xFF262626);

  // Text Colors
  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textPlaceholder = Color(0xFF4B5563);
  static const Color textInverse = Color(0xFF000000);

  // Helper to get primary faint color
  static Color getPrimaryFaint(Color primary) => primary.withOpacity(0.1);
}

/// Theme Provider for dynamic color switching
class FlashChatTheme extends ChangeNotifier {
  Color _primaryColor = AppColors.amber;

  Color get primaryColor => _primaryColor;
  Color get primaryFaint => AppColors.getPrimaryFaint(_primaryColor);

  void setThemeColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  ThemeData get themeData => _buildTheme(_primaryColor);

  static ThemeData _buildTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppColors.backgroundBase,
      
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: AppColors.backgroundCard,
        error: const Color(0xFFE74C3C),
        onPrimary: AppColors.textInverse,
        onSecondary: AppColors.textInverse,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // Typography using Inter font
      textTheme: const TextTheme(
        // H1 - 30px Bold Tight
        displayLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
        // H2 - 20px SemiBold
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
        // H3 - 16px Medium
        displaySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
        // Body - 14px Regular
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
        // Caption - 12px Regular Secondary
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
        // Button - 16px Bold
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textSecondary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),

      // Card Theme
      // cardTheme: CardTheme(
      //   color: AppColors.backgroundCard,
      //   elevation: 0,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(12),
      //     side: const BorderSide(
      //       color: AppColors.backgroundBorder,
      //       width: 1,
      //     ),
      //   ),
      //   shadowColor: Colors.black.withOpacity(0.5),
      // ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.backgroundBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.backgroundBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE74C3C),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE74C3C),
            width: 2,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textPlaceholder,
          fontFamily: 'Inter',
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          fontFamily: 'Inter',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppColors.textInverse,
          elevation: 4,
          shadowColor: AppColors.getPrimaryFaint(primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),

      // Divider Theme
      dividerColor: AppColors.backgroundBorder,
      dividerTheme: const DividerThemeData(
        color: AppColors.backgroundBorder,
        thickness: 1,
        space: 1,
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: AppColors.textInverse,
        elevation: 6,
      ),

      // Scrollbar Theme
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.backgroundHover),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
        thumbVisibility: WidgetStateProperty.all(false),
      ),
    );
  }
}

/// Animation Constants
class AppAnimations {
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve easeInOut = Curves.easeInOut;
  static const Curve popIn = Cubic(0.175, 0.885, 0.32, 1.275);
  static const Curve slide = Cubic(0.4, 0.0, 0.2, 1.0);
}

/// Border Radius Constants
class AppRadius {
  static const double standard = 12.0;
  static const double large = 24.0;
  static const double pill = 999.0;
}

/// Shadow Styles
class AppShadows {
  static List<BoxShadow> cardElevation = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> getPrimaryShadow(Color primaryColor) {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
