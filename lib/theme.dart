import 'package:flutter/material.dart';

/// The AquaSense palette.
///
/// One rule governs everything here: **hue carries meaning**.
///
/// * Neutral navies are chrome — surfaces, borders, text.
/// * [accent] means one thing only: *energized*. Live power, nothing else.
/// * [warning] / [critical] are reserved exclusively for health.
///
/// Nothing decorative is allowed to borrow from the status ramp, because a
/// parameter card that is amber for branding reasons is indistinguishable from
/// one that is amber because the tank is in trouble.
abstract final class AppColors {
  // ---------------------------------------------------------------- surfaces
  // Deep and desaturated, so a single red readout carries across the room.
  static const abyss = Color(0xFF050B14);
  static const surface = Color(0xFF0A1421);
  static const surfaceRaised = Color(0xFF0F1E30);
  static const surfaceSunken = Color(0xFF060E18);
  static const border = Color(0xFF1B2E45);

  // -------------------------------------------------------------------- text
  static const textPrimary = Color(0xFFE6F0F9);
  static const textSecondary = Color(0xFF8FA6BF);
  static const textTertiary = Color(0xFF566E88);

  // ------------------------------------------------------------------ accent
  static const accent = Color(0xFF2DD4E8);
  static const accentSoft = Color(0xFF7DE8F5);
  static const accentDim = Color(0xFF126C7A);

  // ------------------------------------------------------------- status ramp
  static const warning = Color(0xFFFBBF24);
  static const critical = Color(0xFFF87171);

  // ---------------------------------------------------------------- hardware
  // The receptacles borrow the real bar's *geometry*, not its paint. Copying
  // the unit's orange plastic made the board read as a toy dropped into an
  // instrument — the rest of this app is dark glass lit by one accent, and the
  // hardware has to be built from the same material. Fidelity lives in the
  // slot layout and the 2x4 arrangement.
  static const socketWell = Color(0xFF0E1721);
  static const socketBody = Color(0xFF17222E);
  static const socketBodyLive = Color(0xFF12333F);
  static const socketSlot = Color(0xFF03060A);
}

/// Spacing and radius scale.
///
/// Every gap in the app comes from this ramp so vertical rhythm stays even as
/// the layout reflows between screen sizes.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const radiusMd = 14.0;
  static const radiusLg = 22.0;
}

/// Motion durations and curves.
abstract final class AppMotion {
  /// Toggling an outlet is a *physical* act, so it gets a slower, weightier
  /// curve than ordinary UI feedback would.
  static const energize = Duration(milliseconds: 340);
  static const counter = Duration(milliseconds: 520);
  static const entrance = Duration(milliseconds: 620);

  /// Eased at both ends.
  ///
  /// A pure fade on a decelerating curve reads as a flash followed by a crawl,
  /// because most of the opacity change lands in the first few frames. Easing
  /// in as well spreads it evenly, which is what makes a fade feel smooth
  /// rather than merely long.
  static const entranceCurve = Curves.easeInOut;
}

/// The typeface.
///
/// Libre Franklin, a grotesque descended from Franklin Gothic. Chosen against
/// the geometric sans faces this design was first tried with: their circular
/// letterforms read as futuristic, which is wrong for a piece of equipment
/// meant to look dependable rather than speculative.
abstract final class AppFonts {
  /// Labels, section titles, captions — everything that is language. Applied
  /// through the theme, so widgets inherit it without naming it.
  static const ui = 'LibreFranklin';

  /// Numeric readouts and the wordmark.
  ///
  /// The same family as [ui] today. Kept as a separate name so a dedicated
  /// display face can be introduced later by changing this one line, rather
  /// than by hunting down every number on the screen.
  static const display = 'LibreFranklin';
}

/// Widths the dashboard adapts to.
///
/// Driven by available width, not device class — a phone in landscape wants the
/// same layout as a small tablet.
enum FormFactor {
  compact,
  medium,
  expanded;

  bool get isCompact => this == FormFactor.compact;

  static FormFactor of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static FormFactor fromWidth(double width) {
    if (width < 620) return FormFactor.compact;
    if (width < 1080) return FormFactor.medium;
    return FormFactor.expanded;
  }
}

/// The controller theme.
///
/// Dark is not a stylistic default here: these screens live in dim fish rooms
/// and run around the clock, and a deep ground is what lets a single red
/// readout carry across a room.
ThemeData buildAquaSenseTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.abyss,
    // Set once here so every widget inherits the UI face without naming it.
    // Only the numeric readouts opt out, to AppFonts.display.
    typography: Typography.material2021(platform: base.platform).copyWith(
      black: base.typography.black.apply(fontFamily: AppFonts.ui),
      white: base.typography.white.apply(fontFamily: AppFonts.ui),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surface,
      primary: AppColors.accent,
      error: AppColors.critical,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: AppFonts.ui,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}
