/// Aderência de um dia da semana aos rituais agendados.
class DayAdherence {
  const DayAdherence({
    required this.date,
    required this.adherence,
    required this.scheduledSteps,
    required this.completedSteps,
    required this.isFuture,
  });

  final DateTime date;

  /// 0..1 — `null` quando não havia ritual agendado.
  final double? adherence;
  final int scheduledSteps;
  final int completedSteps;
  final bool isFuture;
}

/// Insight sobre o dia da semana de maior falha.
class VulnerabilityInsight {
  const VulnerabilityInsight({
    required this.weekday,
    required this.adherence,
    required this.ritualName,
    required this.isNight,
  });

  /// 1 = segunda ... 7 = domingo.
  final int weekday;
  final double adherence;
  final String ritualName;
  final bool isNight;
}

/// Relatório semanal de consistência.
class WeeklyReport {
  const WeeklyReport({
    required this.weekStart,
    required this.days,
    required this.consistency,
    required this.previousConsistency,
    required this.waterByDay,
    required this.waterGoalMl,
    required this.averageWaterMl,
    required this.averageSleepMinutes,
    required this.sleepRegularityMinutes,
    required this.guidedMinutes,
    required this.previousGuidedMinutes,
    required this.streakDays,
    this.vulnerability,
  });

  final DateTime weekStart;
  final List<DayAdherence> days;

  /// Média de aderência (0..1) dos dias já transcorridos.
  final double consistency;
  final double previousConsistency;

  /// Água consumida em cada dia (ml), seg..dom.
  final List<int> waterByDay;
  final int waterGoalMl;
  final int averageWaterMl;
  final int averageSleepMinutes;

  /// Desvio padrão (minutos) da duração do sono — menor = mais regular.
  final int sleepRegularityMinutes;
  final int guidedMinutes;
  final int previousGuidedMinutes;
  final int streakDays;
  final VulnerabilityInsight? vulnerability;

  double get consistencyDelta => consistency - previousConsistency;

  double get waterGoalRatio =>
      waterGoalMl == 0 ? 0 : averageWaterMl / waterGoalMl;
}
