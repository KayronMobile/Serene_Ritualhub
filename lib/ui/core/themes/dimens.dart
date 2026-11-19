import 'package:flutter/material.dart';

import 'colors.dart';

/// Espaçamentos, raios e sombras do design system.
abstract final class Dimens {
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 36.0;

  /// Margem externa padrão das telas (1.25rem).
  static const margin = 20.0;
  static const gutter = 16.0;

  static const radiusSm = 8.0;
  static const radius = 16.0;
  static const radiusMd = 24.0;
  static const radiusLg = 32.0;
  static const radiusXl = 48.0;

  static const buttonHeight = 52.0;

  static const screenPadding = EdgeInsets.symmetric(horizontal: margin);

  /// Sombra ambiente das superfícies (cards brancos).
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0A1F2923),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
    BoxShadow(color: Color(0x051F2923), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Brilho elevado para ações flutuantes.
  static const floatingShadow = [
    BoxShadow(
      color: Color(0x292D5A43),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];

  static final sunkenBorder = Border.all(color: const Color(0x0A1F2923));

  static BoxDecoration card({Color color = AppColors.surfaceLowest}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radiusMd),
        boxShadow: cardShadow,
      );
}
