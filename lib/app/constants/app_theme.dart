import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vikoba_app/app/constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      outline: AppColors.softBorder,
      outlineVariant: AppColors.softBorder,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.secondary.withValues(alpha: .2),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: AppColors.textSecondary),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 1.5,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.softBorder.withValues(alpha: 0.75),
          width: 0.6,
        ),
      ),
    ),

    dividerColor: AppColors.border,

    iconTheme: const IconThemeData(color: AppColors.primary),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x552563EB),
      selectionHandleColor: AppColors.primary,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      hintStyle: GoogleFonts.poppins(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),

      labelStyle: GoogleFonts.poppins(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),

      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.textSecondary,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.primary,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      outline: AppColors.darkSoftBorder,
      outlineVariant: AppColors.darkSoftBorder,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkTextPrimary,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.secondary.withValues(alpha: .28),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: AppColors.darkTextSecondary),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: TextStyle(color: AppColors.darkTextSecondary),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedColor: AppColors.primary.withValues(alpha: .35),
      side: BorderSide(color: AppColors.darkBorder),
      labelStyle: TextStyle(color: AppColors.darkTextPrimary),
      secondaryLabelStyle: TextStyle(color: AppColors.darkTextPrimary),
    ),

    // DARK CARD THEME
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 2,
      shadowColor: AppColors.darkBackground.withValues(alpha: 0.6),
      surfaceTintColor: Colors.transparent,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.darkSoftBorder.withValues(alpha: 0.7),
          width: 0.6,
        ),
      ),
    ),

    dividerColor: AppColors.darkBorder,

    iconTheme: const IconThemeData(color: Colors.white),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.secondary,
      selectionColor: Color(0x5510B981),
      selectionHandleColor: AppColors.secondary,
    ),

    // DARK INPUT THEME
    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: AppColors.darkSurface,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      hintStyle: GoogleFonts.poppins(
        color: AppColors.darkTextSecondary,
        fontSize: 14,
      ),

      labelStyle: GoogleFonts.poppins(
        color: AppColors.darkTextSecondary,
        fontSize: 14,
      ),

      floatingLabelStyle: GoogleFonts.poppins(
        color: AppColors.primary,
        fontSize: 14,
      ),

      prefixIconColor: AppColors.secondary,

      suffixIconColor: AppColors.darkTextSecondary,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
  );
}
