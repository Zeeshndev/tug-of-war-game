import 'package:flutter/material.dart';

class AppTheme {
  // ── Colours ──────────────────────────────────────────────
  static const Color bg        = Color(0xFF0F172A);
  static const Color bg2       = Color(0xFF1E293B);
  static const Color bg3       = Color(0xFF334155);
  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const Color blue      = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFF3B82F6);
  static const Color blueDark  = Color(0xFF1D4ED8);

  static const Color red       = Color(0xFFDC2626);
  static const Color redLight  = Color(0xFFEF4444);

  static const Color green     = Color(0xFF16A34A);
  static const Color greenLight= Color(0xFF22C55E);

  static const Color yellow    = Color(0xFFF59E0B);
  static const Color yellowLight=Color(0xFFFCD34D);

  static const Color purple    = Color(0xFF7C3AED);

  // ── Typography ───────────────────────────────────────────
  static const String fontDisplay = 'Fredoka';
  static const String fontBody    = 'Nunito';

  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: fontDisplay,
        fontSize: size,
        color: color ?? textPrimary,
        fontWeight: weight ?? FontWeight.w400,
        height: 1.1,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: fontBody,
        fontSize: size,
        color: color ?? textPrimary,
        fontWeight: weight ?? FontWeight.w600,
      );

  // ── Border radius ─────────────────────────────────────────
  static const double radiusSm = 10;
  static const double radius   = 16;
  static const double radiusLg = 24;

  // ── Theme data ───────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: blue,
      secondary: yellow,
      surface: bg2,
      background: bg,
    ),
    scaffoldBackgroundColor: bg,
    fontFamily: fontBody,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textPrimary, fontFamily: fontBody),
    ),
  );
}

// ── Shared UI constants ───────────────────────────────────
const kMinTouchTarget = 48.0;

class AppDecoration {
  static BoxDecoration card({Color? borderColor}) => BoxDecoration(
    color: AppTheme.bg2,
    borderRadius: BorderRadius.circular(AppTheme.radius),
    border: Border.all(color: borderColor ?? AppTheme.bg3),
  );

  static BoxDecoration pill({Color? color}) => BoxDecoration(
    color: color ?? AppTheme.bg2,
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: AppTheme.bg3),
  );
}
