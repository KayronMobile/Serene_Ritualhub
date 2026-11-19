/// Configuração dos lembretes inteligentes.
class ReminderSettings {
  const ReminderSettings({
    this.ritualStartEnabled = true,
    this.waterEnabled = true,
    this.waterStartMinutes = 8 * 60,
    this.waterEndMinutes = 21 * 60,
    this.waterIntervalMinutes = 90,
    this.screensOffEnabled = true,
    this.screensOffMinutes = 21 * 60 + 30,
    this.vulnerableWeekday,
    this.vulnerableLeadMinutes = 30,
    this.streakEnabled = true,
    this.streakMinutes = 20 * 60,
    this.comebackEnabled = true,
  });

  /// Notificação no início (com antecedência) de cada ritual.
  final bool ritualStartEnabled;

  /// Intervalos de água ao longo do dia.
  final bool waterEnabled;
  final int waterStartMinutes;
  final int waterEndMinutes;
  final int waterIntervalMinutes;

  /// Alerta de "desligar telas" à noite.
  final bool screensOffEnabled;
  final int screensOffMinutes;

  /// Dia da semana de maior falha detectado no relatório (1-7). Quando
  /// definido, o alerta de telas é antecipado em [vulnerableLeadMinutes].
  final int? vulnerableWeekday;
  final int vulnerableLeadMinutes;

  /// Resumo diário da sequência de dias.
  final bool streakEnabled;
  final int streakMinutes;

  /// Incentivo para voltar ao app após alguns dias sem abri-lo.
  final bool comebackEnabled;

  /// Horários de lembrete de água entre início e fim.
  List<int> get waterSlots {
    if (waterIntervalMinutes <= 0) return const [];
    return [
      for (
        var m = waterStartMinutes;
        m <= waterEndMinutes;
        m += waterIntervalMinutes
      )
        m,
    ];
  }

  ReminderSettings copyWith({
    bool? ritualStartEnabled,
    bool? waterEnabled,
    int? waterStartMinutes,
    int? waterEndMinutes,
    int? waterIntervalMinutes,
    bool? screensOffEnabled,
    int? screensOffMinutes,
    int? vulnerableWeekday,
    bool clearVulnerableWeekday = false,
    int? vulnerableLeadMinutes,
    bool? streakEnabled,
    int? streakMinutes,
    bool? comebackEnabled,
  }) => ReminderSettings(
    ritualStartEnabled: ritualStartEnabled ?? this.ritualStartEnabled,
    waterEnabled: waterEnabled ?? this.waterEnabled,
    waterStartMinutes: waterStartMinutes ?? this.waterStartMinutes,
    waterEndMinutes: waterEndMinutes ?? this.waterEndMinutes,
    waterIntervalMinutes: waterIntervalMinutes ?? this.waterIntervalMinutes,
    screensOffEnabled: screensOffEnabled ?? this.screensOffEnabled,
    screensOffMinutes: screensOffMinutes ?? this.screensOffMinutes,
    vulnerableWeekday: clearVulnerableWeekday
        ? null
        : (vulnerableWeekday ?? this.vulnerableWeekday),
    vulnerableLeadMinutes: vulnerableLeadMinutes ?? this.vulnerableLeadMinutes,
    streakEnabled: streakEnabled ?? this.streakEnabled,
    streakMinutes: streakMinutes ?? this.streakMinutes,
    comebackEnabled: comebackEnabled ?? this.comebackEnabled,
  );

  Map<String, Object?> toJson() => {
    'ritualStartEnabled': ritualStartEnabled,
    'waterEnabled': waterEnabled,
    'waterStartMinutes': waterStartMinutes,
    'waterEndMinutes': waterEndMinutes,
    'waterIntervalMinutes': waterIntervalMinutes,
    'screensOffEnabled': screensOffEnabled,
    'screensOffMinutes': screensOffMinutes,
    'vulnerableWeekday': vulnerableWeekday,
    'vulnerableLeadMinutes': vulnerableLeadMinutes,
    'streakEnabled': streakEnabled,
    'streakMinutes': streakMinutes,
    'comebackEnabled': comebackEnabled,
  };

  factory ReminderSettings.fromJson(Map<String, Object?> json) =>
      ReminderSettings(
        ritualStartEnabled: (json['ritualStartEnabled'] as bool?) ?? true,
        waterEnabled: (json['waterEnabled'] as bool?) ?? true,
        waterStartMinutes: (json['waterStartMinutes'] as int?) ?? 480,
        waterEndMinutes: (json['waterEndMinutes'] as int?) ?? 1260,
        waterIntervalMinutes: (json['waterIntervalMinutes'] as int?) ?? 90,
        screensOffEnabled: (json['screensOffEnabled'] as bool?) ?? true,
        screensOffMinutes: (json['screensOffMinutes'] as int?) ?? 1290,
        vulnerableWeekday: json['vulnerableWeekday'] as int?,
        vulnerableLeadMinutes: (json['vulnerableLeadMinutes'] as int?) ?? 30,
        streakEnabled: (json['streakEnabled'] as bool?) ?? true,
        streakMinutes: (json['streakMinutes'] as int?) ?? 1200,
        comebackEnabled: (json['comebackEnabled'] as bool?) ?? true,
      );
}

/// Uma notificação concreta a ser agendada pelo serviço de notificações.
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.minutesOfDay,
    this.weekday,
    this.date,
    this.channel = ReminderChannel.rituals,
  });

  final int id;
  final String title;
  final String body;
  final int minutesOfDay;

  /// Se definido, repete semanalmente neste dia (1-7).
  final int? weekday;

  /// Se definido, dispara uma única vez nesta data.
  final DateTime? date;
  final ReminderChannel channel;

  bool get isDaily => weekday == null && date == null;
}

enum ReminderChannel { rituals, water, wellbeing, streak, engagement }
