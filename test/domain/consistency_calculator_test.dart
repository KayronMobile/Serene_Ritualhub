import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/domain/models/challenge.dart';
import 'package:ritualhub/domain/models/ritual.dart';
import 'package:ritualhub/domain/models/user_profile.dart';
import 'package:ritualhub/domain/use_cases/consistency_calculator.dart';
import 'package:ritualhub/utils/dates.dart';

void main() {
  final now = DateTime(2026, 11, 18, 10);
  final today = Dates.dateOnly(now);

  const step = RitualStep(
    id: 's1',
    title: 'Água',
    type: StepType.hydration,
    durationSeconds: 60,
  );
  const ritual = Ritual(
    id: 'r1',
    name: 'Manhã',
    period: RitualPeriod.morning,
    steps: [step],
    activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
    startMinutes: 420,
  );

  RitualLog completeOn(DateTime day) => RitualLog(
    ritualId: 'r1',
    date: day,
    completedStepIds: const {'s1'},
    skippedStepIds: const {},
    totalSteps: 1,
    completedAt: day.add(const Duration(hours: 7)),
  );

  group('ritualStreak', () {
    test('conta dias seguidos e não penaliza o dia de hoje em aberto', () {
      final logs = [
        completeOn(Dates.addDays(today, -1)),
        completeOn(Dates.addDays(today, -2)),
        completeOn(Dates.addDays(today, -3)),
        // dia -4 sem registro quebra a sequência
        completeOn(Dates.addDays(today, -5)),
      ];
      expect(
        ConsistencyCalculator.ritualStreak(
          rituals: [ritual],
          logs: logs,
          now: now,
        ),
        3,
      );
    });

    test('inclui hoje quando já concluído', () {
      final logs = [completeOn(today), completeOn(Dates.addDays(today, -1))];
      expect(
        ConsistencyCalculator.ritualStreak(
          rituals: [ritual],
          logs: logs,
          now: now,
        ),
        2,
      );
    });
  });

  group('leaderboard', () {
    const me = UserProfile(id: 'me', name: 'Lucas M', email: '');
    const ana = UserProfile(id: 'ana', name: 'Ana Souza', email: '');
    final challenge = Challenge(
      id: 'c1',
      title: '21 Dias',
      description: '',
      category: ChallengeCategory.nutrition,
      startDate: Dates.addDays(today, -4), // hoje é o dia 5
      durationDays: 21,
      members: const [ana, me],
      createdBy: 'me',
    );

    CheckIn ci(UserProfile who, int daysAgo) => CheckIn(
      id: '${who.id}$daysAgo',
      challengeId: 'c1',
      author: who,
      createdAt: Dates.addDays(today, -daysAgo).add(const Duration(hours: 8)),
      caption: 'ok',
    );

    test('ordena por consistência e calcula sequência', () {
      final checkIns = [
        for (var d = 0; d <= 4; d++) ci(me, d), // 5/5 incluindo hoje
        ci(ana, 4),
        ci(ana, 1), // 2 de 4 dias encerrados
      ];
      final board = ConsistencyCalculator.leaderboard(
        challenge: challenge,
        checkIns: checkIns,
        now: now,
      );

      expect(board.first.member.id, 'me');
      expect(board.first.consistency, 1.0);
      expect(board.first.currentStreak, 5);
      expect(board.first.checkedInToday, isTrue);

      final anaEntry = board.last;
      expect(anaEntry.elapsedDays, 4);
      expect(anaEntry.consistency, closeTo(0.5, 0.001));
      expect(anaEntry.currentStreak, 1);
      expect(anaEntry.checkedInToday, isFalse);

      expect(
        ConsistencyCalculator.groupRate(board),
        closeTo(0.75, 0.001),
      );
    });
  });
}
