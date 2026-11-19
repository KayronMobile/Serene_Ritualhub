import 'dart:math';

import '../../data/repositories/achievement/achievement_repository.dart';
import '../../data/repositories/challenge/challenge_repository.dart';
import '../../data/repositories/health/health_repository.dart';
import '../../data/repositories/ritual/ritual_repository.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/health.dart';
import '../models/ritual.dart';

/// Resultado da avaliação de medalhas.
class AchievementEvaluation {
  const AchievementEvaluation({
    required this.achievements,
    required this.newlyUnlocked,
  });

  final List<Achievement> achievements;
  final List<Achievement> newlyUnlocked;

  int get unseenCount => achievements.where((a) => a.isNew).length;
}

/// Calcula o progresso de todas as medalhas (individuais e de grupo) e
/// persiste novos desbloqueios.
class EvaluateAchievementsUseCase {
  EvaluateAchievementsUseCase({
    required RitualRepository ritualRepository,
    required HealthRepository healthRepository,
    required ChallengeRepository challengeRepository,
    required AchievementRepository achievementRepository,
  }) : _rituals = ritualRepository,
       _health = healthRepository,
       _challenges = challengeRepository,
       _achievements = achievementRepository;

  final RitualRepository _rituals;
  final HealthRepository _health;
  final ChallengeRepository _challenges;
  final AchievementRepository _achievements;

  static const _historyDays = 120;

  Future<Result<AchievementEvaluation>> evaluate({
    required String userId,
    required DateTime now,
  }) async {
    final today = Dates.dateOnly(now);
    final from = Dates.addDays(today, -_historyDays);

    final ritualsR = await _rituals.getRituals();
    final logsR = await _rituals.getLogs(from, today);
    final goalsR = await _health.getGoals();
    final healthR = await _health.getLogs(from, today);
    final challengesR = await _challenges.getChallenges();
    final unlocksR = await _achievements.getUnlocks();

    if (ritualsR is Error<List<Ritual>>) return Result.error(ritualsR.error);
    final rituals = (ritualsR as Ok<List<Ritual>>).value;
    // Fontes secundárias: em caso de falha, avaliamos com dados vazios.
    final logs = logsR is Ok<List<RitualLog>> ? logsR.value : <RitualLog>[];
    final goals = goalsR is Ok<HealthGoals>
        ? goalsR.value
        : const HealthGoals();
    final health = healthR is Ok<List<DailyHealthLog>>
        ? healthR.value
        : <DailyHealthLog>[];
    final challenges = challengesR is Ok<List<Challenge>>
        ? challengesR.value
        : <Challenge>[];
    final unlocks = unlocksR is Ok<List<AchievementUnlock>>
        ? unlocksR.value
        : <AchievementUnlock>[];

    final checkIns = <String, List<CheckIn>>{};
    for (final c in challenges) {
      final r = await _challenges.getCheckIns(c.id);
      checkIns[c.id] = r is Ok<List<CheckIn>> ? r.value : const [];
    }

    final progress = <String, int>{
      AchievementCatalog.earlyRiser.id: _earlyRiser(rituals, logs, today),
      AchievementCatalog.hydrationGuardian.id: _goalStreak(
        health,
        today,
        (l) => l.waterMl >= goals.waterMl,
      ),
      AchievementCatalog.sharedStrength.id: _sharedStrength(
        challenges,
        checkIns,
        userId,
        now,
      ),
      AchievementCatalog.focusMaster.id: logs.where((l) => l.isFocused).length,
      AchievementCatalog.firstRitual.id: logs.where((l) => l.isComplete).length,
      AchievementCatalog.tribeInSync.id: _tribeInSync(challenges, checkIns),
      AchievementCatalog.avidReader.id: health
          .where((l) => !l.date.isBefore(Dates.addDays(today, -13)))
          .fold<int>(0, (s, l) => s + l.readingMinutes),
      AchievementCatalog.deepRest.id: _goalStreak(
        health,
        today,
        (l) => l.sleepMinutes >= goals.sleepMinutes,
      ),
    };

    final byId = {for (final u in unlocks) u.id: u};
    final newly = <Achievement>[];
    final result = <Achievement>[];
    var changed = false;

    for (final def in AchievementCatalog.all) {
      final p = min(progress[def.id] ?? 0, def.target);
      var unlock = byId[def.id];
      if (unlock == null && p >= def.target) {
        unlock = AchievementUnlock(id: def.id, unlockedAt: now);
        byId[def.id] = unlock;
        changed = true;
      }
      final achievement = Achievement(
        definition: def,
        // Medalhas já conquistadas permanecem completas.
        progress: unlock != null ? def.target : p,
        unlockedAt: unlock?.unlockedAt,
        isNew: unlock != null && !unlock.seen,
      );
      if (unlock != null && !unlocks.any((u) => u.id == def.id)) {
        newly.add(achievement);
      }
      result.add(achievement);
    }

    if (changed) {
      await _achievements.saveUnlocks(byId.values.toList());
    }

    // Conquistadas primeiro (mais recentes no topo), depois por progresso.
    result.sort((a, b) {
      if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
      if (a.unlocked && b.unlocked) {
        return b.unlockedAt!.compareTo(a.unlockedAt!);
      }
      return b.ratio.compareTo(a.ratio);
    });

    return Result.ok(
      AchievementEvaluation(achievements: result, newlyUnlocked: newly),
    );
  }

  /// Dias seguidos (agendados) com ritual matinal concluído antes das 07:30.
  int _earlyRiser(List<Ritual> rituals, List<RitualLog> logs, DateTime today) {
    final morningIds = rituals
        .where((r) => r.period == RitualPeriod.morning)
        .map((r) => r.id)
        .toSet();
    if (morningIds.isEmpty) return 0;

    bool okOn(DateTime day) => logs.any(
      (l) =>
          morningIds.contains(l.ritualId) &&
          Dates.isSameDay(l.date, day) &&
          l.isComplete &&
          l.completedAt != null &&
          (l.completedAt!.hour * 60 + l.completedAt!.minute) <= 7 * 60 + 30,
    );
    bool scheduledOn(DateTime day) =>
        rituals.any((r) => morningIds.contains(r.id) && r.isScheduledOn(day));

    var streak = 0;
    for (var back = 0; back < _historyDays; back++) {
      final day = Dates.addDays(today, -back);
      if (okOn(day)) {
        streak++;
      } else if (back == 0 || !scheduledOn(day)) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Dias consecutivos (a partir de ontem/hoje) que satisfazem [hit].
  int _goalStreak(
    List<DailyHealthLog> logs,
    DateTime today,
    bool Function(DailyHealthLog) hit,
  ) {
    final byKey = {for (final l in logs) Dates.key(l.date): l};
    var streak = 0;
    for (var back = 0; back < _historyDays; back++) {
      final log = byKey[Dates.key(Dates.addDays(today, -back))];
      if (log != null && hit(log)) {
        streak++;
      } else if (back == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Maior número de check-ins do usuário em um desafio com 100% de presença.
  int _sharedStrength(
    List<Challenge> challenges,
    Map<String, List<CheckIn>> checkIns,
    String userId,
    DateTime now,
  ) {
    var best = 0;
    for (final c in challenges) {
      final mine = <String>{
        for (final ci in checkIns[c.id] ?? const <CheckIn>[])
          if (ci.author.id == userId) Dates.key(ci.createdAt),
      };
      final today = Dates.dateOnly(now);
      final checkedToday = mine.contains(Dates.key(today));
      final elapsed = c.isFinished(now)
          ? c.durationDays
          : c.currentDay(now) - (checkedToday ? 0 : 1);
      if (elapsed <= 0) continue;
      if (mine.length >= elapsed) best = max(best, mine.length);
    }
    return best;
  }

  /// Dias em que todos os membros de algum desafio fizeram check-in.
  int _tribeInSync(
    List<Challenge> challenges,
    Map<String, List<CheckIn>> checkIns,
  ) {
    var count = 0;
    for (final c in challenges) {
      final byDay = <String, Set<String>>{};
      for (final ci in checkIns[c.id] ?? const <CheckIn>[]) {
        byDay.putIfAbsent(Dates.key(ci.createdAt), () => {}).add(ci.author.id);
      }
      count += byDay.values.where((s) => s.length >= c.members.length).length;
    }
    return count;
  }
}
