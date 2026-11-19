import '../../utils/dates.dart';
import '../models/challenge.dart';
import '../models/ritual.dart';

/// Regras puras de consistência (sem I/O) compartilhadas entre use cases.
abstract final class ConsistencyCalculator {
  /// Dias seguidos com ao menos um ritual concluído.
  ///
  /// Dias sem ritual agendado não quebram nem contam a sequência. Se hoje
  /// ainda não houve conclusão, a contagem começa por ontem.
  static int ritualStreak({
    required List<Ritual> rituals,
    required List<RitualLog> logs,
    required DateTime now,
    int maxDays = 365,
  }) {
    final completeDays = <String>{
      for (final l in logs)
        if (l.isComplete) Dates.key(l.date),
    };
    final today = Dates.dateOnly(now);
    var streak = 0;
    for (var back = 0; back < maxDays; back++) {
      final day = Dates.addDays(today, -back);
      final done = completeDays.contains(Dates.key(day));
      if (done) {
        streak++;
        continue;
      }
      if (back == 0) continue; // hoje ainda pode acontecer
      final scheduled = rituals.any((r) => r.isScheduledOn(day));
      if (!scheduled) continue;
      break;
    }
    return streak;
  }

  /// Placar de consistência de um desafio a partir dos check-ins.
  static List<LeaderboardEntry> leaderboard({
    required Challenge challenge,
    required List<CheckIn> checkIns,
    required DateTime now,
  }) {
    final today = Dates.dateOnly(now);
    final lastDay = challenge.isFinished(now) ? challenge.endDate : today;
    final entries = <LeaderboardEntry>[];

    for (final member in challenge.members) {
      final days = <String>{
        for (final c in checkIns)
          if (c.author.id == member.id &&
              !Dates.dateOnly(c.createdAt).isBefore(challenge.startDate) &&
              !Dates.dateOnly(c.createdAt).isAfter(lastDay))
            Dates.key(c.createdAt),
      };
      final checkedToday = days.contains(Dates.key(today));
      final current = challenge.currentDay(now);
      final elapsed = challenge.isFinished(now)
          ? challenge.durationDays
          : (checkedToday ? current : current - 1);

      var streak = 0;
      var cursor = checkedToday || challenge.isFinished(now)
          ? lastDay
          : Dates.addDays(today, -1);
      while (!cursor.isBefore(challenge.startDate) &&
          days.contains(Dates.key(cursor))) {
        streak++;
        cursor = Dates.addDays(cursor, -1);
      }

      entries.add(
        LeaderboardEntry(
          member: member,
          checkInDays: days.length,
          elapsedDays: elapsed < 0 ? 0 : elapsed,
          currentStreak: streak,
          checkedInToday: checkedToday,
        ),
      );
    }

    entries.sort((a, b) {
      final byConsistency = b.consistency.compareTo(a.consistency);
      if (byConsistency != 0) return byConsistency;
      final byStreak = b.currentStreak.compareTo(a.currentStreak);
      if (byStreak != 0) return byStreak;
      return a.member.name.compareTo(b.member.name);
    });
    return entries;
  }

  /// Taxa média de sucesso do grupo (0..1).
  static double groupRate(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) return 0;
    final sum = entries.fold<double>(0, (s, e) => s + e.consistency);
    return sum / entries.length;
  }
}
