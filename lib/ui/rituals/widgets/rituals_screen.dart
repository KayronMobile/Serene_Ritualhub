import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/rituals_viewmodel.dart';

/// Aba "Rituais": lista dos rituais com acesso ao construtor e ao player.
class RitualsScreen extends StatelessWidget {
  const RitualsScreen({super.key, required this.viewModel});

  final RitualsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => context.push(Routes.newRitual),
        icon: const Icon(Icons.add),
        label: const Text('Novo ritual'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.load]),
          builder: (context, _) {
            if (viewModel.load.running && viewModel.items.isEmpty) {
              return const LoadingView();
            }
            if (viewModel.load.error && viewModel.items.isEmpty) {
              return ErrorIndicator(
                title: 'Não foi possível carregar seus rituais.',
                onRetry: viewModel.load.execute,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Dimens.margin,
                Dimens.spaceMd,
                Dimens.margin,
                120,
              ),
              children: [
                Text(
                  'CONSTRUÇÃO DE HÁBITOS',
                  style: t.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text('Seus Rituais', style: t.displaySmall),
                const SizedBox(height: 4),
                Text(
                  'Sequências encadeadas executadas com um player guiado por '
                  'temporizador.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Dimens.spaceLg),
                if (viewModel.items.isEmpty)
                  SereneCard(
                    child: Text(
                      'Você ainda não tem rituais. Toque em “Novo ritual” para '
                      'montar o primeiro.',
                      style: t.bodyMedium,
                    ),
                  ),
                for (final item in viewModel.items) ...[
                  _RitualCard(
                    item: item,
                    onPlay: () => context.push(Routes.player(item.ritual.id)),
                    onEdit: () => context.push(Routes.editRitual(item.ritual.id)),
                    onDelete: () => _confirmDelete(context, item),
                  ),
                  const SizedBox(height: Dimens.spaceMd),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RitualListItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ritual?'),
        content: Text(
          '“${item.ritual.name}” e seu histórico serão removidos deste '
          'aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok ?? false) await viewModel.delete.execute(item.ritual.id);
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.item,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  final RitualListItem item;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = item.ritual;
    return SereneCard(
      radius: Dimens.radiusLg,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Visuals.periodIcon(r.period),
                background: AppColors.surfaceContainer,
                size: 48,
              ),
              const SizedBox(width: Dimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.period.label.toUpperCase()} · ${Dates.hhmm(r.startMinutes)}',
                      style: t.labelSmall?.copyWith(color: AppColors.secondary),
                    ),
                    Text(r.name, style: t.headlineSmall),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in r.steps)
                PillBadge(
                  label: s.title,
                  icon: Visuals.stepIcon(s.type),
                  dense: true,
                  background: Visuals.stepTint(s.type).background,
                  foreground: Visuals.stepTint(s.type).foreground,
                ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: r.activeWeekdays.contains(d)
                          ? AppColors.primaryContainer
                          : AppColors.surfaceHigh,
                    ),
                    child: Text(
                      Dates.weekdayLetter[d - 1],
                      style: t.labelSmall?.copyWith(
                        color: r.activeWeekdays.contains(d)
                            ? AppColors.onPrimary
                            : AppColors.outline,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '${r.steps.length} passos · ${r.totalMinutes} min',
                style: t.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.scheduledToday
                      ? (item.completedToday
                            ? 'Concluído hoje ✓'
                            : '${item.stepsDoneToday}/${r.steps.length} passos hoje')
                      : 'Descanso hoje',
                  style: t.bodySmall,
                ),
              ),
              Text(
                '${item.weekCompleted}/${item.weekScheduled} na semana',
                style: t.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow),
            label: Text(item.completedToday ? 'Repetir no player' : 'Iniciar no player'),
          ),
        ],
      ),
    );
  }
}
