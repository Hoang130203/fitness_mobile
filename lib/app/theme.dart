import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF0C0F0E);
  static const surface = Color(0xFF151918);
  static const raised = Color(0xFF1B201E);
  static const lime = Color(0xFFB6F04A);
  static const limeDim = Color(0xFF6E9A2A);
  static const text = Color(0xFFF2F4F1);
  static const muted = Color(0xFF8A928D);
  static const faint = Color(0xFF2A302D);
  static const orange = Color(0xFFF0A24A);
  static const blue = Color(0xFF5AB3F0);
  static const red = Color(0xFFE86A6A);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.lime,
      onPrimary: Color(0xFF0C0F0E),
      secondary: C.lime,
      surface: C.surface,
      onSurface: C.text,
      error: C.red,
    ),
    textTheme: base.textTheme
        .apply(bodyColor: C.text, displayColor: C.text)
        .copyWith(
          displayLarge: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
          displayMedium: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          headlineMedium: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 15),
          bodySmall: const TextStyle(fontSize: 13, color: C.muted),
          labelSmall: const TextStyle(
            fontSize: 12,
            color: C.muted,
            letterSpacing: 0.8,
          ),
        ),
    cardTheme: CardThemeData(
      color: C.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: C.text,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.lime,
        foregroundColor: C.bg,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.text,
        side: const BorderSide(color: C.faint),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: C.lime),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.raised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: C.muted),
      hintStyle: const TextStyle(color: C.muted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? C.bg : C.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? C.lime : C.faint,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.lime.withValues(alpha: 0.15),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? C.lime : C.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? C.lime : C.muted,
        ),
      ),
    ),
    dividerColor: C.faint,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.raised,
      contentTextStyle: const TextStyle(color: C.text),
      actionTextColor: C.lime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
