/// Metas diárias dos rastreadores de saúde.
class HealthGoals {
  const HealthGoals({
    this.waterMl = 2500,
    this.sleepMinutes = 480,
    this.activityMinutes = 45,
    this.readingMinutes = 30,
    this.waterIncrementMl = 250,
  });

  final int waterMl;
  final int sleepMinutes;
  final int activityMinutes;
  final int readingMinutes;

  /// Volume adicionado pelo botão rápido do widget de hidratação.
  final int waterIncrementMl;

  HealthGoals copyWith({
    int? waterMl,
    int? sleepMinutes,
    int? activityMinutes,
    int? readingMinutes,
    int? waterIncrementMl,
  }) => HealthGoals(
    waterMl: waterMl ?? this.waterMl,
    sleepMinutes: sleepMinutes ?? this.sleepMinutes,
    activityMinutes: activityMinutes ?? this.activityMinutes,
    readingMinutes: readingMinutes ?? this.readingMinutes,
    waterIncrementMl: waterIncrementMl ?? this.waterIncrementMl,
  );

  Map<String, Object?> toJson() => {
    'waterMl': waterMl,
    'sleepMinutes': sleepMinutes,
    'activityMinutes': activityMinutes,
    'readingMinutes': readingMinutes,
    'waterIncrementMl': waterIncrementMl,
  };

  factory HealthGoals.fromJson(Map<String, Object?> json) => HealthGoals(
    waterMl: (json['waterMl'] as int?) ?? 2500,
    sleepMinutes: (json['sleepMinutes'] as int?) ?? 480,
    activityMinutes: (json['activityMinutes'] as int?) ?? 45,
    readingMinutes: (json['readingMinutes'] as int?) ?? 30,
    waterIncrementMl: (json['waterIncrementMl'] as int?) ?? 250,
  );
}

/// Registro diário dos rastreadores (água, sono, atividade e leitura).
class DailyHealthLog {
  const DailyHealthLog({
    required this.date,
    this.waterMl = 0,
    this.sleepMinutes = 0,
    this.deepSleepPercent,
    this.activityMinutes = 0,
    this.readingMinutes = 0,
    this.updatedAt,
  });

  factory DailyHealthLog.empty(DateTime date) => DailyHealthLog(date: date);

  final DateTime date;
  final int waterMl;
  final int sleepMinutes;

  /// Qualidade/eficácia do sono informada pelo usuário (0-100).
  final int? deepSleepPercent;
  final int activityMinutes;
  final int readingMinutes;
  final DateTime? updatedAt;

  double waterProgress(HealthGoals g) => _ratio(waterMl, g.waterMl);
  double sleepProgress(HealthGoals g) => _ratio(sleepMinutes, g.sleepMinutes);
  double activityProgress(HealthGoals g) =>
      _ratio(activityMinutes, g.activityMinutes);
  double readingProgress(HealthGoals g) =>
      _ratio(readingMinutes, g.readingMinutes);

  static double _ratio(int value, int goal) =>
      goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0);

  DailyHealthLog copyWith({
    int? waterMl,
    int? sleepMinutes,
    int? deepSleepPercent,
    int? activityMinutes,
    int? readingMinutes,
    DateTime? updatedAt,
  }) => DailyHealthLog(
    date: date,
    waterMl: waterMl ?? this.waterMl,
    sleepMinutes: sleepMinutes ?? this.sleepMinutes,
    deepSleepPercent: deepSleepPercent ?? this.deepSleepPercent,
    activityMinutes: activityMinutes ?? this.activityMinutes,
    readingMinutes: readingMinutes ?? this.readingMinutes,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String(),
    'waterMl': waterMl,
    'sleepMinutes': sleepMinutes,
    'deepSleepPercent': deepSleepPercent,
    'activityMinutes': activityMinutes,
    'readingMinutes': readingMinutes,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory DailyHealthLog.fromJson(Map<String, Object?> json) => DailyHealthLog(
    date: DateTime.parse(json['date']! as String),
    waterMl: (json['waterMl'] as int?) ?? 0,
    sleepMinutes: (json['sleepMinutes'] as int?) ?? 0,
    deepSleepPercent: json['deepSleepPercent'] as int?,
    activityMinutes: (json['activityMinutes'] as int?) ?? 0,
    readingMinutes: (json['readingMinutes'] as int?) ?? 0,
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt']! as String),
  );
}
