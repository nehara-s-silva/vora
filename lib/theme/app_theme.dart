import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors - Modern & Vibrant
  static const Color primaryGreen = Color(0xff00E676); // Brighter green
  static const Color primaryTeal = Color(0xff11998e);
  static const Color primaryPurple = Color(0xff667eea);
  static const Color accentRed = Color(0xffff5252);
  static const Color accentYellow = Color(0xFFFFD740);
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPink = Color(0xFFFF4081);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xff00E676), Color(0xff11998e)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white10, Colors.white12],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xff0A0E11), Color(0xff1A2438)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark Theme Colors
  static const Color darkBg = Color(0xff0A0E11); // Deeper, richer dark
  static const Color darkSurface = Color(0xff151A21);
  static const Color darkCard = Color(0xFF1E2530);
  static const Color darkInput = Color(0xFF2C3545);
  static const Color darkCardAlt = Color(0xFF252C38);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFAFBFC);
  static const Color lightInput = Color(0xFFF0F2F5);
  static const Color lightCardAlt = Color(0xFFF5F7FA);

  // Spacing
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;

  // Radius
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXL = 32.0;

  // Text Styles (Static accessors for custom widgets that don't use Theme.of(context))
  static final TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static final TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static final TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.white,
  );

  static final TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white.withOpacity(0.8),
  );

  static final TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    color: Colors.white.withOpacity(0.6),
  );

  // Shadow
  static final List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      canvasColor: darkBg,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: primaryTeal,
        surface: darkSurface,
        background: darkBg,
        error: accentRed,
        onPrimary: Colors.black,
        onSurface: Colors.white,
        tertiary: neonBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInput,
        hintStyle: const TextStyle(color: Colors.white38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        bodyLarge: const TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium:
            TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        bodySmall:
            TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        labelLarge:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: Colors.white12,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      canvasColor: lightBg,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryTeal,
        surface: lightSurface,
        background: lightBg,
        error: accentRed,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
        tertiary: primaryPurple,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInput,
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        bodyLarge: const TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: const TextStyle(color: Colors.black54, fontSize: 14),
        bodySmall:
            TextStyle(color: Colors.black54.withOpacity(0.8), fontSize: 12),
        labelLarge:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      dividerColor: Colors.black12,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
