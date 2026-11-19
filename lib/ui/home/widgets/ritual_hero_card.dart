import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../view_models/home_viewmodel.dart';

/// Card principal do ritual em destaque com a lista de passos encadeados.
class RitualHeroCard extends StatelessWidget {
  const RitualHeroCard({super.key, required this.today, required this.onStart});

  final TodayRitual today;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ritual = today.ritual;
    final next = today.nextStep;
    return SereneCard(
      radius: Dimens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ritual.period.eyebrow.toUpperCase(),
                      style: t.labelSmall?.copyWith(color: AppColors.secondary),
                    ),
                    const SizedBox(height: 4),
                    Text(ritual.name, style: t.headlineLarge),
                  ],
                ),
              ),
              PillBadge(
                label: '${today.completedCount}/${ritual.steps.length} concluído',
                background: AppColors.secondaryFixed,
                foreground: AppColors.onSecondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          ProgressTrack(value: today.progress, height: 8),
          const SizedBox(height: Dimens.spaceMd),
          for (var i = 0; i < ritual.steps.length; i++) ...[
            _StepRow(
              index: i + 1,
              title: ritual.steps[i].title,
              subtitle: ritual.steps[i].description,
              done: today.isStepDone(ritual.steps[i]),
              isNext: next?.id == ritual.steps[i].id,
            ),
            const SizedBox(height: Dimens.spaceSm),
          ],
          const SizedBox(height: Dimens.spaceSm),
          DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              boxShadow: Dimens.floatingShadow,
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: onStart,
              child: Row(
                children: [
                  Icon(
                    today.isDone ? Icons.replay : Icons.play_arrow,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      today.isDone
                          ? 'Ritual concluído · Repetir'
                          : today.completedCount == 0
                          ? 'Iniciar Ritual (${ritual.totalMinutes} min)'
                          : 'Iniciar Próximo Bloco (${next!.title} '
                                '${next.durationMinutes} min)',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.isNext,
  });

  final int index;
  final String title;
  final String subtitle;
  final bool done;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = !done && !isNext;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNext ? AppColors.surfaceHigh : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(Dimens.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.primaryContainer
                  : isNext
                  ? AppColors.secondary
                  : Colors.transparent,
              border: muted
                  ? Border.all(color: AppColors.outlineVariant, width: 2)
                  : null,
            ),
            child: done
                ? const Icon(Icons.check, color: AppColors.onPrimary, size: 18)
                : isNext
                ? const Icon(Icons.schedule, color: AppColors.onPrimary, size: 18)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. $title',
                  style: t.titleSmall?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: muted ? AppColors.onSurfaceVariant : AppColors.onSurface,
                    fontWeight: done ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: t.bodySmall?.copyWith(
                    color: muted ? AppColors.outline : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isNext)
            const PillBadge(
              label: 'Próximo',
              dense: true,
              background: AppColors.secondaryContainer,
              foreground: AppColors.onSecondaryContainer,
            ),
        ],
      ),
    );
  }
}
