/// Escopo da conquista: individual ou coletiva (em grupo).
enum AchievementScope { individual, group }

/// Ícones disponíveis para medalhas (mapeados na camada de UI).
enum AchievementIcon {
  sunrise,
  water,
  group,
  focus,
  seedling,
  book,
  moon,
  flame,
}

/// Definição estática de uma medalha.
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.scope,
    required this.target,
    required this.unit,
  });

  final String id;
  final String title;
  final String description;
  final AchievementIcon icon;
  final AchievementScope scope;

  /// Quantidade necessária para desbloquear.
  final int target;

  /// Unidade do progresso (ex.: "Dias", "Sessões").
  final String unit;
}

/// Estado de uma medalha para o usuário.
class Achievement {
  const Achievement({
    required this.definition,
    required this.progress,
    this.unlockedAt,
    this.isNew = false,
  });

  final AchievementDefinition definition;
  final int progress;
  final DateTime? unlockedAt;

  /// Desbloqueada recentemente e ainda não vista.
  final bool isNew;

  bool get unlocked => unlockedAt != null;

  double get ratio => definition.target == 0
      ? 0
      : (progress / definition.target).clamp(0.0, 1.0);

  int get remaining =>
      (definition.target - progress).clamp(0, definition.target);
}

/// Persistência do desbloqueio.
class AchievementUnlock {
  const AchievementUnlock({
    required this.id,
    required this.unlockedAt,
    this.seen = false,
  });

  final String id;
  final DateTime unlockedAt;
  final bool seen;

  AchievementUnlock markSeen() =>
      AchievementUnlock(id: id, unlockedAt: unlockedAt, seen: true);

  Map<String, Object?> toJson() => {
    'id': id,
    'unlockedAt': unlockedAt.toIso8601String(),
    'seen': seen,
  };

  factory AchievementUnlock.fromJson(Map<String, Object?> json) =>
      AchievementUnlock(
        id: json['id']! as String,
        unlockedAt: DateTime.parse(json['unlockedAt']! as String),
        seen: (json['seen'] as bool?) ?? false,
      );
}

/// Catálogo de medalhas do app.
abstract final class AchievementCatalog {
  static const earlyRiser = AchievementDefinition(
    id: 'early_riser',
    title: 'Madrugador Sereno',
    description:
        'Cumprir o ritual matinal antes das 07:30 por 7 dias seguidos sem '
        'interrupção.',
    icon: AchievementIcon.sunrise,
    scope: AchievementScope.individual,
    target: 7,
    unit: 'Dias',
  );

  static const hydrationGuardian = AchievementDefinition(
    id: 'hydration_guardian',
    title: 'Guardião da Hidratação',
    description:
        '10 dias consecutivos batendo integralmente a meta pessoal de água.',
    icon: AchievementIcon.water,
    scope: AchievementScope.individual,
    target: 10,
    unit: 'Dias',
  );

  static const sharedStrength = AchievementDefinition(
    id: 'shared_strength',
    title: 'Força Compartilhada',
    description:
        'Completar um ciclo de desafio coletivo com 100% de presença e '
        'celebração mútua.',
    icon: AchievementIcon.group,
    scope: AchievementScope.group,
    target: 21,
    unit: 'Dias',
  );

  static const focusMaster = AchievementDefinition(
    id: 'focus_master',
    title: 'Mestre do Foco',
    description:
        'Concluir 10 práticas de atenção plena guiada sem pausa ou desvio '
        'de foco.',
    icon: AchievementIcon.focus,
    scope: AchievementScope.individual,
    target: 10,
    unit: 'Sessões',
  );

  static const firstRitual = AchievementDefinition(
    id: 'first_ritual',
    title: 'Primeira Semente',
    description: 'Concluir seu primeiro ritual completo no player guiado.',
    icon: AchievementIcon.seedling,
    scope: AchievementScope.individual,
    target: 1,
    unit: 'Ritual',
  );

  static const tribeInSync = AchievementDefinition(
    id: 'tribe_in_sync',
    title: 'Tribo em Sintonia',
    description:
        'Todos os membros de um desafio fizeram check-in no mesmo dia, 3 '
        'vezes.',
    icon: AchievementIcon.flame,
    scope: AchievementScope.group,
    target: 3,
    unit: 'Dias',
  );

  static const avidReader = AchievementDefinition(
    id: 'avid_reader',
    title: 'Leitor Constante',
    description: 'Acumular 300 minutos de leitura nos últimos 14 dias.',
    icon: AchievementIcon.book,
    scope: AchievementScope.individual,
    target: 300,
    unit: 'Min',
  );

  static const deepRest = AchievementDefinition(
    id: 'deep_rest',
    title: 'Descanso Profundo',
    description: 'Dormir a meta de sono por 5 noites seguidas.',
    icon: AchievementIcon.moon,
    scope: AchievementScope.individual,
    target: 5,
    unit: 'Noites',
  );

  static const all = [
    earlyRiser,
    hydrationGuardian,
    sharedStrength,
    focusMaster,
    firstRitual,
    tribeInSync,
    avidReader,
    deepRest,
  ];
}
