import 'package:flutter/material.dart';

import '../../../domain/models/ritual.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';

/// Card de um passo no construtor (arrastável).
class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.index,
    required this.step,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final int index;
  final RitualStep step;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tint = Visuals.stepTint(step.type);
    return SereneCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge.tint(Visuals.stepIcon(step.type), tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                'PASSO ${(index + 1).toString().padLeft(2, '0')}',
                            style: t.labelSmall?.copyWith(
                              color: tint.foreground,
                            ),
                          ),
                          TextSpan(
                            text: '  •  ${step.type.label}',
                            style: t.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      step.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.headlineSmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  switch (v) {
                    case 0:
                      onEdit();
                    case 1:
                      onDuplicate();
                    default:
                      onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 0, child: Text('Editar')),
                  PopupMenuItem(value: 1, child: Text('Duplicar')),
                  PopupMenuItem(value: 2, child: Text('Remover')),
                ],
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_indicator, color: AppColors.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  if (step.type == StepType.hydration) ...[
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      step.description.isEmpty
                          ? step.instruction
                          : step.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(Dates.mmss(step.durationSeconds), style: t.labelMedium),
                ],
              ),
            ),
          ),
          if (step.ambientSound != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Som Ambiente: ',
                          style: t.bodySmall,
                          children: [
                            TextSpan(
                              text: step.ambientSound,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.volume_up_outlined, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Conector tracejado entre passos consecutivos.
class StepConnector extends StatelessWidget {
  const StepConnector({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < 3; i++)
          Container(width: 2, height: 4, color: AppColors.outlineVariant),
        const Icon(
          Icons.keyboard_arrow_down,
          size: 14,
          color: AppColors.outline,
        ),
      ],
    ),
  );
}
