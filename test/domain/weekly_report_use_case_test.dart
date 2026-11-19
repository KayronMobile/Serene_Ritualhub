import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/domain/models/ritual.dart';
import 'package:ritualhub/domain/models/weekly_report.dart';
import 'package:ritualhub/utils/dates.dart';
import 'package:ritualhub/utils/result.dart';

import '../../testing/fakes/fake_environment.dart';

void main() {
  late FakeEnvironment env;

  setUp(() async {
    env = await FakeEnvironment.create(); // quarta-feira, 18/11/2026
    // Cenário controlado: remove os rituais de demonstração.
    final seeded = (await env.rituals.getRituals() as Ok<List<Ritual>>).value;
    for (final r in seeded) {
      await env.rituals.deleteRitual(r.id);
    }
    await env.rituals.saveRitual(
      const Ritual(
        id: 'night',
        name: 'Ritual Noturno',
        period: RitualPeriod.night,
        steps: [
          RitualStep(
            id: 'a',
            title: 'Chá',
            type: StepType.custom,
            durationSeconds: 300,
          ),
          RitualStep(
            id: 'b',
            title: 'Leitura',
            type: StepType.reading,
            durationSeconds: 600,
          ),
        ],
        activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
        startMinutes: 21 * 60,
      ),
    );
    // 4 semanas concluídas, exceto às sextas-feiras.
    final today = Dates.dateOnly(env.now);
    for (var back = 1; back <= 28; back++) {
      final day = Dates.addDays(today, -back);
      if (day.weekday == DateTime.friday) continue;
      await env.rituals.saveLog(
        RitualLog(
          ritualId: 'night',
          date: day,
          completedStepIds: const {'a', 'b'},
          skippedStepIds: const {},
          totalSteps: 2,
          completedAt: day.add(const Duration(hours: 21, minutes: 20)),
          guidedSeconds: 900,
        ),
      );
    }
  });

  test('detecta a sexta-feira como dia de maior falha', () async {
    final r = await env.weeklyReport.build(weekStart: env.now, now: env.now);
    final report = (r as Ok<WeeklyReport>).value;

    expect(report.vulnerability, isNotNull);
    expect(report.vulnerability!.weekday, DateTime.friday);
    expect(report.vulnerability!.adherence, 0);
    expect(report.vulnerability!.isNight, isTrue);
  });

  test(
    'semana atual: dias futuros sem aderência e média dos dias passados',
    () async {
      final r = await env.weeklyReport.build(weekStart: env.now, now: env.now);
      final report = (r as Ok<WeeklyReport>).value;

      expect(report.days, hasLength(7));
      expect(report.weekStart.weekday, DateTime.monday);
      // Seg e Ter concluídos; Qua (hoje) em aberto; Qui..Dom no futuro.
      expect(report.days[0].adherence, 1);
      expect(report.days[1].adherence, 1);
      expect(report.days[2].adherence, 0);
      expect(report.days.skip(3).every((d) => d.isFuture), isTrue);
      expect(report.consistency, closeTo(2 / 3, 0.001));
      expect(report.guidedMinutes, 30); // 2 × 900s
    },
  );

  test('semana anterior inclui a sexta-feira com 0%', () async {
    final lastWeek = Dates.addDays(env.now, -7);
    final r = await env.weeklyReport.build(weekStart: lastWeek, now: env.now);
    final report = (r as Ok<WeeklyReport>).value;

    final friday = report.days.firstWhere(
      (d) => d.date.weekday == DateTime.friday,
    );
    expect(friday.adherence, 0);
    expect(report.consistency, closeTo(6 / 7, 0.001));
  });
}
