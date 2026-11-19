import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'dimens.dart';

/// Tema global baseado no design system "Serene Rituals".
abstract final class AppTheme {
  static TextTheme _textTheme() {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    TextStyle s(TextStyle? t, double size, FontWeight w, double lh,
            [double ls = 0]) =>
        (t ?? const TextStyle()).copyWith(
          fontSize: size,
          fontWeight: w,
          height: lh / size,
          letterSpacing: ls * size,
          color: AppColors.onSurface,
        );

    return base.copyWith(
      displayLarge: s(base.displayLarge, 40, FontWeight.w700, 48, -0.02),
      displayMedium: s(base.displayMedium, 32, FontWeight.w700, 40, -0.01),
      displaySmall: s(base.displaySmall, 28, FontWeight.w700, 36, -0.01),
      headlineLarge: s(base.headlineLarge, 28, FontWeight.w600, 36, -0.01),
      headlineMedium: s(base.headlineMedium, 22, FontWeight.w600, 28),
      headlineSmall: s(base.headlineSmall, 18, FontWeight.w600, 24),
      titleLarge: s(base.titleLarge, 20, FontWeight.w600, 28),
      titleMedium: s(base.titleMedium, 16, FontWeight.w600, 22),
      titleSmall: s(base.titleSmall, 14, FontWeight.w600, 20),
      bodyLarge: s(base.bodyLarge, 16, FontWeight.w400, 26),
      bodyMedium: s(base.bodyMedium, 14, FontWeight.w400, 22),
      bodySmall: s(base.bodySmall, 12, FontWeight.w400, 18),
      labelLarge: s(base.labelLarge, 14, FontWeight.w600, 20, 0.01),
      labelMedium: s(base.labelMedium, 12, FontWeight.w500, 16, 0.02),
      labelSmall: s(base.labelSmall, 11, FontWeight.w600, 14, 0.04),
    );
  }

  static ThemeData get light {
    final textTheme = _textTheme();
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        foregroundColor: AppColors.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(Dimens.buttonHeight),
          shape: pill,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          minimumSize: const Size.fromHeight(Dimens.buttonHeight),
          shape: pill,
          side: const BorderSide(color: Color(0x2E2D5A43)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.sage, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sunkenWell,
        selectedColor: AppColors.primaryContainer,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.onPrimary,
        ),
        checkmarkColor: AppColors.onPrimary,
        shape: pill,
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryContainer
              : AppColors.surfaceHighest,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimens.radiusLg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryFixed,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
