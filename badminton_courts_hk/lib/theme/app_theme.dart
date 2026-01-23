import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6C63FF);
  static const secondaryColor = Color(0xFF00BFA6);
  static const backgroundColor = Color(0xFF0F172A);
  static const cardColor = Color(0xFF1E293B);
  static const textColor = Colors.white;

  static const lightBackgroundColor = Color(0xFFF8FAFC);
  static const lightCardColor = Colors.white;
  static const lightTextColor = Color(0xFF0F172A);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    cardTheme: CardTheme(
      color: lightCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold, fontSize: 24),
        bodyLarge: TextStyle(color: Color(0xFF475569), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: lightTextColor),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightCardColor,
      background: lightBackgroundColor,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: CardTheme(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white60, fontSize: 14),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: cardColor,
      background: backgroundColor,
    ),
  );
}
