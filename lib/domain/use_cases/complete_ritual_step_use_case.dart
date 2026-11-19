import 'dart:math';

import '../../data/repositories/challenge/challenge_repository.dart';
import '../../data/repositories/health/health_repository.dart';
import '../../data/repositories/ritual/ritual_repository.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../models/challenge.dart';
import '../models/ritual.dart';
import '../models/user_profile.dart';

/// Resultado de concluir/pular um passo.
class StepOutcome {
  const StepOutcome({
    required this.log,
    required this.ritualCompleted,
    this.sharedWithTribe = false,
  });

  final RitualLog log;
  final bool ritualCompleted;
  final bool sharedWithTribe;
}

/// Conclui (ou pula) um passo do ritual e propaga os efeitos:
///
/// * atualiza o registro do dia do ritual;
/// * alimenta os rastreadores (água, atividade, leitura) conforme o tipo;
/// * ao concluir o ritual inteiro, faz check-in automático no desafio
///   vinculado, se o usuário optou por compartilhar com a tribo.
class CompleteRitualStepUseCase {
  CompleteRitualStepUseCase({
    required RitualRepository ritualRepository,
    required HealthRepository healthRepository,
    required ChallengeRepository challengeRepository,
  }) : _rituals = ritualRepository,
       _health = healthRepository,
       _challenges = challengeRepository;

  final RitualRepository _rituals;
  final HealthRepository _health;
  final ChallengeRepository _challenges;

  Future<Result<StepOutcome>> execute({
    required Ritual ritual,
    required RitualStep step,
    required DateTime now,
    required UserProfile author,
    required int elapsedSeconds,
    bool skipped = false,
  }) async {
    final date = Dates.dateOnly(now);
    final existingR = await _rituals.getLog(ritual.id, date);
    if (existingR is Error<RitualLog?>) return Result.error(existingR.error);
    final existing =
        (existingR as Ok<RitualLog?>).value ??
        RitualLog(
          ritualId: ritual.id,
          date: date,
          completedStepIds: const {},
          skippedStepIds: const {},
          totalSteps: ritual.steps.length,
        );

    final wasComplete = existing.isComplete;
    final alreadyDone = existing.completedStepIds.contains(step.id);

    final completed = {...existing.completedStepIds};
    final skippedIds = {...existing.skippedStepIds};
    if (skipped) {
      skippedIds.add(step.id);
    } else {
      completed.add(step.id);
      skippedIds.remove(step.id);
    }

    var log = existing.copyWith(
      completedStepIds: completed,
      skippedStepIds: skippedIds,
      totalSteps: ritual.steps.length,
      guidedSeconds: existing.guidedSeconds + elapsedSeconds,
    );
    final nowComplete = log.isComplete;
    if (nowComplete && !wasComplete) log = log.copyWith(completedAt: now);

    final saved = await _rituals.saveLog(log);
    if (saved is Error<RitualLog>) return Result.error(saved.error);

    // Rastreadores de saúde (não contabiliza duas vezes o mesmo passo).
    if (!skipped && !alreadyDone) {
      final minutes = (elapsedSeconds / 60).round().clamp(
        1,
        max(1, step.durationMinutes * 3),
      ).toInt();
      switch (step.type.metric) {
        case HealthMetric.water:
          await _health.addWater(date, step.waterMl ?? 250);
        case HealthMetric.activity:
          await _health.addActivity(date, minutes);
        case HealthMetric.reading:
          await _health.addReading(date, minutes);
        case HealthMetric.sleep:
        case null:
          break;
      }
    }

    // Check-in automático no desafio vinculado.
    var shared = false;
    if (nowComplete &&
        !wasComplete &&
        ritual.shareWithTribe &&
        ritual.linkedChallengeId != null) {
      final r = await _challenges.addCheckIn(
        CheckIn(
          id: Ids.generate('ci'),
          challengeId: ritual.linkedChallengeId!,
          author: author,
          createdAt: now,
          caption:
              'Concluí o ${ritual.name} ✨ ${ritual.steps.length} passos, '
              '${ritual.totalMinutes} min de presença.',
          context: ritual.name,
          tag: 'Ritual concluído',
        ),
      );
      shared = r is Ok<CheckIn>;
    }

    return Result.ok(
      StepOutcome(
        log: log,
        ritualCompleted: nowComplete && !wasComplete,
        sharedWithTribe: shared,
      ),
    );
  }
}
