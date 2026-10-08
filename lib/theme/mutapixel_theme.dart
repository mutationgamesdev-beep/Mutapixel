import 'package:flutter/material.dart';

/// Premium design system for Mutapixel, in light and dark.
///
/// Stripe / Linear / Figma inspired: crisp surfaces, hairline
/// borders, a restrained indigo accent, generous spacing. Restraint is
/// what reads expensive: no neon, no garish gradients, no clutter.
///
/// Use [MutapixelTheme.of(context)] for theme-aware colors instead of
/// hardcoded values — it returns the light or dark [MutapixelPalette]
/// matching the active [ThemeMode].
class MutapixelTheme {
  MutapixelTheme._();

  /// Refined indigo/violet accent — identical in both themes.
  static const Color primary = Color(0xFF6C5CE7);

  // Raw light palette values (usable inside const expressions).
  static const Color lightBackground = Color(0xFFF7F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightHairline = Color(0xFFE8E8EC);
  static const Color lightInk = Color(0xFF111827);
  static const Color lightSecondaryText = Color(0xFF6B7280);
  static const Color lightSubtleFill = Color(0xFFF0F0F3);

  // Raw dark palette values (usable inside const expressions).
  static const Color darkBackground = Color(0xFF0A0A0B);
  static const Color darkSurface = Color(0xFF131316);
  static const Color darkHairline = Color(0x14FFFFFF);
  static const Color darkInk = Color(0xFFF9FAFB);
  static const Color darkSecondaryText = Color(0xFF9CA3AF);
  static const Color darkSubtleFill = Color(0xFF1E1E24);

  static const double cardRadius = 20;
  static const double smallCardRadius = 16;
  static const double sheetRadius = 20;

  /// Theme-aware palette for the active brightness.
  static MutapixelPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? MutapixelPalette.dark
          : MutapixelPalette.light;

  /// Standard premium card: surface color, 1px hairline, soft shadow.
  static BoxDecoration cardDecoration(BuildContext context,
      {double radius = cardRadius}) {
    final p = of(context);
    final dark =
        Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: p.hairline),
      boxShadow: [
        BoxShadow(
          color: dark
              ? const Color(0x40000000)
              : const Color(0x0A000000),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

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
      scaffoldBackgroundColor:
          lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: lightInk,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(
              color: lightHairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        showDragHandle: true,
        dragHandleColor: lightHairline,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: lightInk,
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: lightHairline, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF4B5563),
        textColor: lightInk,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
              color: lightHairline),
        ),
        textStyle: const TextStyle(
            color: lightInk, fontSize: 14),
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
        style: IconButton.styleFrom(
            foregroundColor: lightInk),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSubtleFill,
        selectedColor: primary,
        labelStyle: const TextStyle(
          color: lightInk,
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
        backgroundColor: lightInk,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: lightInk,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkInk,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(
              color: darkHairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        showDragHandle: true,
        dragHandleColor: darkHairline,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkInk,
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: darkHairline, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF9CA3AF),
        textColor: darkInk,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
              color: darkHairline),
        ),
        textStyle: const TextStyle(
            color: darkInk, fontSize: 14),
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
        style: IconButton.styleFrom(
            foregroundColor: darkInk),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSubtleFill,
        selectedColor: primary,
        labelStyle: const TextStyle(
          color: darkInk,
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
        backgroundColor: Color(0xFFF9FAFB),
        contentTextStyle:
            TextStyle(color: darkBackground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xFF2A2A30),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

/// Per-theme color palette. Access via `MutapixelTheme.of(context)`.
class MutapixelPalette {
  final Color background;
  final Color surface;
  final Color hairline;
  final Color ink;
  final Color secondaryText;
  final Color subtleFill;

  const MutapixelPalette({
    required this.background,
    required this.surface,
    required this.hairline,
    required this.ink,
    required this.secondaryText,
    required this.subtleFill,
  });

  static const light = MutapixelPalette(
    background: MutapixelTheme.lightBackground,
    surface: MutapixelTheme.lightSurface,
    hairline: MutapixelTheme.lightHairline,
    ink: MutapixelTheme.lightInk,
    secondaryText: MutapixelTheme.lightSecondaryText,
    subtleFill: MutapixelTheme.lightSubtleFill,
  );

  /// Linear / Vercel-inspired dark: near-black background, raised
  /// surfaces, hairline white borders, same indigo accent.
  static const dark = MutapixelPalette(
    background: MutapixelTheme.darkBackground,
    surface: MutapixelTheme.darkSurface,
    hairline: MutapixelTheme.darkHairline,
    ink: MutapixelTheme.darkInk,
    secondaryText: MutapixelTheme.darkSecondaryText,
    subtleFill: MutapixelTheme.darkSubtleFill,
  );
}
