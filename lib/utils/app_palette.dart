import 'package:flutter/material.dart';

/// Dealance Design System — Warm Beige/Brown Theme
/// Matches the original committed design language
class AppPalette {
  // ─── Primary / Brand ───
  static const Color primary = Color(0xFFEFBA8F);           // Warm orange
  static const Color primaryAccent = Color(0xFFD4956A);      // Deeper warm
  static const Color primaryLight = Color(0xFFF5D4B8);       // Light warm
  static const Color primaryDark = Color(0xFF57493F);        // Dark brown

  // ─── Surfaces ───
  static const Color background = Color(0xFFF8F7F6);         // Warm off-white
  static const Color surfaceCard = Color(0xFFFFFFFF);         // Card white
  static const Color surfaceElevated = Color(0xFFF5E8DC);     // Soft beige
  static const Color primaryBackground = Color(0xFFFDF5EE);   // Cream bg

  // ─── Text ───
  static const Color textPrimary = Color(0xFF1A1A1A);        // Near black
  static const Color textSecondary = Color(0xFF757575);       // Medium gray
  static const Color textTerenary = Color(0xFFA0A0A0);        // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);       // White on primary
  static const Color accentText = Color(0xFF57493F);          // Dark brown text

  // ─── AI / Feature Colors ───
  static const Color aiGlow = Color(0xFF7C3AED);              // AI purple glow
  static const Color aiGradientStart = Color(0xFF6C63FF);
  static const Color aiGradientEnd = Color(0xFF00D4AA);

  // ─── Status Colors ───
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Legacy ───
  static const Color secondary = Color(0xFF00D4AA);
  static const Color warmAccent = Color(0xFFEFBA8F);
  static const Color messageColor = Color(0xFFEFBA8F);
  static const Color highlight = Color(0xFFF5E8DC);
  static const Color unseen = Color(0xFFEEAC1B);
  static const Color seen = Color(0xFF07DE0E);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color red = Color(0xFFF44336);
  static const Color lightgreen = Color(0xFF8BC34A);
  static const Color transparent = Color(0x00000000);
  static const Color iconColor = Colors.black54;

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFEFBA8F), Color(0xFFD4956A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [aiGradientStart, aiGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFDF5EE), Color(0xFFF8F7F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF5E8DC), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Theme configuration — Warm beige/brown
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppPalette.background,
    colorScheme: ColorScheme.light(
      primary: AppPalette.primary,
      secondary: AppPalette.secondary,
      surface: AppPalette.surfaceCard,
      error: AppPalette.danger,
      onPrimary: AppPalette.textOnPrimary,
      onSurface: AppPalette.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppPalette.textPrimary,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppPalette.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.primaryDark,
        side: BorderSide(color: AppPalette.surfaceElevated),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPalette.surfaceElevated),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPalette.surfaceElevated),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: AppPalette.textTerenary,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppPalette.surfaceElevated),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppPalette.surfaceCard,
      selectedItemColor: AppPalette.primaryDark,
      unselectedItemColor: AppPalette.textSecondary,
    ),
  );
}
