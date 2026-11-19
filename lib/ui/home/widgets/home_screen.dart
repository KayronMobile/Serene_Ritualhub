import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/home_viewmodel.dart';
import 'breathing_dialog.dart';
import 'challenge_carousel.dart';
import 'metric_cards.dart';
import 'ritual_hero_card.dart';

/// Tela "Hoje": dashboard de rituais, rastreadores e desafios.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.refreshReminders();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: vm.load,
          builder: (context, child) {
            if (vm.load.running && vm.healthLog == null) {
              return const LoadingView();
            }
            if (vm.load.error && vm.healthLog == null) {
              return ErrorIndicator(
                title: 'Não foi possível carregar seu dia.',
                onRetry: vm.load.execute,
              );
            }
            return child!;
          },
          child: ListenableBuilder(
            listenable: vm,
            builder: (context, _) => RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: vm.load.execute,
              child: _HomeContent(vm: vm),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final featured = vm.featured;
    return ListView(
      padding: const EdgeInsets.only(bottom: Dimens.spaceXl),
      children: [
        SereneTopBar(
          user: vm.user,
          streak: vm.streak,
          onAvatarTap: () => context.push(Routes.profile),
        ),
        Padding(
          padding: Dimens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Dimens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vm.dateLabel.toUpperCase(),
                      style: t.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (vm.streak > 0)
                    PillBadge(
                      label: 'Dia ${vm.streak} de consistência',
                      icon: Icons.eco_outlined,
                    ),
                ],
              ),
              const SizedBox(height: Dimens.spaceSm),
              Text(
                '${vm.greeting}, ${vm.user?.firstName ?? ''} 🌿',
                style: t.displayMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: Dimens.spaceMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '“${vm.quote}”',
                        style: t.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimens.spaceLg),
              if (featured != null)
                RitualHeroCard(
                  today: featured,
                  onStart: () =>
                      context.push(Routes.player(featured.ritual.id)),
                )
              else
                _EmptyRituals(onCreate: () => context.push(Routes.newRitual)),
              const SizedBox(height: Dimens.spaceXl),
              SectionHeader(
                title: 'Métricas do Dia',
                trailing: Text(
                  vm.updatedLabel,
                  style: t.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: Dimens.spaceMd),
              if (vm.healthLog != null)
                MetricGrid(
                  log: vm.healthLog!,
                  goals: vm.goals,
                  onAddWater: vm.addWater.execute,
                  onLogSleep: (minutes, quality) =>
                      vm.logSleep.execute((minutes: minutes, quality: quality)),
                  onAddReading: vm.addReading.execute,
                  onAddActivity: vm.addActivity.execute,
                ),
              const SizedBox(height: Dimens.spaceXl),
              SectionHeader(
                title: 'Desafios em Tribo',
                icon: Icons.groups_outlined,
                trailing: TextButton(
                  onPressed: () => context.go(Routes.community),
                  child: const Text('Ver todos'),
                ),
              ),
              const SizedBox(height: Dimens.spaceMd),
            ],
          ),
        ),
        ChallengeCarousel(
          challenges: vm.activeChallenges,
          onTap: (_) => context.go(Routes.community),
          onCreate: () => context.go(Routes.community),
        ),
        Padding(
          padding: Dimens.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: Dimens.spaceLg),
              SereneCard(
                color: AppColors.surfaceContainer,
                shadow: false,
                radius: Dimens.radiusLg,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const BreathingDialog(),
                ),
                child: Row(
                  children: [
                    const IconBadge(
                      icon: Icons.air,
                      background: AppColors.surfaceHighest,
                      size: 48,
                    ),
                    const SizedBox(width: Dimens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Micro-pausa de 1 Minuto', style: t.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            'Inspire 4s, retenha 4s e expire em 6s para '
                            'regular seu ritmo cardíaco.',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (final other in vm.otherRituals) ...[
                const SizedBox(height: Dimens.spaceMd),
                SereneCard(
                  radius: Dimens.radiusLg,
                  onTap: () => context.push(Routes.player(other.ritual.id)),
                  child: Row(
                    children: [
                      IconBadge(
                        icon: Visuals.periodIcon(other.ritual.period),
                        background: AppColors.surfaceContainer,
                        size: 48,
                      ),
                      const SizedBox(width: Dimens.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(other.ritual.name, style: t.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              other.ritual.steps
                                  .map((s) => s.title)
                                  .join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      other.isDone
                          ? const PillBadge(label: 'Feito', icon: Icons.check)
                          : PillBadge(
                              label: Dates.hhmm(other.ritual.startMinutes),
                              icon: Icons.alarm_on_outlined,
                              background: AppColors.surfaceContainer,
                            ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyRituals extends StatelessWidget {
  const _EmptyRituals({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => SereneCard(
    radius: Dimens.radiusLg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconBadge(icon: Icons.self_improvement, size: 48),
        const SizedBox(height: Dimens.spaceMd),
        Text(
          'Nenhum ritual para hoje',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Monte uma sequência de pequenos passos e deixe o player guiar você.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Dimens.spaceMd),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Criar ritual'),
        ),
      ],
    ),
  );
}
