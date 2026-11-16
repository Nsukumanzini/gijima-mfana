// ignore: deprecated_member_use
import 'package:flutter/material.dart';

abstract final class Brand {
  static const green = Color(0xFF087F5B);
  static const charcoal = Color(0xFF202A30);
  static const canvas = Color(0xFFF5F7F6);
  static const mint = Color(0xFFE7F4EE);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
      seedColor: Brand.green,
      primary: Brand.green,
      brightness: brightness,
      surface: dark ? const Color(0xFF182126) : Colors.white);
  return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF11191D) : Brand.canvas,
      appBarTheme: const AppBarTheme(
          backgroundColor: Brand.canvas,
          foregroundColor: Brand.charcoal,
          elevation: 0,
          centerTitle: false),
      cardTheme: CardThemeData(
          color: scheme.surface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: Brand.mint,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Brand.green
                : Brand.charcoal)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? Brand.green
                : Brand.charcoal)),
      ));
}
