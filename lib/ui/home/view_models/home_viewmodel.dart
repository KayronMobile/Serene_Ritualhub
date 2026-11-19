import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/challenge/challenge_repository.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../data/repositories/ritual/ritual_repository.dart';
import '../../../domain/models/challenge.dart';
import '../../../domain/models/health.dart';
import '../../../domain/models/ritual.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/consistency_calculator.dart';
import '../../../domain/use_cases/plan_reminders_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Estado de um ritual agendado para hoje.
class TodayRitual {
  const TodayRitual({required this.ritual, this.log});

  final Ritual ritual;
  final RitualLog? log;

  int get completedCount => ritual.steps
      .where((s) => log?.completedStepIds.contains(s.id) ?? false)
      .length;

  bool get isDone => completedCount >= ritual.steps.length;

  double get progress =>
      ritual.steps.isEmpty ? 0 : completedCount / ritual.steps.length;

  RitualStep? get nextStep {
    for (final s in ritual.steps) {
      if (!(log?.completedStepIds.contains(s.id) ?? false)) return s;
    }
    return null;
  }

  bool isStepDone(RitualStep s) => log?.completedStepIds.contains(s.id) ?? false;
}

/// Resumo de um desafio para o carrossel "Desafios em Tribo".
class ChallengeSummary {
  const ChallengeSummary({
    required this.challenge,
    required this.day,
    required this.checkInsToday,
    required this.recentAuthors,
  });

  final Challenge challenge;
  final int day;
  final int checkInsToday;
  final List<UserProfile> recentAuthors;
}

class HomeViewModel extends ViewModel {
  HomeViewModel({
    required AuthRepository authRepository,
    required RitualRepository ritualRepository,
    required HealthRepository healthRepository,
    required ChallengeRepository challengeRepository,
    required PlanRemindersUseCase planReminders,
    DateTime Function()? clock,
  }) : _auth = authRepository,
       _rituals = ritualRepository,
       _health = healthRepository,
       _challenges = challengeRepository,
       _planReminders = planReminders,
       _clock = clock ?? DateTime.now {
    load = Command0(_load)..execute();
    addWater = Command1<void, int>(_addWater);
    logSleep = Command1<void, ({int minutes, int? quality})>(_logSleep);
    addActivity = Command1<void, int>(_addActivity);
    addReading = Command1<void, int>(_addReading);
    _rituals.addListener(_onDataChanged);
    _health.addListener(_onDataChanged);
    _challenges.addListener(_onDataChanged);
    _auth.addListener(_onDataChanged);
  }

  final _log = Logger('HomeViewModel');
  final AuthRepository _auth;
  final RitualRepository _rituals;
  final HealthRepository _health;
  final ChallengeRepository _challenges;
  final PlanRemindersUseCase _planReminders;
  final DateTime Function() _clock;

  late final Command0<void> load;
  late final Command1<void, int> addWater;
  late final Command1<void, ({int minutes, int? quality})> logSleep;
  late final Command1<void, int> addActivity;
  late final Command1<void, int> addReading;

  static const _quotes = [
    'A calma é o ponto de partida do seu dia.',
    'Pequenos gestos repetidos com gentileza transformam destinos.',
    'Não é sobre perfeição, é sobre presença.',
    'Cada ritual é um voto silencioso de cuidado consigo.',
    'O corpo agradece o que a mente decide repetir.',
    'Respire. O ritmo certo é o que você consegue sustentar.',
    'Constância é a forma mais bonita de coragem.',
  ];

  UserProfile? get user => _auth.currentUser;

  DateTime get now => _clock();

  String get greeting {
    final h = now.hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get dateLabel => Dates.longDate(now);

  String get quote =>
      _quotes[Dates.daysBetween(DateTime(now.year), now) % _quotes.length];

  int _streak = 0;
  int get streak => _streak;

  List<TodayRitual> _today = const [];
  List<TodayRitual> get todayRituals => _today;

  TodayRitual? _featured;

  /// Ritual em destaque (o próximo a ser feito no momento do dia).
  TodayRitual? get featured => _featured;

  /// Demais rituais de hoje (exibidos como cards secundários).
  List<TodayRitual> get otherRituals =>
      _today.where((r) => r.ritual.id != _featured?.ritual.id).toList();

  DailyHealthLog? _healthLog;
  DailyHealthLog? get healthLog => _healthLog;

  HealthGoals _goals = const HealthGoals();
  HealthGoals get goals => _goals;

  List<ChallengeSummary> _activeChallenges = const [];
  List<ChallengeSummary> get activeChallenges => _activeChallenges;

  String get updatedLabel {
    final at = _healthLog?.updatedAt;
    if (at == null) return 'Sem registros hoje';
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'Atualizado agora';
    if (diff.inMinutes < 60) return 'Atualizado há ${diff.inMinutes} min';
    return 'Atualizado há ${diff.inHours}h';
  }

  void _onDataChanged() => scheduleReload(_load);

  Future<Result<void>> _load() async {
    final today = Dates.dateOnly(now);

    final ritualsR = await _rituals.getRituals();
    if (ritualsR is Error<List<Ritual>>) return Result.error(ritualsR.error);
    final rituals = (ritualsR as Ok<List<Ritual>>).value;

    final logsR = await _rituals.getLogs(Dates.addDays(today, -60), today);
    if (logsR is Error<List<RitualLog>>) return Result.error(logsR.error);
    final logs = (logsR as Ok<List<RitualLog>>).value;

    final healthR = await _health.getLog(today);
    if (healthR is Error<DailyHealthLog>) return Result.error(healthR.error);
    _healthLog = (healthR as Ok<DailyHealthLog>).value;

    final goalsR = await _health.getGoals();
    if (goalsR is Ok<HealthGoals>) _goals = goalsR.value;

    _streak = ConsistencyCalculator.ritualStreak(
      rituals: rituals,
      logs: logs,
      now: now,
    );

    _today = [
      for (final r in rituals.where((r) => r.isScheduledOn(today)))
        TodayRitual(
          ritual: r,
          log: logs
              .where((l) => l.ritualId == r.id && Dates.isSameDay(l.date, today))
              .firstOrNull,
        ),
    ];
    _featured = _pickFeatured(_today);

    final challengesR = await _challenges.getChallenges();
    if (challengesR is Ok<List<Challenge>>) {
      final summaries = <ChallengeSummary>[];
      for (final c in challengesR.value.where((c) => c.isActive(now))) {
        final ciR = await _challenges.getCheckIns(c.id);
        final todayCis = ciR is Ok<List<CheckIn>>
            ? ciR.value.where((ci) => Dates.isSameDay(ci.createdAt, now)).toList()
            : <CheckIn>[];
        summaries.add(
          ChallengeSummary(
            challenge: c,
            day: c.currentDay(now),
            checkInsToday: todayCis.length,
            recentAuthors: todayCis.map((ci) => ci.author).toList(),
          ),
        );
      }
      _activeChallenges = summaries;
    }

    notifyListeners();
    return const Result.ok(null);
  }

  TodayRitual? _pickFeatured(List<TodayRitual> today) {
    if (today.isEmpty) return null;
    final minutes = now.hour * 60 + now.minute;
    final pending = today.where((r) => !r.isDone).toList();
    if (pending.isEmpty) return today.last;
    // Um ritual já iniciado hoje tem prioridade: retomar é mais fácil.
    final inProgress = pending.where((r) => r.completedCount > 0);
    if (inProgress.isNotEmpty) return inProgress.first;
    // O primeiro ritual pendente que ainda "está na janela" (início + duração
    // + 2h de tolerância); senão, o próximo pendente.
    for (final r in pending) {
      final windowEnd = r.ritual.startMinutes + r.ritual.totalMinutes + 120;
      if (windowEnd >= minutes) return r;
    }
    return pending.last;
  }

  Future<void> _replanReminders({bool requestPermission = false}) async {
    final r = await _planReminders.execute(
      now: now,
      requestPermission: requestPermission,
    );
    if (r case Error(:final error)) {
      _log.warning('Falha ao replanejar lembretes', error);
    }
  }

  /// Replaneja os lembretes (chamado ao abrir o app; pede permissão de
  /// notificação na primeira vez).
  Future<void> refreshReminders() => _replanReminders(requestPermission: true);

  Future<Result<void>> _addWater(int ml) async {
    final r = await _health.addWater(now, ml);
    if (r is Error<DailyHealthLog>) return Result.error(r.error);
    // Lembretes de água são adaptativos: silenciam quando a meta é batida.
    await _replanReminders();
    return const Result.ok(null);
  }

  Future<Result<void>> _logSleep(({int minutes, int? quality}) input) async {
    final r = await _health.setSleep(
      now,
      input.minutes,
      qualityPercent: input.quality,
    );
    return r is Error<DailyHealthLog>
        ? Result.error(r.error)
        : const Result.ok(null);
  }

  Future<Result<void>> _addActivity(int minutes) async {
    final r = await _health.addActivity(now, minutes);
    return r is Error<DailyHealthLog>
        ? Result.error(r.error)
        : const Result.ok(null);
  }

  Future<Result<void>> _addReading(int minutes) async {
    final r = await _health.addReading(now, minutes);
    return r is Error<DailyHealthLog>
        ? Result.error(r.error)
        : const Result.ok(null);
  }

  @override
  void dispose() {
    _rituals.removeListener(_onDataChanged);
    _health.removeListener(_onDataChanged);
    _challenges.removeListener(_onDataChanged);
    _auth.removeListener(_onDataChanged);
    super.dispose();
  }
}
