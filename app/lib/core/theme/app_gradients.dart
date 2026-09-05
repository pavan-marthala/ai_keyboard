import 'package:material_ui/material_ui.dart';

@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  // ── Core ──
  final LinearGradient primary;
  final LinearGradient primaryReverse;
  final LinearGradient primaryVertical;
  final LinearGradient secondary;
  final LinearGradient secondaryReverse;

  // ── Glass / Brand blend ──
  final LinearGradient glass;
  final LinearGradient glassReverse;
  final LinearGradient glassVertical;

  // ── Signature combos ──
  final LinearGradient purpleRose;
  final LinearGradient rosePurple;
  final LinearGradient purpleIndigo;
  final LinearGradient roseDeep;

  // ── Backgrounds ──
  final LinearGradient backgroundDark;
  final LinearGradient backgroundLight;
  final LinearGradient surface;

  // ── Overlays ──
  final LinearGradient glassOverlay;
  final LinearGradient glassOverlaySubtle;
  final LinearGradient overlayBottom;
  final LinearGradient overlayTop;

  // ── Utility ──
  final LinearGradient shimmer;
  final LinearGradient welcomeBox;

  // ── Password strength ──
  final LinearGradient passwordWeak;
  final LinearGradient passwordMedium;
  final LinearGradient passwordStrong;

  const AppGradients({
    required this.primary,
    required this.primaryReverse,
    required this.primaryVertical,
    required this.secondary,
    required this.secondaryReverse,
    required this.glass,
    required this.glassReverse,
    required this.glassVertical,
    required this.purpleRose,
    required this.rosePurple,
    required this.purpleIndigo,
    required this.roseDeep,
    required this.backgroundDark,
    required this.backgroundLight,
    required this.surface,
    required this.glassOverlay,
    required this.glassOverlaySubtle,
    required this.overlayBottom,
    required this.overlayTop,
    required this.shimmer,
    required this.welcomeBox,
    required this.passwordWeak,
    required this.passwordMedium,
    required this.passwordStrong,
  });

  // ── Dark Preset — Electric Violet ───────────────────────────
  //
  // Same legend as app_colors.dart: EXACT = literal HTML value/stop,
  // DERIVED = no equivalent exists in the HTML app (it deliberately avoids
  // gradients on most surfaces — buttons are flat fills, not gradients).
  //
  static final dark = AppGradients(
    // EXACT — accent (#8B5CF6) -> accentHover (#7C3AED), the two literal
    // violet values used for interactive fills in the HTML app. Note the
    // HTML app itself uses these as flat solid colors, not a gradient —
    // this is provided for callers of your theme that specifically need a
    // gradient variant of the primary color.
    primary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),
    primaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),
    primaryVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),

    // DERIVED — no secondary hue in the HTML app; neutral gray duo instead.
    secondary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF444452), Color(0xFF5C5C6E)],
    ),
    secondaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFF444452), Color(0xFF5C5C6E)],
    ),

    // EXACT — the linear component of the HTML app's featured-art / stage
    // background: linear-gradient(150deg, #20202C, #0D0D11)
    glass: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF20202C), Color(0xFF0D0D11)],
    ),
    glassReverse: const LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      colors: [Color(0xFF20202C), Color(0xFF0D0D11)],
    ),
    glassVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF20202C), Color(0xFF0D0D11)],
    ),

    // DERIVED — the HTML app has no "purple + rose" two-hue combos (single
    // accent system), so these are repurposed as violet light/dark pairings.
    // Colors themselves are still exact violet-ramp hexes.
    purpleRose: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFC4B5FD),
        Color(0xFF7C3AED),
      ], // primary300 -> primary600
    ),
    rosePurple: const LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      colors: [Color(0xFFC4B5FD), Color(0xFF7C3AED)],
    ),
    // EXACT — the app's two accent-swatch options combined: Indigo (#6366F1,
    // the HTML app's default accent) -> Violet (#8B5CF6, this preset's accent)
    purpleIndigo: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    roseDeep: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF7C3AED),
        Color(0xFF4C1D95),
      ], // primary600 -> primary900
    ),

    // EXACT — --bg -> --surface-1 -> --surface-2, same three-tier ordering
    // the HTML app uses for elevation.
    backgroundDark: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A0A0D), Color(0xFF131318)],
    ),
    backgroundLight: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF131318), Color(0xFF1B1B22)],
    ),
    surface: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B1B22), Color(0xFF24242D)],
    ),

    // EXACT hexes (accent / accentHover) at an alpha within the HTML app's
    // own --indigo-wash / --indigo-wash-strong range (.14–.26).
    glassOverlay: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B5CF6).withValues(alpha: 0.18),
        const Color(0xFF7C3AED).withValues(alpha: 0.18),
      ],
    ),
    glassOverlaySubtle: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B5CF6).withValues(alpha: 0.08),
        const Color(0xFF7C3AED).withValues(alpha: 0.08),
      ],
    ),

    // EXACT — matches the HTML app's stage/hero fade precisely:
    // linear-gradient(180deg, rgba(10,10,13,0), var(--bg) 92%)
    overlayBottom: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0xFF0A0A0D)],
      stops: [0.0, 0.92],
    ),
    // DERIVED direction (HTML has no literal "top" overlay), same exact colors/stop.
    overlayTop: const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Colors.transparent, Color(0xFF0A0A0D)],
      stops: [0.0, 0.92],
    ),

    // EXACT — matches the HTML app's skeleton-loading shimmer precisely:
    // linear-gradient(100deg, surface-1 30%, surface-2 50%, surface-1 70%)
    shimmer: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF131318), Color(0xFF1B1B22), Color(0xFF131318)],
      stops: [0.3, 0.5, 0.7],
    ),

    // DERIVED — no equivalent component in the HTML app; reuses the two
    // accent-swatch hexes (Violet + Indigo) at a low wash alpha.
    welcomeBox: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B5CF6).withValues(alpha: 0.10),
        const Color(0xFF6366F1).withValues(alpha: 0.10),
      ],
    ),

    // DERIVED — no password-strength UI in Pure Cast; recolored using the
    // exact semantic error/warning/success base hexes with a derived darker
    // second stop for gradient effect.
    passwordWeak: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFF0576B), Color(0xFFC23349)],
    ),
    passwordMedium: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFF5A623), Color(0xFFC97D0E)],
    ),
    passwordStrong: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF34D399), Color(0xFF1FA372)],
    ),
  );

  @override
  AppGradients copyWith({
    LinearGradient? primary,
    LinearGradient? primaryReverse,
    LinearGradient? primaryVertical,
    LinearGradient? secondary,
    LinearGradient? secondaryReverse,
    LinearGradient? glass,
    LinearGradient? glassReverse,
    LinearGradient? glassVertical,
    LinearGradient? purpleRose,
    LinearGradient? rosePurple,
    LinearGradient? purpleIndigo,
    LinearGradient? roseDeep,
    LinearGradient? backgroundDark,
    LinearGradient? backgroundLight,
    LinearGradient? surface,
    LinearGradient? glassOverlay,
    LinearGradient? glassOverlaySubtle,
    LinearGradient? overlayBottom,
    LinearGradient? overlayTop,
    LinearGradient? shimmer,
    LinearGradient? welcomeBox,
    LinearGradient? passwordWeak,
    LinearGradient? passwordMedium,
    LinearGradient? passwordStrong,
  }) {
    return AppGradients(
      primary: primary ?? this.primary,
      primaryReverse: primaryReverse ?? this.primaryReverse,
      primaryVertical: primaryVertical ?? this.primaryVertical,
      secondary: secondary ?? this.secondary,
      secondaryReverse: secondaryReverse ?? this.secondaryReverse,
      glass: glass ?? this.glass,
      glassReverse: glassReverse ?? this.glassReverse,
      glassVertical: glassVertical ?? this.glassVertical,
      purpleRose: purpleRose ?? this.purpleRose,
      rosePurple: rosePurple ?? this.rosePurple,
      purpleIndigo: purpleIndigo ?? this.purpleIndigo,
      roseDeep: roseDeep ?? this.roseDeep,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      surface: surface ?? this.surface,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassOverlaySubtle: glassOverlaySubtle ?? this.glassOverlaySubtle,
      overlayBottom: overlayBottom ?? this.overlayBottom,
      overlayTop: overlayTop ?? this.overlayTop,
      shimmer: shimmer ?? this.shimmer,
      welcomeBox: welcomeBox ?? this.welcomeBox,
      passwordWeak: passwordWeak ?? this.passwordWeak,
      passwordMedium: passwordMedium ?? this.passwordMedium,
      passwordStrong: passwordStrong ?? this.passwordStrong,
    );
  }

  // ── lerp ─────────────────────────────────────────────────────
  @override
  AppGradients lerp(covariant ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      primary: LinearGradient.lerp(primary, other.primary, t)!,
      primaryReverse: LinearGradient.lerp(
        primaryReverse,
        other.primaryReverse,
        t,
      )!,
      primaryVertical: LinearGradient.lerp(
        primaryVertical,
        other.primaryVertical,
        t,
      )!,
      secondary: LinearGradient.lerp(secondary, other.secondary, t)!,
      secondaryReverse: LinearGradient.lerp(
        secondaryReverse,
        other.secondaryReverse,
        t,
      )!,
      glass: LinearGradient.lerp(glass, other.glass, t)!,
      glassReverse: LinearGradient.lerp(glassReverse, other.glassReverse, t)!,
      glassVertical: LinearGradient.lerp(
        glassVertical,
        other.glassVertical,
        t,
      )!,
      purpleRose: LinearGradient.lerp(purpleRose, other.purpleRose, t)!,
      rosePurple: LinearGradient.lerp(rosePurple, other.rosePurple, t)!,
      purpleIndigo: LinearGradient.lerp(purpleIndigo, other.purpleIndigo, t)!,
      roseDeep: LinearGradient.lerp(roseDeep, other.roseDeep, t)!,
      backgroundDark: LinearGradient.lerp(
        backgroundDark,
        other.backgroundDark,
        t,
      )!,
      backgroundLight: LinearGradient.lerp(
        backgroundLight,
        other.backgroundLight,
        t,
      )!,
      surface: LinearGradient.lerp(surface, other.surface, t)!,
      glassOverlay: LinearGradient.lerp(glassOverlay, other.glassOverlay, t)!,
      glassOverlaySubtle: LinearGradient.lerp(
        glassOverlaySubtle,
        other.glassOverlaySubtle,
        t,
      )!,
      overlayBottom: LinearGradient.lerp(
        overlayBottom,
        other.overlayBottom,
        t,
      )!,
      overlayTop: LinearGradient.lerp(overlayTop, other.overlayTop, t)!,
      shimmer: LinearGradient.lerp(shimmer, other.shimmer, t)!,
      welcomeBox: LinearGradient.lerp(welcomeBox, other.welcomeBox, t)!,
      passwordWeak: LinearGradient.lerp(passwordWeak, other.passwordWeak, t)!,
      passwordMedium: LinearGradient.lerp(
        passwordMedium,
        other.passwordMedium,
        t,
      )!,
      passwordStrong: LinearGradient.lerp(
        passwordStrong,
        other.passwordStrong,
        t,
      )!,
    );
  }
}
