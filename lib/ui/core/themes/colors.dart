import 'package:flutter/material.dart';

/// Paleta "Serene Rituals" (DESIGN.md do protótipo Stitch).
abstract final class AppColors {
  // Primária — verde sálvia/floresta
  static const primary = Color(0xFF14422D);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2D5A43);
  static const onPrimaryContainer = Color(0xFF9FCFB2);
  static const primaryFixed = Color(0xFFBCEECF);
  static const primaryFixedDim = Color(0xFFA1D1B4);
  static const sage = Color(0xFF4E8767);

  // Secundária — terracota/âmbar (energia, streaks, desafios)
  static const secondary = Color(0xFF9A442D);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFC9174);
  static const onSecondaryContainer = Color(0xFF742814);
  static const secondaryFixed = Color(0xFFFFDBD2);
  static const terracotta = Color(0xFFE07A5F);
  static const amber = Color(0xFFF4A261);

  // Terciária — hidratação
  static const tertiary = Color(0xFF003B6D);
  static const tertiaryContainer = Color(0xFF005295);
  static const tertiaryFixed = Color(0xFFD4E3FF);
  static const hydration = Color(0xFF4A90E2);

  // Descanso — índigo crepúsculo
  static const rest = Color(0xFF3A405A);
  static const restContainer = Color(0xFFE3E5F2);

  // Superfícies
  static const surface = Color(0xFFF1FCF3);
  static const surfaceDim = Color(0xFFD1DDD4);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFEBF7ED);
  static const surfaceContainer = Color(0xFFE5F1E7);
  static const surfaceHigh = Color(0xFFE0EBE2);
  static const surfaceHighest = Color(0xFFDAE5DC);
  static const onSurface = Color(0xFF141E18);
  static const onSurfaceVariant = Color(0xFF414943);
  static const outline = Color(0xFF717973);
  static const outlineVariant = Color(0xFFC0C9C1);
  static const inverseSurface = Color(0xFF29332C);
  static const sunkenWell = Color(0xFFEFEFE9);
  static const pine = Color(0xFF1F2923);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  // Medalhas do placar
  static const gold = Color(0xFFE0A526);
  static const silver = Color(0xFF9EA7A3);
  static const bronze = Color(0xFFB8733F);

  /// Paleta para avatares por iniciais.
  static const avatarPalette = [
    Color(0xFFBCEECF),
    Color(0xFFFFDBD2),
    Color(0xFFD4E3FF),
    Color(0xFFDAE5DC),
    Color(0xFFFFE6C7),
    Color(0xFFE3E5F2),
  ];

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: Color(0xFF9FC6FF),
    error: error,
    onError: Color(0xFFFFFFFF),
    errorContainer: errorContainer,
    onErrorContainer: Color(0xFF93000A),
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceDim: surfaceDim,
    surfaceBright: surface,
    surfaceContainerLowest: surfaceLowest,
    surfaceContainerLow: surfaceLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: Color(0xFFE8F4EA),
    inversePrimary: primaryFixedDim,
    surfaceTint: Color(0xFF3A674F),
    shadow: pine,
  );
}
