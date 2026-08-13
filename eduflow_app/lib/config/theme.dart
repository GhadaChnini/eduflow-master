import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFFEC4899);
  static const Color accent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color primaryLight = Color(0xFFEDE9FE);

  // Dynamic colors based on brightness
  static Color bgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF111827)
      : const Color(0xFFFAF5FF);

  static Color cardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1F2937)
      : Colors.white;

  static Color textDarkColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF3B0764);

  static Color textMediumColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF9CA3AF)
      : const Color(0xFF6B7280);

  static Color borderColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF374151)
      : const Color(0xFFC4B5FD);

  static Color inputFillColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF111827)
      : const Color(0xFFFAF5FF);

  static bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;


  static ThemeData lightTheme(String language) {
    final isArabic = language == 'ar';

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        error: error,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: isArabic ? 'Cairo' : null,
      textTheme: isArabic
          ? _arabicTextTheme()
          : GoogleFonts.nunitoTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: isArabic ? 'Cairo' : 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surface,
      ),
    );
  }

  static TextTheme _arabicTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: 'Cairo'),
      bodyMedium: TextStyle(fontFamily: 'Cairo'),
      bodySmall: TextStyle(fontFamily: 'Cairo'),
      labelLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      labelMedium: TextStyle(fontFamily: 'Cairo'),
      labelSmall: TextStyle(fontFamily: 'Cairo'),
    );
  }

  static ThemeData darkTheme(String language) {
    final isArabic = language == 'ar';
    const darkTextColor = Colors.white;

    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = isArabic
        ? baseTextTheme.copyWith(
            displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            titleMedium: baseTextTheme.titleMedium?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            labelMedium: baseTextTheme.labelMedium?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
            labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: 'Cairo', color: darkTextColor, inherit: true),
          )
        : baseTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        error: error,
        surface: const Color(0xFF1F2937),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      fontFamily: isArabic ? 'Cairo' : null,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: isArabic ? 'Cairo' : 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          inherit: true,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(inherit: true),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1F2937),
      ),
    );
  }

}