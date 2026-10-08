import 'package:flutter/material.dart';

/// Premium light design system for Mutapixel.
///
/// Stripe / Linear / Figma inspired: crisp white surfaces, hairline
/// borders, a restrained indigo accent, generous spacing. Restraint is
/// what reads expensive: no neon, no garish gradients, no clutter.
class MutapixelTheme {
  MutapixelTheme._();

  /// Refined indigo/violet accent.
  static const Color primary = Color(0xFF6C5CE7);

  /// App background: very subtle warm gray.
  static const Color background = Color(0xFFF7F7F8);

  /// Cards, sheets, dialogs.
  static const Color surface = Color(0xFFFFFFFF);

  /// 1px hairline borders.
  static const Color hairline = Color(0xFFE8E8EC);

  /// Primary text.
  static const Color ink = Color(0xFF111827);

  /// Secondary / helper text.
  static const Color secondaryText = Color(0xFF6B7280);

  /// Segmented controls, unselected chips, subtle fills.
  static const Color subtleFill = Color(0xFFF0F0F3);

  static const double cardRadius = 20;
  static const double smallCardRadius = 16;
  static const double sheetRadius = 20;

  /// Standard premium card: white, 1px hairline, very soft shadow.
  static BoxDecoration cardDecoration({double radius = cardRadius}) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Soft shadow for a selected/filled pill.
  static List<BoxShadow> get pillShadow => const [
        BoxShadow(
          color: Color(0x246C5CE7),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ink,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: hairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: hairline,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      dividerTheme: const DividerThemeData(color: hairline, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF4B5563),
        textColor: ink,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: hairline),
        ),
        textStyle: const TextStyle(color: ink, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ink),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: subtleFill,
        selectedColor: primary,
        labelStyle: const TextStyle(
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
