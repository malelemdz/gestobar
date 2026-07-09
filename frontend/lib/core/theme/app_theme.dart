import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores de la paleta Liquid Modernist
  static final Color liquidBg = const Color(0xFF14161A);
  static final Color liquidSurface = const Color(0xFF24262A); // level 1 surface / cards
  static final Color liquidSurfaceContainerLow = const Color(0xFF1E2024);
  static final Color liquidSurfaceContainerHigh = const Color(0xFF2E3035);
  
  static final Color liquidPrimary = const Color(0xFF00BCCF); // softer premium cyan
  static final Color liquidSecondary = const Color(0xFF6366F1); // softer premium indigo/violet
  static final Color liquidTertiary = const Color(0xFFEC4899); // softer premium pink/magenta
  
  static final Color liquidOnSurface = const Color(0xFFEBEBEF); // clearer grey-white
  static final Color liquidOnSurfaceVariant = const Color(0xFFCBE2E3); // clearer teal-grey
  static final Color liquidOutline = const Color(0xFF4A5657); // clearer outline variant

  // Colores de Estados Comunes
  static final Color colorSuccess = const Color(0xFF10B981);
  static final Color colorDanger = const Color(0xFFEF4444);
  static final Color colorWarning = const Color(0xFFF59E0B);

  // 🌟 Diseño Unificado Liquid Modernist (Dark por Defecto - Sin diferencias Claro/Oscuro)
  static ThemeData get liquidTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: liquidBg,
      colorScheme: ColorScheme.dark(
        background: liquidBg,
        surface: liquidBg,
        surfaceVariant: liquidSurface,
        primary: liquidPrimary,
        secondary: liquidSecondary,
        tertiary: liquidTertiary,
        onBackground: liquidOnSurface,
        onSurface: liquidOnSurface,
        onSurfaceVariant: liquidOnSurfaceVariant,
        outline: liquidOutline,
        error: colorDanger,
      ),
      textTheme: TextTheme(
        // display-lg (Montos y métricas en Bento Grid)
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 48.0,
          fontWeight: FontWeight.w800,
          color: liquidOnSurface,
        ),
        // headline-lg (Títulos primarios de páginas)
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32.0,
          fontWeight: FontWeight.w700,
          color: liquidOnSurface,
        ),
        // headline-md (Títulos de componentes y Bento widgets)
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24.0,
          fontWeight: FontWeight.w700,
          color: liquidOnSurface,
        ),
        // headline-sm (Nombres de productos / tragos en tarjetas)
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: liquidOnSurface,
        ),
        // body-lg (Texto de cuerpo extendido)
        bodyLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: liquidOnSurface,
        ),
        // body-md (Textos estándar generales / body-sm)
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: liquidOnSurface,
        ),
        // label-caps (Inter para etiquetas y metadatos)
        labelLarge: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: liquidOnSurface,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
          color: liquidOnSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: liquidSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0), // Esquinas extremas redondeadas (24px a 32px)
          side: BorderSide(color: liquidOutline.withOpacity(0.4), width: 1.0), // Borde interior sutil de 1px
        ),
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: liquidBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: liquidPrimary,
          fontSize: 22.0,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: liquidPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: liquidSurface,
        selectedItemColor: liquidPrimary,
        unselectedItemColor: liquidOnSurfaceVariant,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Ambos retornan exactamente el mismo estilo unificado Liquid Modernist
  static ThemeData get darkTheme => liquidTheme;
  static ThemeData get lightTheme => liquidTheme;
}
