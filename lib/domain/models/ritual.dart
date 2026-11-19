/// Período do dia ao qual o ritual pertence.
enum RitualPeriod {
  morning('Manhã'),
  afternoon('Tarde'),
  night('Noite');

  const RitualPeriod(this.label);

  final String label;

  String get eyebrow => switch (this) {
    RitualPeriod.morning => 'Ritual matinal',
    RitualPeriod.afternoon => 'Ritual da tarde',
    RitualPeriod.night => 'Ritual noturno',
  };
}

/// Métrica de saúde que um passo alimenta automaticamente ao ser concluído.
enum HealthMetric { water, sleep, activity, reading }

/// Tipo do bloco de ação. Define ícone, cor e integração com rastreadores.
enum StepType {
  hydration('Meta de Volume', HealthMetric.water),
  movement('Temporizador Guiado', HealthMetric.activity),
  breathing('Pranayama / Foco', null),
  meditation('Meditação Guiada', null),
  reading('Leitura', HealthMetric.reading),
  journaling('Escrita / Diário', null),
  custom('Livre', null);

  const StepType(this.label, this.metric);

  final String label;
  final HealthMetric? metric;
}

/// Um passo (bloco) encadeado dentro de um ritual.
class RitualStep {
  const RitualStep({
    required this.id,
    required this.title,
    required this.type,
    required this.durationSeconds,
    this.description = '',
    this.instruction = '',
    this.ambientSound,
    this.tip,
    this.waterMl,
    this.pages,
  });

  final String id;
  final String title;
  final StepType type;
  final int durationSeconds;

  /// Resumo curto (ex.: "500ml de água morna com limão").
  final String description;

  /// Instrução exibida no player guiado.
  final String instruction;

  /// Som ambiente opcional (ex.: "Chuva Suave na Floresta").
  final String? ambientSound;

  /// Dica corporal exibida no player.
  final String? tip;

  /// Volume de água (ml) contabilizado ao concluir um passo de hidratação.
  final int? waterMl;

  /// Páginas de leitura (informativo).
  final int? pages;

  int get durationMinutes => (durationSeconds / 60).ceil();

  RitualStep copyWith({
    String? title,
    StepType? type,
    int? durationSeconds,
    String? description,
    String? instruction,
    String? ambientSound,
    bool clearAmbientSound = false,
    String? tip,
    int? waterMl,
    int? pages,
  }) => RitualStep(
    id: id,
    title: title ?? this.title,
    type: type ?? this.type,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    description: description ?? this.description,
    instruction: instruction ?? this.instruction,
    ambientSound: clearAmbientSound
        ? null
        : (ambientSound ?? this.ambientSound),
    tip: tip ?? this.tip,
    waterMl: waterMl ?? this.waterMl,
    pages: pages ?? this.pages,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'durationSeconds': durationSeconds,
    'description': description,
    'instruction': instruction,
    'ambientSound': ambientSound,
    'tip': tip,
    'waterMl': waterMl,
    'pages': pages,
  };

  factory RitualStep.fromJson(Map<String, Object?> json) => RitualStep(
    id: json['id']! as String,
    title: json['title']! as String,
    type: StepType.values.byName(json['type']! as String),
    durationSeconds: json['durationSeconds']! as int,
    description: (json['description'] as String?) ?? '',
    instruction: (json['instruction'] as String?) ?? '',
    ambientSound: json['ambientSound'] as String?,
    tip: json['tip'] as String?,
    waterMl: json['waterMl'] as int?,
    pages: json['pages'] as int?,
  );
}

/// Ritual estruturado: sequência de passos executados por um player guiado.
class Ritual {
  const Ritual({
    required this.id,
    required this.name,
    required this.period,
    required this.steps,
    required this.activeWeekdays,
    required this.startMinutes,
    this.reminderEnabled = true,
    this.reminderLeadMinutes = 15,
    this.focusMode = false,
    this.linkedChallengeId,
    this.shareWithTribe = false,
  });

  final String id;
  final String name;
  final RitualPeriod period;
  final List<RitualStep> steps;

  /// Dias ativos: 1 = segunda ... 7 = domingo ([DateTime.weekday]).
  final Set<int> activeWeekdays;

  /// Horário de início em minutos desde a meia-noite.
  final int startMinutes;

  /// "Lembrete suave": notificação antes do início.
  final bool reminderEnabled;
  final int reminderLeadMinutes;

  /// "Pausa de telas (Zen)".
  final bool focusMode;

  /// Desafio coletivo vinculado (check-in automático ao concluir).
  final String? linkedChallengeId;

  /// Compartilhar conclusão com a tribo.
  final bool shareWithTribe;

  int get totalSeconds => steps.fold(0, (sum, s) => sum + s.durationSeconds);

  int get totalMinutes => (totalSeconds / 60).round();

  bool isScheduledOn(DateTime day) => activeWeekdays.contains(day.weekday);

  Ritual copyWith({
    String? name,
    RitualPeriod? period,
    List<RitualStep>? steps,
    Set<int>? activeWeekdays,
    int? startMinutes,
    bool? reminderEnabled,
    int? reminderLeadMinutes,
    bool? focusMode,
    String? linkedChallengeId,
    bool clearLinkedChallenge = false,
    bool? shareWithTribe,
  }) => Ritual(
    id: id,
    name: name ?? this.name,
    period: period ?? this.period,
    steps: steps ?? this.steps,
    activeWeekdays: activeWeekdays ?? this.activeWeekdays,
    startMinutes: startMinutes ?? this.startMinutes,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
    focusMode: focusMode ?? this.focusMode,
    linkedChallengeId: clearLinkedChallenge
        ? null
        : (linkedChallengeId ?? this.linkedChallengeId),
    shareWithTribe: shareWithTribe ?? this.shareWithTribe,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'period': period.name,
    'steps': steps.map((s) => s.toJson()).toList(),
    'activeWeekdays': activeWeekdays.toList()..sort(),
    'startMinutes': startMinutes,
    'reminderEnabled': reminderEnabled,
    'reminderLeadMinutes': reminderLeadMinutes,
    'focusMode': focusMode,
    'linkedChallengeId': linkedChallengeId,
    'shareWithTribe': shareWithTribe,
  };

  factory Ritual.fromJson(Map<String, Object?> json) => Ritual(
    id: json['id']! as String,
    name: json['name']! as String,
    period: RitualPeriod.values.byName(json['period']! as String),
    steps: (json['steps']! as List<Object?>)
        .map((e) => RitualStep.fromJson(e! as Map<String, Object?>))
        .toList(),
    activeWeekdays: (json['activeWeekdays']! as List<Object?>)
        .map((e) => e! as int)
        .toSet(),
    startMinutes: json['startMinutes']! as int,
    reminderEnabled: (json['reminderEnabled'] as bool?) ?? true,
    reminderLeadMinutes: (json['reminderLeadMinutes'] as int?) ?? 15,
    focusMode: (json['focusMode'] as bool?) ?? false,
    linkedChallengeId: json['linkedChallengeId'] as String?,
    shareWithTribe: (json['shareWithTribe'] as bool?) ?? false,
  );
}

/// Registro diário de execução de um ritual.
class RitualLog {
  const RitualLog({
    required this.ritualId,
    required this.date,
    required this.completedStepIds,
    required this.skippedStepIds,
    required this.totalSteps,
    this.completedAt,
    this.guidedSeconds = 0,
  });

  final String ritualId;

  /// Data (somente dia) a que o registro pertence.
  final DateTime date;
  final Set<String> completedStepIds;
  final Set<String> skippedStepIds;
  final int totalSteps;

  /// Horário em que todos os passos foram finalizados.
  final DateTime? completedAt;

  /// Tempo efetivamente passado no player guiado.
  final int guidedSeconds;

  bool get isComplete =>
      totalSteps > 0 && completedStepIds.length >= totalSteps;

  /// Sessão concluída sem pular nenhuma etapa.
  bool get isFocused => isComplete && skippedStepIds.isEmpty;

  double get adherence =>
      totalSteps == 0 ? 0 : (completedStepIds.length / totalSteps).clamp(0.0, 1.0);

  RitualLog copyWith({
    Set<String>? completedStepIds,
    Set<String>? skippedStepIds,
    int? totalSteps,
    DateTime? completedAt,
    int? guidedSeconds,
  }) => RitualLog(
    ritualId: ritualId,
    date: date,
    completedStepIds: completedStepIds ?? this.completedStepIds,
    skippedStepIds: skippedStepIds ?? this.skippedStepIds,
    totalSteps: totalSteps ?? this.totalSteps,
    completedAt: completedAt ?? this.completedAt,
    guidedSeconds: guidedSeconds ?? this.guidedSeconds,
  );

  Map<String, Object?> toJson() => {
    'ritualId': ritualId,
    'date': date.toIso8601String(),
    'completedStepIds': completedStepIds.toList(),
    'skippedStepIds': skippedStepIds.toList(),
    'totalSteps': totalSteps,
    'completedAt': completedAt?.toIso8601String(),
    'guidedSeconds': guidedSeconds,
  };

  factory RitualLog.fromJson(Map<String, Object?> json) => RitualLog(
    ritualId: json['ritualId']! as String,
    date: DateTime.parse(json['date']! as String),
    completedStepIds: (json['completedStepIds']! as List<Object?>)
        .cast<String>()
        .toSet(),
    skippedStepIds: ((json['skippedStepIds'] as List<Object?>?) ?? const [])
        .cast<String>()
        .toSet(),
    totalSteps: json['totalSteps']! as int,
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt']! as String),
    guidedSeconds: (json['guidedSeconds'] as int?) ?? 0,
  );
}
