import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Midnight Gold (Modo Oscuro - Default Bar Night)
  static final Color darkBackground = const Color(0xFF181309);
  static final Color darkSurface = const Color(0xFF241F14); // Container
  static final Color darkSurfaceCard = const Color(0xFF2F291E); // Card / Product
  static final Color darkPrimary = const Color(0xFFFBBC00); // Oro Ámbar
  static final Color darkSecondary = const Color(0xFF43DDE6); // Cian Neón
  static final Color darkOnSurface = const Color(0xFFEDE1D0); // Crema Cálido
  static final Color darkOnSurfaceVariant = const Color(0xFFD4C5AB); // Gris Arena
  static final Color darkOutline = const Color(0xFF504532);

  // Golden Slate (Modo Claro - Turno de Día)
  static final Color lightBackground = const Color(0xFFF8F9FA);
  static final Color lightSurface = const Color(0xFFEDEEEF); // Container
  static final Color lightSurfaceCard = const Color(0xFFFFFFFF); // Card
  static final Color lightPrimary = const Color(0xFF795900); // Ámbar Oscuro
  static final Color lightSecondary = const Color(0xFF006A65); // Verde Azulado
  static final Color lightOnSurface = const Color(0xFF191C1D); // Carbono Oscuro
  static final Color lightOnSurfaceVariant = const Color(0xFF504532); // Marrón Suave
  static final Color lightOutline = const Color(0xFFD4C5AB);

  // Color de Estados Comunes
  static final Color colorSuccess = const Color(0xFF10B981);
  static final Color colorDanger = const Color(0xFFEF4444);
  static final Color colorWarning = const Color(0xFFF59E0B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        background: darkBackground,
        surface: darkSurface,
        surfaceVariant: darkSurfaceCard,
        primary: darkPrimary,
        secondary: darkSecondary,
        onBackground: darkOnSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: darkOutline,
        error: colorDanger,
      ),
      textTheme: _buildTextTheme(darkOnSurface, darkOnSurfaceVariant),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: darkOutline, width: 1.0),
        ),
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkPrimary,
          fontSize: 24.0,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: darkPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkOnSurfaceVariant,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        background: lightBackground,
        surface: lightSurface,
        surfaceVariant: lightSurfaceCard,
        primary: lightPrimary,
        secondary: lightSecondary,
        onBackground: lightOnSurface,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightOnSurfaceVariant,
        outline: lightOutline,
        error: colorDanger,
      ),
      textTheme: _buildTextTheme(lightOnSurface, lightOnSurfaceVariant),
      cardTheme: CardThemeData(
        color: lightSurfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: lightOutline, width: 1.0),
        ),
        elevation: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: lightPrimary,
          fontSize: 24.0,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: lightPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: lightOnSurfaceVariant,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w500),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color mainColor, Color secondaryColor) {
    return TextTheme(
      // display-lg (Montos de dinero en Bento Grid)
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 48.0,
        height: 1.16,
        letterSpacing: -0.02,
        fontWeight: FontWeight.w700,
        color: mainColor,
      ),
      // headline-lg (Títulos de páginas primarias)
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32.0,
        height: 1.25,
        letterSpacing: -0.02,
        fontWeight: FontWeight.w700,
        color: mainColor,
      ),
      // headline-md (Títulos de componentes y Bento widgets)
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24.0,
        height: 1.33,
        letterSpacing: -0.01,
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      // headline-sm (Nombres de productos / tragos en tarjetas)
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20.0,
        height: 1.40,
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      // body-lg (Texto de cuerpo extendido)
      bodyLarge: GoogleFonts.inter(
        fontSize: 18.0,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: mainColor,
      ),
      // body-md (Textos estándar generales)
      bodyMedium: GoogleFonts.inter(
        fontSize: 16.0,
        height: 1.50,
        fontWeight: FontWeight.w400,
        color: mainColor,
      ),
      // label-lg (Botones e indicadores rápidos)
      labelLarge: GoogleFonts.inter(
        fontSize: 14.0,
        height: 1.42,
        letterSpacing: 0.02,
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      // label-sm (Badges de estado, información secundaria)
      labelSmall: GoogleFonts.inter(
        fontSize: 12.0,
        height: 1.33,
        letterSpacing: 0.04,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
    );
  }
}
