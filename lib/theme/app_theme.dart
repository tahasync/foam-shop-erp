import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color saleTint;
  final Color purchaseTint;
  final Color expenseTint;
  final Color profitTint;
  final Color inventoryTint;
  final Color khataTint;

  final Color saleFg;
  final Color purchaseFg;
  final Color expenseFg;
  final Color profitFg;
  final Color inventoryFg;

  final Color inkFaint;

  const AppColors({
    required this.saleTint,
    required this.purchaseTint,
    required this.expenseTint,
    required this.profitTint,
    required this.inventoryTint,
    required this.khataTint,
    required this.saleFg,
    required this.purchaseFg,
    required this.expenseFg,
    required this.profitFg,
    required this.inventoryFg,
    required this.inkFaint,
  });

  static const _light = AppColors(
    saleTint: Color(0xFFEAF3F1),
    purchaseTint: Color(0xFFFDF1E4),
    expenseTint: Color(0xFFFBEBE8),
    profitTint: Color(0xFFEAF3EC),
    inventoryTint: Color(0xFFF1EDF9),
    khataTint: Color(0xFFE0F2F1),
    saleFg: Color(0xFF0F6B64),
    purchaseFg: Color(0xFFB4712A),
    expenseFg: Color(0xFFB54A38),
    profitFg: Color(0xFF2E6B4E),
    inventoryFg: Color(0xFF6C4FA0),
    inkFaint: Color(0xFF8A928F),
  );

  static const _dark = AppColors(
    saleTint: Color(0xFF16302C),
    purchaseTint: Color(0xFF332512),
    expenseTint: Color(0xFF331D18),
    profitTint: Color(0xFF17301F),
    inventoryTint: Color(0xFF241D33),
    khataTint: Color(0xFF0D3A35),
    saleFg: Color(0xFF6ED8C7),
    purchaseFg: Color(0xFFF0B876),
    expenseFg: Color(0xFFF09A80),
    profitFg: Color(0xFF7DE0A3),
    inventoryFg: Color(0xFFC7ADF5),
    inkFaint: Color(0xFF7C8582),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? _light;

  @override
  ThemeExtension<AppColors> copyWith({
    Color? saleTint, Color? purchaseTint, Color? expenseTint,
    Color? profitTint, Color? inventoryTint, Color? khataTint,
    Color? saleFg, Color? purchaseFg, Color? expenseFg,
    Color? profitFg, Color? inventoryFg, Color? inkFaint,
  }) => AppColors(
    saleTint: saleTint ?? this.saleTint,
    purchaseTint: purchaseTint ?? this.purchaseTint,
    expenseTint: expenseTint ?? this.expenseTint,
    profitTint: profitTint ?? this.profitTint,
    inventoryTint: inventoryTint ?? this.inventoryTint,
    khataTint: khataTint ?? this.khataTint,
    saleFg: saleFg ?? this.saleFg,
    purchaseFg: purchaseFg ?? this.purchaseFg,
    expenseFg: expenseFg ?? this.expenseFg,
    profitFg: profitFg ?? this.profitFg,
    inventoryFg: inventoryFg ?? this.inventoryFg,
    inkFaint: inkFaint ?? this.inkFaint,
  );

  @override
  ThemeExtension<AppColors> lerp(covariant ThemeExtension<AppColors>? other, double t) => this;
}

class AppTheme {
  static const ink = Color(0xFF1B1F1E);
  static const inkSoft = Color(0xFF5B6461);
  static const inkFaint = Color(0xFF8A928F);
  static const teal = Color(0xFF0F6B64);
  static const tealDark = Color(0xFF0B4E49);
  static const amber = Color(0xFFE8A33D);
  static const terracotta = Color(0xFFB54A38);
  static const sage = Color(0xFF3B8264);
  static const bgLight = Color(0xFFF6F4F0);
  static const bgDark = Color(0xFF12171A);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1A2124);

  static ThemeData light() {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: teal,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEAF3F1),
      onPrimaryContainer: teal,
      secondary: amber,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFFF3E0),
      onSecondaryContainer: const Color(0xFF7A4F0A),
      tertiary: sage,
      onTertiary: Colors.white,
      error: terracotta,
      onError: Colors.white,
      surface: bgLight,
      onSurface: ink,
      surfaceContainerLowest: surfaceLight,
      surfaceContainerLow: const Color(0xFFEFEDEA),
      surfaceContainerHigh: const Color(0xFFE5E3E0),
      surfaceContainerHighest: const Color(0xFFDBD9D6),
      onSurfaceVariant: inkSoft,
      outlineVariant: const Color(0x1A14140F),
      shadow: Colors.black.withValues(alpha: 0.06),
    );
    return _base(cs, AppColors._light);
  }

  static ThemeData dark() {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF6ED8C7),
      onPrimary: const Color(0xFF003732),
      primaryContainer: const Color(0xFF16302C),
      onPrimaryContainer: const Color(0xFF6ED8C7),
      secondary: const Color(0xFFF0B876),
      onSecondary: const Color(0xFF3A2700),
      secondaryContainer: const Color(0xFF332512),
      onSecondaryContainer: const Color(0xFFF0B876),
      tertiary: const Color(0xFF7DE0A3),
      onTertiary: const Color(0xFF00331A),
      error: const Color(0xFFF09A80),
      onError: const Color(0xFF3A1108),
      surface: bgDark,
      onSurface: const Color(0xFFF5F7F6),
      surfaceContainerLowest: surfaceDark,
      surfaceContainerLow: const Color(0xFF1F2729),
      surfaceContainerHigh: const Color(0xFF2A3235),
      surfaceContainerHighest: const Color(0xFF363E41),
      onSurfaceVariant: const Color(0xFFB7C0BD),
      outlineVariant: const Color(0x29FFFFFF),
      shadow: Colors.black.withValues(alpha: 0.3),
    );
    return _base(cs, AppColors._dark).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
    );
  }

  static ThemeData _base(ColorScheme cs, AppColors appColors) {
    final inter = GoogleFonts.interTextTheme();
    final jakarta = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: inter.copyWith(
        headlineLarge: jakarta.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.02),
        headlineMedium: jakarta.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.02),
        titleLarge: jakarta.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: jakarta.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: jakarta.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: jakarta.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ).apply(
        bodyColor: cs.onSurface,
        displayColor: cs.onSurface,
      ),
      scaffoldBackgroundColor: cs.surface,
      extensions: [appColors],
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: jakarta.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 19,
          letterSpacing: -0.01,
          color: cs.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: inter.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
          elevation: 0,
          shadowColor: teal.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: inter.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 0),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: inter.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: inter.labelSmall,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textStyle: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
