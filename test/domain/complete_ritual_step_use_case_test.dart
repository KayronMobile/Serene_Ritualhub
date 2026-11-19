import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/domain/models/challenge.dart';
import 'package:ritualhub/domain/models/health.dart';
import 'package:ritualhub/domain/models/ritual.dart';
import 'package:ritualhub/domain/use_cases/complete_ritual_step_use_case.dart';
import 'package:ritualhub/utils/dates.dart';
import 'package:ritualhub/utils/result.dart';

import '../../testing/fakes/fake_environment.dart';

void main() {
  late FakeEnvironment env;
  late Ritual morning;

  setUp(() async {
    env = await FakeEnvironment.create();
    await env.signIn();
    morning = (await env.rituals.getRitual('ritual_morning') as Ok<Ritual>).value;
  });

  Future<DailyHealthLog> todayLog() async =>
      (await env.health.getLog(env.now) as Ok<DailyHealthLog>).value;

  Future<StepOutcome> complete(RitualStep step, {int seconds = 60}) async =>
      (await env.completeStep.execute(
                ritual: morning,
                step: step,
                now: env.now,
                author: env.auth.currentUser!,
                elapsedSeconds: seconds,
              )
              as Ok<StepOutcome>)
          .value;

  test('passo de movimento alimenta o rastreador de atividade', () async {
    final before = (await todayLog()).activityMinutes;
    await complete(morning.steps[1], seconds: 420);
    expect((await todayLog()).activityMinutes, before + 7);
  });

  test('não contabiliza duas vezes um passo já concluído', () async {
    // O seed já marca o 1º passo (hidratação) como feito hoje.
    final before = (await todayLog()).waterMl;
    await complete(morning.steps[0]);
    expect((await todayLog()).waterMl, before);
  });

  test('concluir o ritual faz check-in automático no desafio vinculado', () async {
    await complete(morning.steps[1], seconds: 420);
    final outcome = await complete(morning.steps[2], seconds: 600);

    expect(outcome.ritualCompleted, isTrue);
    expect(outcome.sharedWithTribe, isTrue);
    expect(outcome.log.completedAt, isNotNull);

    final checkIns =
        (await env.challenges.getCheckIns(morning.linkedChallengeId!)
                as Ok<List<CheckIn>>)
            .value;
    expect(
      checkIns.where(
        (c) => c.author.id == 'me' && Dates.isSameDay(c.createdAt, env.now),
      ),
      hasLength(1),
    );
  });

  test('pular um passo não conta como concluído', () async {
    final r = await env.completeStep.execute(
      ritual: morning,
      step: morning.steps[1],
      now: env.now,
      author: env.auth.currentUser!,
      elapsedSeconds: 0,
      skipped: true,
    );
    final log = (r as Ok<StepOutcome>).value.log;
    expect(log.completedStepIds.contains(morning.steps[1].id), isFalse);
    expect(log.skippedStepIds, contains(morning.steps[1].id));
  });
}
