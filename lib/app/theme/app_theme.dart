// ignore: deprecated_member_use
import 'package:flutter/material.dart';

abstract final class Brand {
  static const green = Color(0xFF087F5B);
  static const charcoal = Color(0xFF202A30);
  static const canvas = Color(0xFFF5F7F6);
  static const mint = Color(0xFFE7F4EE);
  static const glassEdge = Color(0xBFFFFFFF);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.green,
    primary: Brand.green,
    brightness: brightness,
    surface: dark ? const Color(0xFF182126) : Colors.white,
  );
  final glassFill = dark ? const Color(0xAA1B292B) : const Color(0xD9FFFFFF);
  final glassBorder = dark
      ? Colors.white.withValues(alpha: .22)
      : Colors.white.withValues(alpha: .9);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: dark ? Colors.white : Brand.charcoal,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: glassFill,
      surfaceTintColor: Brand.green.withValues(alpha: .035),
      shadowColor: Brand.charcoal.withValues(alpha: dark ? .28 : .1),
      elevation: 4,
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: glassBorder, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 19, vertical: 13)),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? Brand.green.withValues(alpha: .35)
                : Brand.green.withValues(alpha: .91)),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor:
            WidgetStatePropertyAll(Colors.white.withValues(alpha: .19)),
        elevation: const WidgetStatePropertyAll(3),
        shadowColor: WidgetStatePropertyAll(Brand.green.withValues(alpha: .25)),
        side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withValues(alpha: .56))),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        backgroundColor: WidgetStatePropertyAll(glassFill),
        foregroundColor: WidgetStatePropertyAll(Brand.green),
        overlayColor:
            WidgetStatePropertyAll(Brand.green.withValues(alpha: .09)),
        elevation: const WidgetStatePropertyAll(3),
        shadowColor:
            WidgetStatePropertyAll(Brand.charcoal.withValues(alpha: .1)),
        side: WidgetStatePropertyAll(BorderSide(color: glassBorder)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        backgroundColor:
            WidgetStatePropertyAll(glassFill.withValues(alpha: .65)),
        foregroundColor: const WidgetStatePropertyAll(Brand.green),
        overlayColor:
            WidgetStatePropertyAll(Brand.green.withValues(alpha: .08)),
        side:
            WidgetStatePropertyAll(BorderSide(color: glassBorder, width: 1.2)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(Brand.green),
        overlayColor:
            WidgetStatePropertyAll(Brand.green.withValues(alpha: .08)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(Brand.charcoal),
        backgroundColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: dark ? .08 : .5)),
        overlayColor:
            WidgetStatePropertyAll(Brand.green.withValues(alpha: .13)),
        side: WidgetStatePropertyAll(
            BorderSide(color: glassBorder.withValues(alpha: .65))),
        shape: const WidgetStatePropertyAll(CircleBorder()),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: glassFill.withValues(alpha: .76),
      selectedColor: Brand.green.withValues(alpha: .14),
      disabledColor: glassFill.withValues(alpha: .42),
      side: BorderSide(color: glassBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      labelStyle:
          const TextStyle(color: Brand.charcoal, fontWeight: FontWeight.w600),
      secondaryLabelStyle:
          const TextStyle(color: Brand.green, fontWeight: FontWeight.w700),
      checkmarkColor: Brand.green,
      showCheckmark: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassFill.withValues(alpha: .76),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Brand.green, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: glassFill.withValues(alpha: .6),
      surfaceTintColor: Colors.transparent,
      indicatorColor: Brand.green.withValues(alpha: .13),
      elevation: 0,
      height: 72,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Brand.green
                : Brand.charcoal,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? Brand.green
                : Brand.charcoal,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: glassFill.withValues(alpha: .58),
      indicatorColor: Brand.green.withValues(alpha: .13),
      selectedIconTheme: const IconThemeData(color: Brand.green),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Brand.green,
      unselectedLabelColor: Brand.charcoal.withValues(alpha: .72),
      indicatorColor: Brand.green,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStatePropertyAll(Brand.green.withValues(alpha: .08)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: glassFill.withValues(alpha: .84),
      modalBackgroundColor: glassFill.withValues(alpha: .84),
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      showDragHandle: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: Brand.glassEdge),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: glassFill.withValues(alpha: .9),
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: glassBorder),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Brand.green.withValues(alpha: .94),
      foregroundColor: Colors.white,
      elevation: 7,
      focusElevation: 8,
      hoverElevation: 9,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Brand.glassEdge)),
    ),
    dividerTheme: DividerThemeData(
        color: Brand.green.withValues(alpha: .12), thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? const Color(0xEE20302D) : const Color(0xEEFFFFFF),
      contentTextStyle: TextStyle(color: dark ? Colors.white : Brand.charcoal),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: glassBorder)),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Brand.green),
  );
}
