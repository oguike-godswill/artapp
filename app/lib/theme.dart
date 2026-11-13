import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  /// Override with: flutter run --dart-define=API_URL=http://192.168.1.10:4000
  static const _fromEnv = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000'; // Android emulator -> host machine
    }
    return 'http://localhost:4000';
  }

  static String asset(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$apiUrl$path';
  }
}

class Solis {
  static const paper = Color(0xFFF4EEE3);
  static const ink = Color(0xFF1B1712);
  static const sun = Color(0xFFE58A2B);
  static const teal = Color(0xFF0F4C4A);
  static const rust = Color(0xFFB84A17);
  static const card = Color(0xFFFBF8F2);
  static const line = Color(0xFFE3DACB);
  static const muted = Color(0xFF7A7064);
  static const inkSoft = Color(0xFF2A241D);
  static const sunSoft = Color(0xFFF2A65A);

  static TextStyle serif(double size, {Color color = ink, FontWeight weight = FontWeight.w400, double? height}) =>
      GoogleFonts.fraunces(fontSize: size, color: color, fontWeight: weight, height: height ?? 1.1, letterSpacing: -0.3);

  static TextStyle sans(double size, {Color color = ink, FontWeight weight = FontWeight.w400, double? spacing, double? height}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight, letterSpacing: spacing, height: height);

  static TextStyle label({Color color = muted}) =>
      GoogleFonts.inter(fontSize: 10.5, color: color, fontWeight: FontWeight.w600, letterSpacing: 1.2);

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: sun, primary: ink, secondary: sun, surface: paper),
      scaffoldBackgroundColor: paper,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: GoogleFonts.inter().fontFamily, bodyColor: ink, displayColor: ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: ink, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: rust)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: rust, width: 1.4)),
        labelStyle: sans(14, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: sans(14, color: paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
