import 'package:flutter/foundation.dart';

import '../../../data/repositories/achievement/achievement_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/challenge/challenge_repository.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../data/repositories/reminder/reminder_repository.dart';
import '../../../data/repositories/ritual/ritual_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/reminder_settings.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/weekly_report.dart';
import '../../../domain/use_cases/evaluate_achievements_use_case.dart';
import '../../../domain/use_cases/plan_reminders_use_case.dart';
import '../../../domain/use_cases/weekly_report_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Relatórios semanais de consistência + medalhas.
class ReportsViewModel extends ViewModel {
  ReportsViewModel({
    required AuthRepository authRepository,
    required RitualRepository ritualRepository,
    required HealthRepository healthRepository,
    required ChallengeRepository challengeRepository,
    required AchievementRepository achievementRepository,
    required ReminderRepository reminderRepository,
    required WeeklyReportUseCase weeklyReport,
    required EvaluateAchievementsUseCase evaluateAchievements,
    required PlanRemindersUseCase planReminders,
    DateTime Function()? clock,
  }) : _auth = authRepository,
       _watched = [ritualRepository, healthRepository, challengeRepository],
       _achievements = achievementRepository,
       _reminders = reminderRepository,
       _weeklyReport = weeklyReport,
       _evaluate = evaluateAchievements,
       _planReminders = planReminders,
       _clock = clock ?? DateTime.now {
    load = Command0(_load)..execute();
    scheduleSmartReminder = Command0(_scheduleSmartReminder);
    markAchievementsSeen = Command0(_markSeen);
    for (final r in _watched) {
      r.addListener(_onChanged);
    }
  }

  final AuthRepository _auth;
  final List<Listenable> _watched;
  final AchievementRepository _achievements;
  final ReminderRepository _reminders;
  final WeeklyReportUseCase _weeklyReport;
  final EvaluateAchievementsUseCase _evaluate;
  final PlanRemindersUseCase _planReminders;
  final DateTime Function() _clock;

  late final Command0<void> load;
  late final Command0<void> scheduleSmartReminder;
  late final Command0<void> markAchievementsSeen;

  UserProfile? get user => _auth.currentUser;

  /// 0 = esta semana, -1 = semana anterior.
  int _weekOffset = 0;
  int get weekOffset => _weekOffset;

  DateTime get weekStart =>
      Dates.addDays(Dates.startOfWeek(_clock()), 7 * _weekOffset);

  String get weekLabel => Dates.weekRange(weekStart);

  String get currentWeekLabel =>
      Dates.weekRange(Dates.startOfWeek(_clock()));

  WeeklyReport? _report;
  WeeklyReport? get report => _report;

  List<Achievement> _medals = const [];
  List<Achievement> get achievements => _medals;

  int get newAchievements => _medals.where((a) => a.isNew).length;

  ReminderSettings? _settings;

  /// O lembrete inteligente do dia vulnerável já está programado.
  bool get smartReminderActive =>
      _report?.vulnerability != null &&
      _settings?.vulnerableWeekday == _report!.vulnerability!.weekday &&
      (_settings?.screensOffEnabled ?? false);

  void _onChanged() => scheduleReload(() async {
    await _load();
  });

  Future<void> selectWeek(int offset) async {
    if (offset == _weekOffset) return;
    _weekOffset = offset;
    notifyListeners();
    await load.execute();
  }

  Future<Result<void>> _load() async {
    final now = _clock();
    final r = await _weeklyReport.build(weekStart: weekStart, now: now);
    if (r is Error<WeeklyReport>) return Result.error(r.error);
    _report = (r as Ok<WeeklyReport>).value;

    final me = user;
    if (me != null) {
      final a = await _evaluate.evaluate(userId: me.id, now: now);
      if (a is Ok<AchievementEvaluation>) _medals = a.value.achievements;
    }
    final s = await _reminders.getSettings();
    if (s is Ok<ReminderSettings>) _settings = s.value;

    notifyListeners();
    return const Result.ok(null);
  }

  /// Antecipa o alerta de "desligar telas" no dia de maior falha.
  Future<Result<void>> _scheduleSmartReminder() async {
    final v = _report?.vulnerability;
    if (v == null) {
      return const Result.error(AppException('Nenhum padrão detectado ainda.'));
    }
    final s = await _reminders.getSettings();
    if (s is Error<ReminderSettings>) return Result.error(s.error);
    final updated = (s as Ok<ReminderSettings>).value.copyWith(
      screensOffEnabled: true,
      vulnerableWeekday: v.weekday,
    );
    final saved = await _reminders.saveSettings(updated);
    if (saved is Error<ReminderSettings>) return Result.error(saved.error);
    _settings = updated;
    await _reminders.requestPermission();
    final planned = await _planReminders.execute(now: _clock());
    notifyListeners();
    return planned is Error<List<ScheduledReminder>>
        ? Result.error(planned.error)
        : const Result.ok(null);
  }

  Future<Result<void>> _markSeen() async {
    final r = await _achievements.markAllSeen();
    _medals = [
      for (final a in _medals)
        Achievement(
          definition: a.definition,
          progress: a.progress,
          unlockedAt: a.unlockedAt,
        ),
    ];
    notifyListeners();
    return r;
  }

  /// Resumo em texto para compartilhar no grupo.
  String shareText() {
    final r = _report;
    if (r == null) return '';
    final medals = _medals.where((a) => a.unlocked).map((a) => a.definition.title);
    return [
      '🌿 Meu ritmo da semana (${Dates.weekRange(r.weekStart)})',
      '• Consistência geral: ${(r.consistency * 100).round()}%',
      '• Hidratação média: ${r.averageWaterMl} ml/dia',
      '• Sono médio: ${Dates.hoursMinutes(r.averageSleepMinutes)}',
      '• Rituais guiados: ${r.guidedMinutes} min',
      '• Sequência: ${r.streakDays} dias',
      if (medals.isNotEmpty) '🏅 ${medals.join(', ')}',
      '— via Serene',
    ].join('\n');
  }

  @override
  void dispose() {
    for (final r in _watched) {
      r.removeListener(_onChanged);
    }
    super.dispose();
  }
}
