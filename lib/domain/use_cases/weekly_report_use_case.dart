import 'dart:math';

import '../../data/repositories/health/health_repository.dart';
import '../../data/repositories/ritual/ritual_repository.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../models/health.dart';
import '../models/ritual.dart';
import '../models/weekly_report.dart';
import 'consistency_calculator.dart';

/// Monta o relatório semanal de consistência combinando os repositórios de
/// rituais e de saúde (lógica compartilhada → camada de domínio).
class WeeklyReportUseCase {
  WeeklyReportUseCase({
    required RitualRepository ritualRepository,
    required HealthRepository healthRepository,
  }) : _rituals = ritualRepository,
       _health = healthRepository;

  final RitualRepository _rituals;
  final HealthRepository _health;

  Future<Result<WeeklyReport>> build({
    required DateTime weekStart,
    required DateTime now,
  }) async {
    final start = Dates.startOfWeek(weekStart);
    final end = Dates.addDays(start, 6);
    final today = Dates.dateOnly(now);
    final historyStart = [
      Dates.addDays(start, -28),
      Dates.addDays(today, -60),
    ].reduce((a, b) => a.isBefore(b) ? a : b);

    final ritualsResult = await _rituals.getRituals();
    if (ritualsResult is Error<List<Ritual>>) {
      return Result.error(ritualsResult.error);
    }
    final rituals = (ritualsResult as Ok<List<Ritual>>).value;

    final logsResult = await _rituals.getLogs(historyStart, end);
    if (logsResult is Error<List<RitualLog>>) {
      return Result.error(logsResult.error);
    }
    final logs = (logsResult as Ok<List<RitualLog>>).value;

    final goalsResult = await _health.getGoals();
    if (goalsResult is Error<HealthGoals>) {
      return Result.error(goalsResult.error);
    }
    final goals = (goalsResult as Ok<HealthGoals>).value;

    final healthResult = await _health.getLogs(start, end);
    if (healthResult is Error<List<DailyHealthLog>>) {
      return Result.error(healthResult.error);
    }
    final healthLogs = (healthResult as Ok<List<DailyHealthLog>>).value;

    final days = _week(start, rituals, logs, today);
    final prevDays = _week(Dates.addDays(start, -7), rituals, logs, today);

    // Hidratação e sono: média dos dias já encerrados (hoje entra apenas se
    // for o único dia disponível da semana).
    final closed = healthLogs.where((l) => l.date.isBefore(today)).toList();
    final sample = closed.isNotEmpty
        ? closed
        : healthLogs.where((l) => !l.date.isAfter(today)).toList();
    final avgWater = sample.isEmpty
        ? 0
        : sample.fold<int>(0, (s, l) => s + l.waterMl) ~/ sample.length;
    final sleeps = sample
        .where((l) => l.sleepMinutes > 0)
        .map((l) => l.sleepMinutes)
        .toList();
    final avgSleep = sleeps.isEmpty
        ? 0
        : sleeps.reduce((a, b) => a + b) ~/ sleeps.length;
    final sleepStd = sleeps.length < 2
        ? 0
        : sqrt(
            sleeps
                    .map((s) => pow(s - avgSleep, 2))
                    .reduce((a, b) => a + b) /
                sleeps.length,
          ).round();

    int guided(DateTime from, DateTime to) =>
        logs
            .where((l) => !l.date.isBefore(from) && !l.date.isAfter(to))
            .fold<int>(0, (s, l) => s + l.guidedSeconds) ~/
        60;

    return Result.ok(
      WeeklyReport(
        weekStart: start,
        days: days,
        consistency: _average(days),
        previousConsistency: _average(prevDays),
        waterByDay: healthLogs.map((l) => l.waterMl).toList(),
        waterGoalMl: goals.waterMl,
        averageWaterMl: avgWater,
        averageSleepMinutes: avgSleep,
        sleepRegularityMinutes: sleepStd,
        guidedMinutes: guided(start, end),
        previousGuidedMinutes: guided(
          Dates.addDays(start, -7),
          Dates.addDays(start, -1),
        ),
        streakDays: ConsistencyCalculator.ritualStreak(
          rituals: rituals,
          logs: logs,
          now: now,
        ),
        vulnerability: _vulnerability(rituals, logs, today),
      ),
    );
  }

  List<DayAdherence> _week(
    DateTime start,
    List<Ritual> rituals,
    List<RitualLog> logs,
    DateTime today,
  ) {
    return [
      for (var i = 0; i < 7; i++) _day(Dates.addDays(start, i), rituals, logs, today),
    ];
  }

  DayAdherence _day(
    DateTime day,
    List<Ritual> rituals,
    List<RitualLog> logs,
    DateTime today,
  ) {
    final future = day.isAfter(today);
    var scheduled = 0;
    var completed = 0;
    for (final r in rituals.where((r) => r.isScheduledOn(day))) {
      scheduled += r.steps.length;
      final log = logs.where(
        (l) => l.ritualId == r.id && Dates.isSameDay(l.date, day),
      );
      if (log.isNotEmpty) {
        completed += min(log.first.completedStepIds.length, r.steps.length);
      }
    }
    return DayAdherence(
      date: day,
      adherence: scheduled == 0 || future ? null : completed / scheduled,
      scheduledSteps: scheduled,
      completedSteps: completed,
      isFuture: future,
    );
  }

  double _average(List<DayAdherence> days) {
    final values = days
        .where((d) => d.adherence != null)
        .map((d) => d.adherence!)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Detecta o dia da semana com menor aderência nas últimas 4 semanas.
  VulnerabilityInsight? _vulnerability(
    List<Ritual> rituals,
    List<RitualLog> logs,
    DateTime today,
  ) {
    // weekday -> ritualId -> lista de aderências
    final samples = <int, Map<String, List<double>>>{};
    for (var back = 1; back <= 28; back++) {
      final day = Dates.addDays(today, -back);
      for (final r in rituals.where((r) => r.isScheduledOn(day))) {
        final match = logs.where(
          (l) => l.ritualId == r.id && Dates.isSameDay(l.date, day),
        );
        final adherence = match.isEmpty ? 0.0 : match.first.adherence;
        samples
            .putIfAbsent(day.weekday, () => {})
            .putIfAbsent(r.id, () => [])
            .add(adherence);
      }
    }
    if (samples.isEmpty) return null;

    int? worstDay;
    var worstAvg = 2.0;
    samples.forEach((weekday, byRitual) {
      final all = byRitual.values.expand((v) => v).toList();
      if (all.length < 2) return;
      final avg = all.reduce((a, b) => a + b) / all.length;
      if (avg < worstAvg) {
        worstAvg = avg;
        worstDay = weekday;
      }
    });
    if (worstDay == null || worstAvg >= 0.85) return null;

    final byRitual = samples[worstDay]!;
    String? worstRitualId;
    var worstRitualAvg = 2.0;
    byRitual.forEach((id, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      if (avg < worstRitualAvg) {
        worstRitualAvg = avg;
        worstRitualId = id;
      }
    });
    final ritual = rituals.firstWhere((r) => r.id == worstRitualId);
    return VulnerabilityInsight(
      weekday: worstDay!,
      adherence: worstAvg,
      ritualName: ritual.name,
      isNight: ritual.period == RitualPeriod.night,
    );
  }
}
