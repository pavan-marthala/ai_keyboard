import 'package:material_ui/material_ui.dart';

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  // Display
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  // Headline
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  // Title
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  // Body
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  // Label
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
  // Custom
  final TextStyle button;
  final TextStyle caption;

  const AppTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.button,
    required this.caption,
  });

  // Note on sizes: the Pure Cast HTML app never defines a formal Material-style
  // type ramp (its type sizes are contextual/responsive: e.g. hero titles run
  // clamp(22px, 5cqw, 34px) and scale up to ~52px on desktop). So the numeric
  // `fontSize`/`height` values below are UNCHANGED from your original scale —
  // only `color` and `fontWeight` were updated to match how the HTML app
  // actually uses Inter (colors are EXACT matches to --ink / --ink-soft /
  // --ink-faint; weights were bumped where the HTML app is visibly heavier,
  // e.g. large titles are font-weight 800 there, not 600).
  static const dark = AppTypography(
    // Display
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w800,
      height: 1.12,
      fontFamily: 'Inter',
      letterSpacing: -0.5,
      color: Color(0xFFF5F5F7), // EXACT — --ink
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      height: 1.16,
      fontFamily: 'Inter',
      letterSpacing: -0.4,
      color: Color(0xFFF5F5F7),
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.22,
      fontFamily: 'Inter',
      letterSpacing: -0.3,
      color: Color(0xFFF5F5F7),
    ),

    // Headline
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight:
          FontWeight.w800, // matches the HTML app's hero/player title weight
      height: 1.25,
      fontFamily: 'Inter',
      letterSpacing: -0.3,
      color: Color(0xFFF5F5F7),
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.29,
      fontFamily: 'Inter',
      letterSpacing: -0.2,
      color: Color(0xFFF5F5F7),
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.33,
      fontFamily: 'Inter',
      color: Color(0xFFF5F5F7),
    ),

    // Title
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700, // matches HTML section headings (~700/750)
      height: 1.27,
      fontFamily: 'Inter',
      color: Color(0xFFF5F5F7),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.50,
      letterSpacing: 0.15,
      fontFamily: 'Inter',
      color: Color(0xFFF5F5F7),
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600, // matches e.g. device/card name weight
      height: 1.43,
      letterSpacing: 0.10,
      fontFamily: 'Inter',
      color: Color(0xFFF5F5F7),
    ),

    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.50,
      letterSpacing: 0.50,
      fontFamily: 'Inter',
      color: Color(0xFF98989F), // EXACT — --ink-soft
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      fontFamily: 'Inter',
      color: Color(0xFF98989F),
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.40,
      fontFamily: 'Inter',
      color: Color(0xFF5C5C66), // EXACT — --ink-faint
    ),

    // Label
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.10,
      fontFamily: 'Inter',
      color: Color(0xFF98989F),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.50,
      fontFamily: 'Inter',
      color: Color(0xFF5C5C66),
    ),
    // This one is a near-exact translation of the HTML app's `.eyebrow` style:
    // 11px / weight 700 / letter-spacing .14em (11 * 0.14 ≈ 1.5) / --ink-faint
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.45,
      letterSpacing: 1.5,
      fontFamily: 'Inter',
      color: Color(0xFF5C5C66),
    ),

    // EXACT — HTML primary buttons are font-weight 700, white text on a solid fill
    button: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.42,
      letterSpacing: 0.10,
      fontFamily: 'Inter',
      color: Color(0xFFFFFFFF),
    ),

    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.40,
      fontFamily: 'Inter',
      color: Color(0xFF5C5C66), // EXACT — --ink-faint
    ),
  );
  @override
  AppTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
    TextStyle? button,
    TextStyle? caption,
  }) {
    return AppTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
      button: button ?? this.button,
      caption: caption ?? this.caption,
    );
  }

  // ── lerp ─────────────────────────────────────────────────────
  @override
  AppTypography lerp(covariant ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t)!,
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t)!,
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t)!,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}
