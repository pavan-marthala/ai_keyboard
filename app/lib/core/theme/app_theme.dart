import 'package:atfix/core/theme/app_colors.dart';
import 'package:atfix/core/theme/app_gradients.dart';
import 'package:atfix/core/theme/app_typography.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static final dark = _buildTheme(
    colors: AppColors.dark,
    gradients: AppGradients.dark,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme({
    required AppColors colors,
    required AppGradients gradients,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    final typography = AppTypography.dark;

    return ThemeData(
      fontFamily: 'Inter',
      useMaterial3: true,
      brightness: brightness,
    ).copyWith(
      extensions: [colors, typography, gradients],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.white,
        primaryContainer: colors.primary800,
        onPrimaryContainer: colors.primary100,
        secondary: colors.secondary,
        onSecondary: colors.white,
        secondaryContainer: colors.secondary200,
        onSecondaryContainer: colors.secondary900,
        surface: colors.surfaceLight,
        onSurface: colors.textPrimary,
        error: colors.error,
        onError: colors.white,
        outline: colors.border,
        outlineVariant: colors.borderLight,
        shadow: colors.black,
        scrim: colors.black,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(menuStyle: MenuStyle()),
      scaffoldBackgroundColor: colors.background,

      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: colors.background,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        titleTextStyle: typography.titleLarge.copyWith(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.background,
        elevation: 0,
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }),
      ),

      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          textStyle: typography.button.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: typography.button.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: typography.button.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error),
        ),
        hintStyle: TextStyle(color: colors.text4, fontSize: 13),
        labelStyle: TextStyle(color: colors.textTertiary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? colors.primary50 : colors.primary50,
        labelStyle: typography.labelLarge.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        side: BorderSide.none,
        selectedColor: colors.primary,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.background,
        headerBackgroundColor: colors.primary,
        headerForegroundColor: colors.white,
        rangePickerBackgroundColor: colors.background,
        rangePickerHeaderBackgroundColor: colors.primary,
        rangePickerHeaderForegroundColor: colors.white,
        rangePickerShape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(24),
        ),
        dayStyle: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),

      dataTableTheme: DataTableThemeData(
        dataTextStyle: typography.bodyMedium.copyWith(
          color: colors.textPrimary,
        ),
        headingTextStyle: typography.titleMedium.copyWith(
          color: colors.textPrimary,
        ),
        dividerThickness: 0,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceDark : colors.textPrimary,
        contentTextStyle: TextStyle(color: colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      textTheme: TextTheme(
        displayLarge: typography.displayLarge.copyWith(
          color: colors.textPrimary,
        ),
        displayMedium: typography.displayMedium.copyWith(
          color: colors.textPrimary,
        ),
        displaySmall: typography.displaySmall.copyWith(
          color: colors.textPrimary,
        ),
        headlineLarge: typography.headlineLarge.copyWith(
          color: colors.textPrimary,
        ),
        headlineMedium: typography.headlineMedium.copyWith(
          color: colors.textPrimary,
        ),
        headlineSmall: typography.headlineSmall.copyWith(
          color: colors.textPrimary,
        ),
        titleLarge: typography.titleLarge.copyWith(color: colors.textPrimary),
        titleMedium: typography.titleMedium.copyWith(color: colors.textPrimary),
        titleSmall: typography.titleSmall.copyWith(color: colors.textPrimary),
        bodyLarge: typography.bodyLarge.copyWith(color: colors.textSecondary),
        bodyMedium: typography.bodyMedium.copyWith(color: colors.textSecondary),
        bodySmall: typography.bodySmall.copyWith(color: colors.textTertiary),
        labelLarge: typography.labelLarge.copyWith(color: colors.textSecondary),
        labelMedium: typography.labelMedium.copyWith(
          color: colors.textTertiary,
        ),
        labelSmall: typography.labelSmall.copyWith(color: colors.text4),
      ),
    );
  }
}

extension ColorThemeExtension on ThemeData {
  AppColors get appColors => extension<AppColors>()!;
}

extension FontThemeExtension on ThemeData {
  AppTypography get appTypography => extension<AppTypography>()!;
}

extension ThemeGetter on BuildContext {
  ThemeData get theme => Theme.of(this);
}

extension GradientThemeExtension on ThemeData {
  AppGradients get appGradients => extension<AppGradients>()!;
}

extension AppThemeContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  AppGradients get appGradients => Theme.of(this).extension<AppGradients>()!;
  AppTypography get appTypography => Theme.of(this).extension<AppTypography>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
