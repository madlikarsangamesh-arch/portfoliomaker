import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color darkBg = Color(0xFF09090E);
  static const Color glassCardBg = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x1BFFFFFF);
  static const Color neonCyan = Color(0xFF00FFCC);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color electricPink = Color(0xFFEC4899);
  
  // Curated Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        tertiary: electricPink,
        background: darkBg,
        surface: glassCardBg,
        onPrimary: Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
      ),
      cardTheme: const CardTheme(
        color: glassCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: glassBorder, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  // Neon Gradient Decoration helper
  static Decoration get glassDecoration {
    return BoxDecoration(
      color: glassCardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: glassBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Glowing Primary Gradient
  static Gradient get primaryGradient {
    return const LinearGradient(
      colors: [neonPurple, neonCyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // High contrast Neon Gradient
  static Gradient get creativeGradient {
    return const LinearGradient(
      colors: [electricPink, neonPurple],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}
