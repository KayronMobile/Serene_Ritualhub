import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/domain/models/health.dart';
import 'package:ritualhub/ui/home/widgets/metric_cards.dart';

/// Cartões de métricas da tela "Hoje" com valores reais (água, sono com
/// eficácia, leitura, movimento) em telas estreitas e fonte ampliada.
void main() {
  final logs = {
    'vazio': DailyHealthLog.empty(DateTime(2026, 11, 18)),
    'cheio': DailyHealthLog(
      date: DateTime(2026, 11, 18),
      waterMl: 12500,
      sleepMinutes: 8 * 60 + 30,
      deepSleepPercent: 100,
      activityMinutes: 125,
      readingMinutes: 140,
    ),
  };

  for (final width in const [320.0, 360.0, 412.0]) {
    for (final scale in const [1.0, 1.3]) {
      for (final entry in logs.entries) {
        testWidgets('métricas ${entry.key} @ ${width.toInt()} x$scale', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: MetricGrid(
                      log: entry.value,
                      goals: const HealthGoals(),
                      onAddWater: (_) {},
                      onLogSleep: (_, _) {},
                      onAddReading: (_) {},
                      onAddActivity: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (entry.key == 'cheio') {
            final pill = tester.renderObject<RenderParagraph>(
              find.text('Meta ✓'),
            );
            expect(pill.didExceedMaxLines, isFalse);
            // Legível: ao menos 70% do tamanho original.
            final box = tester.getSize(find.text('Meta ✓'));
            expect(box.height, greaterThan(9));
          }
        });
      }
    }
  }
}
