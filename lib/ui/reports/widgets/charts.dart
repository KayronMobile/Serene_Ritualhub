import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/weekly_report.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';

/// Barras de aderência diária (seg..dom) com destaque do dia vulnerável.
class AdherenceBarChart extends StatelessWidget {
  const AdherenceBarChart({
    super.key,
    required this.days,
    this.highlightWeekday,
    this.height = 150,
  });

  final List<DayAdherence> days;
  final int? highlightWeekday;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: height + 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Semantics(
                label:
                    '${Dates.weekdayLong[d.date.weekday - 1]}: '
                    '${d.adherence == null ? 'sem dados' : '${(d.adherence! * 100).round()}%'}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (d.date.weekday == highlightWeekday &&
                        d.adherence != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${(d.adherence! * 100).round()}%',
                          style: t.labelSmall?.copyWith(
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: d.adherence ?? 0.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        constraints: const BoxConstraints(maxWidth: 30),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: max(
                          8.0,
                          height * (d.adherence == null ? 0.08 : v),
                        ),
                        decoration: BoxDecoration(
                          color: d.adherence == null
                              ? AppColors.surfaceHighest
                              : d.date.weekday == highlightWeekday
                              ? AppColors.terracotta
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Dates.weekdayShort[d.date.weekday - 1],
                        style: t.labelMedium?.copyWith(
                          color: d.isFuture
                              ? AppColors.outline
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Linha suave de hidratação diária com a meta tracejada.
class HydrationLineChart extends StatelessWidget {
  const HydrationLineChart({
    super.key,
    required this.values,
    required this.goal,
    this.height = 70,
  });

  final List<int> values;
  final int goal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _LinePainter(values, goal)),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in const ['Seg', 'Qua', 'Sex', 'Dom'])
              Text(
                label,
                style: t.labelSmall?.copyWith(color: AppColors.outline),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.goal);

  final List<int> values;
  final int goal;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = max(goal * 1.2, values.reduce(max).toDouble());
    double y(num v) => size.height - (v / maxV) * size.height;
    final dx = values.length == 1 ? 0.0 : size.width / (values.length - 1);

    // Meta tracejada.
    final goalPaint = Paint()
      ..color = AppColors.hydration.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final gy = y(goal);
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, gy),
        Offset(min(x + 4, size.width), gy),
        goalPaint,
      );
    }

    final points = [
      for (var i = 0; i < values.length; i++) Offset(i * dx, y(values[i])),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = (p0.dx + p1.dx) / 2;
      path.cubicTo(mid, p0.dy, mid, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.hydration.withValues(alpha: 0.22),
            AppColors.hydration.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.tertiaryContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.goal != goal || old.values.join() != values.join();
}
