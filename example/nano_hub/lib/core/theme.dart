import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NanoHubTheme {
  static const primaryColor = Color(0xFF6200EE);
  static const accentColor = Color(0xFF03DAC6);
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
      ),
    );
  }

  static BoxDecoration glassDecoration({double opacity = 0.1}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    );
  }
}
