import 'package:flutter/material.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/ritual.dart';
import '../../../domain/use_cases/complete_ritual_step_use_case.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';

/// Tela de celebração ao terminar a sessão guiada.
class SessionCompleteView extends StatelessWidget {
  const SessionCompleteView({
    super.key,
    required this.ritual,
    required this.outcome,
    required this.sessionSeconds,
    required this.unlocked,
    required this.onDone,
    required this.onSeeProgress,
  });

  final Ritual ritual;
  final StepOutcome? outcome;
  final int sessionSeconds;
  final List<Achievement> unlocked;
  final VoidCallback onDone;
  final VoidCallback onSeeProgress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final log = outcome?.log;
    final done = log?.completedStepIds.length ?? 0;
    final complete = log?.isComplete ?? false;
    return ListView(
      padding: const EdgeInsets.all(Dimens.margin),
      children: [
        const SizedBox(height: Dimens.spaceXl),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed,
              ),
              child: Icon(
                complete ? Icons.check_rounded : Icons.spa_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimens.spaceLg),
        Text(
          complete ? 'Ritual concluído' : 'Sessão encerrada',
          textAlign: TextAlign.center,
          style: t.displayMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: Dimens.spaceSm),
        Text(
          complete
              ? 'Você honrou o “${ritual.name}”. Pequenos gestos repetidos '
                    'transformam destinos.'
              : 'Algumas etapas ficaram para depois — e tudo bem. O ritmo '
                    'certo é o que você consegue sustentar.',
          textAlign: TextAlign.center,
          style: t.bodyLarge,
        ),
        const SizedBox(height: Dimens.spaceLg),
        Row(
          children: [
            Expanded(
              child: _Stat(label: 'Passos', value: '$done/${ritual.steps.length}'),
            ),
            const SizedBox(width: Dimens.gutter),
            Expanded(
              child: _Stat(
                label: 'Presença',
                value: Dates.mmss(sessionSeconds),
              ),
            ),
          ],
        ),
        if (outcome?.sharedWithTribe ?? false) ...[
          const SizedBox(height: Dimens.spaceMd),
          const SereneCard(
            color: AppColors.secondaryFixed,
            shadow: false,
            padding: EdgeInsets.all(Dimens.spaceMd),
            child: Row(
              children: [
                Icon(Icons.groups_outlined, color: AppColors.secondary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Check-in automático enviado para sua tribo! 🔥',
                  ),
                ),
              ],
            ),
          ),
        ],
        if (unlocked.isNotEmpty) ...[
          const SizedBox(height: Dimens.spaceLg),
          Text('Nova medalha desbloqueada', style: t.headlineSmall),
          const SizedBox(height: Dimens.spaceSm),
          for (final a in unlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spaceSm),
              child: SereneCard(
                padding: const EdgeInsets.all(Dimens.spaceMd),
                child: Row(
                  children: [
                    IconBadge.tint(
                      Visuals.achievementIcon(a.definition.icon),
                      Visuals.achievementTint(a.definition.icon),
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.definition.title, style: t.titleMedium),
                          Text(a.definition.description, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: Dimens.spaceXl),
        FilledButton(onPressed: onDone, child: const Text('Voltar para Hoje')),
        const SizedBox(height: Dimens.spaceSm),
        TextButton(
          onPressed: onSeeProgress,
          child: const Text('Ver meu progresso'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      padding: const EdgeInsets.all(Dimens.spaceMd),
      child: Column(
        children: [
          Text(value, style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}
