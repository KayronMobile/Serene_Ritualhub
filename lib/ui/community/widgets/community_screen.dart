import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/challenge.dart';
import '../../../routing/routes.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/community_viewmodel.dart';
import 'check_in_card.dart';
import 'check_in_sheet.dart';
import 'create_challenge_sheet.dart';
import 'leaderboard_section.dart';

/// Aba "Comunidade": desafios coletivos, placar, mural e feed.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, required this.viewModel});

  final CommunityViewModel viewModel;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  CommunityViewModel get vm => widget.viewModel;

  late final List<Command<Object?>> _watched = [
    vm.addComment,
    vm.sendEncouragement,
    vm.toggleReaction,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _watched) {
      c.addListener(_onCommand);
    }
    vm.sendEncouragement.addListener(_onEncouragement);
  }

  @override
  void dispose() {
    for (final c in _watched) {
      c.removeListener(_onCommand);
    }
    vm.sendEncouragement.removeListener(_onEncouragement);
    super.dispose();
  }

  void _onCommand() {
    for (final c in _watched) {
      final r = c.result;
      if (r is Error<Object?> && mounted) {
        showSnack(context, errorMessage(r.error));
        c.clearResult();
      }
    }
  }

  void _onEncouragement() {
    if (vm.sendEncouragement.completed && mounted) {
      showSnack(context, 'Lembrança afetuosa enviada 💛');
      vm.sendEncouragement.clearResult();
    }
  }

  Future<void> _openCheckIn() async {
    final ok = await showCheckInSheet(context, vm);
    if ((ok ?? false) && mounted) {
      showSnack(context, 'Check-in publicado! Sua tribo vai adorar ✨');
    }
  }

  Future<void> _openCreate({ChallengeTemplate? template}) async {
    final ok = await showCreateChallengeSheet(context, vm, template: template);
    if ((ok ?? false) && mounted) {
      showSnack(context, 'Desafio criado! Convites enviados para a tribo 🌿');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ListenableBuilder(
        listenable: vm,
        builder: (context, _) =>
            vm.tab == CommunityTab.active &&
                vm.selected != null &&
                vm.selected!.isActive(vm.now)
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                onPressed: vm.checkedInToday ? null : _openCheckIn,
                icon: Icon(
                  vm.checkedInToday ? Icons.check : Icons.photo_camera_outlined,
                ),
                label: Text(
                  vm.checkedInToday ? 'Check-in feito hoje' : 'Fazer Check-in',
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([vm, vm.load]),
          builder: (context, _) {
            if (vm.load.running && vm.challenges.isEmpty) {
              return const LoadingView();
            }
            if (vm.load.error && vm.challenges.isEmpty) {
              return ErrorIndicator(
                title: 'Não foi possível carregar sua tribo.',
                onRetry: vm.load.execute,
              );
            }
            final me = vm.leaderboard
                .where((e) => e.member.id == vm.user?.id)
                .firstOrNull;
            return RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: vm.load.execute,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  SereneTopBar(
                    user: vm.user,
                    streak: me?.currentStreak,
                    onAvatarTap: () => context.push(Routes.profile),
                  ),
                  Padding(
                    padding: Dimens.screenPadding,
                    child: _Tabs(selected: vm.tab, onSelect: vm.setTab),
                  ),
                  const SizedBox(height: Dimens.spaceLg),
                  ...switch (vm.tab) {
                    CommunityTab.active => _active(context),
                    CommunityTab.groups => _groups(context),
                    CommunityTab.discover => _discover(context),
                  },
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _active(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = vm.selected;
    if (c == null) {
      return [
        Padding(
          padding: Dimens.screenPadding,
          child: SereneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nenhum desafio ativo', style: t.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Convide amigos para um desafio temporário e construam '
                  'consistência juntos.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Dimens.spaceMd),
                FilledButton(
                  onPressed: () => vm.setTab(CommunityTab.discover),
                  child: const Text('Descobrir desafios'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    final active = vm.activeChallenges;
    final care = vm.careTarget;
    return [
      if (active.length > 1)
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: Dimens.screenPadding,
            children: [
              for (final a in active)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: a.id == c.id,
                    showCheckmark: false,
                    label: Text(a.title, overflow: TextOverflow.ellipsis),
                    onSelected: (_) => vm.select(a.id),
                  ),
                ),
            ],
          ),
        ),
      if (active.length > 1) const SizedBox(height: Dimens.spaceMd),
      Padding(
        padding: Dimens.screenPadding,
        child: _ChallengeHero(challenge: c, now: vm.now),
      ),
      const SizedBox(height: Dimens.spaceXl),
      Padding(
        padding: Dimens.screenPadding,
        child: LeaderboardSection(
          entries: vm.leaderboard,
          groupRate: vm.groupRate,
          myId: vm.user?.id,
          isFinished: c.isFinished(vm.now),
        ),
      ),
      if (care != null && c.isActive(vm.now)) ...[
        const SizedBox(height: Dimens.spaceLg),
        Padding(
          padding: Dimens.screenPadding,
          child: _CareCard(
            name: care.member.firstName,
            busy: vm.sendEncouragement.running,
            onSend: () => vm.sendEncouragement.execute(care.member),
          ),
        ),
      ],
      if (vm.wall.isNotEmpty) ...[
        const SizedBox(height: Dimens.spaceLg),
        Padding(
          padding: Dimens.screenPadding,
          child: _Wall(vm: vm),
        ),
      ],
      const SizedBox(height: Dimens.spaceXl),
      Padding(
        padding: Dimens.screenPadding,
        child: SectionHeader(
          eyebrow: 'Comunidade ativa',
          title: 'Check-ins em Tempo Real',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('Ao vivo', style: t.labelMedium),
            ],
          ),
        ),
      ),
      const SizedBox(height: Dimens.spaceMd),
      if (vm.feed.isEmpty)
        Padding(
          padding: Dimens.screenPadding,
          child: Text(
            'Ninguém registrou ainda. Que tal ser o primeiro? 🌱',
            style: t.bodyMedium,
          ),
        ),
      for (final ci in vm.feed)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.margin,
            0,
            Dimens.margin,
            Dimens.spaceMd,
          ),
          child: CheckInCard(
            key: ValueKey(ci.id),
            checkIn: ci,
            challenge: c,
            now: vm.now,
            onReact: (r) =>
                vm.toggleReaction.execute((checkInId: ci.id, reaction: r)),
            onComment: (text) =>
                vm.addComment.execute((checkInId: ci.id, text: text)),
          ),
        ),
    ];
  }

  List<Widget> _groups(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return [
      for (final c in vm.challenges)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.margin,
            0,
            Dimens.margin,
            Dimens.spaceMd,
          ),
          child: SereneCard(
            onTap: () => vm.select(c.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge.tint(
                      Visuals.categoryIcon(c.category),
                      Visuals.categoryTint(c.category),
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: t.titleMedium),
                          Text(
                            c.isFinished(vm.now)
                                ? 'Encerrado em ${Dates.dayMonth(c.endDate)}'
                                : c.isActive(vm.now)
                                ? 'Dia ${c.currentDay(vm.now)} de ${c.durationDays}'
                                : 'Começa em ${Dates.dayMonth(c.startDate)}',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    PillBadge(
                      label: '${(vm.myConsistencyIn(c.id) * 100).round()}%',
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spaceMd),
                Row(
                  children: [
                    AvatarStack(users: c.members, size: 28, max: 4),
                    const Spacer(),
                    Text(
                      '${c.members.length} participantes',
                      style: t.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _discover(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return [
      Padding(
        padding: Dimens.screenPadding,
        child: SereneCard(
          color: AppColors.primaryContainer,
          onTap: _openCreate,
          child: Row(
            children: [
              const IconBadge(
                icon: Icons.add,
                background: AppColors.primaryFixed,
                foreground: AppColors.primary,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Criar desafio personalizado com amigos',
                  style: t.titleMedium?.copyWith(color: AppColors.onPrimary),
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.onPrimary),
            ],
          ),
        ),
      ),
      const SizedBox(height: Dimens.spaceLg),
      Padding(
        padding: Dimens.screenPadding,
        child: const SectionHeader(eyebrow: 'Inspirações', title: 'Modelos de desafio'),
      ),
      const SizedBox(height: Dimens.spaceMd),
      for (final tpl in vm.templates)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.margin,
            0,
            Dimens.margin,
            Dimens.spaceMd,
          ),
          child: SereneCard(
            onTap: () => _openCreate(template: tpl),
            child: Row(
              children: [
                IconBadge.tint(
                  Visuals.categoryIcon(tpl.category),
                  Visuals.categoryTint(tpl.category),
                  size: 48,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tpl.title, style: t.titleMedium),
                      Text(tpl.description, style: t.bodySmall),
                      const SizedBox(height: 6),
                      PillBadge(
                        label: '${tpl.durationDays} dias · ${tpl.category.label}',
                        dense: true,
                        background: AppColors.surfaceContainer,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
    ];
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelect});

  final CommunityTab selected;
  final void Function(CommunityTab) onSelect;

  static const _labels = {
    CommunityTab.active: 'Desafios Ativos',
    CommunityTab.groups: 'Meus Grupos',
    CommunityTab.discover: 'Descobrir',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        for (final tab in CommunityTab.values)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: tab == selected
                      ? AppColors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[tab]!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tab == selected
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({required this.challenge, required this.now});

  final Challenge challenge;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = challenge;
    final finished = c.isFinished(now);
    final progress = finished ? 1.0 : c.timeProgress(now);
    const light = AppColors.onPrimary;
    return Container(
      padding: const EdgeInsets.all(Dimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(Dimens.radiusLg),
        boxShadow: Dimens.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillBadge(
                label: finished
                    ? 'ENCERRADO'
                    : 'RESTAM ${c.daysLeft(now)} DIAS',
                icon: Icons.timer_outlined,
                background: Colors.white.withValues(alpha: 0.15),
                foreground: light,
              ),
              const Spacer(),
              AvatarStack(users: c.members, size: 30, dark: true),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Text(c.title, style: t.headlineMedium?.copyWith(color: light)),
          const SizedBox(height: 4),
          Text(
            c.description,
            style: t.bodyMedium?.copyWith(color: AppColors.onPrimaryContainer),
          ),
          if (c.dailyGoal.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Meta diária: ${c.dailyGoal}',
              style: t.bodySmall?.copyWith(color: AppColors.primaryFixed),
            ),
          ],
          const SizedBox(height: Dimens.spaceMd),
          Row(
            children: [
              Text(
                'Progresso do Grupo (Dia ${c.currentDay(now)}/${c.durationDays})',
                style: t.labelMedium?.copyWith(color: light),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}% concluído',
                style: t.labelMedium?.copyWith(
                  color: light,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressTrack(
            value: progress,
            color: AppColors.surfaceLowest,
            background: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  const _CareCard({
    required this.name,
    required this.onSend,
    required this.busy,
  });

  final String name;
  final VoidCallback onSend;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Dimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(
                icon: Icons.favorite_border,
                background: AppColors.secondaryFixed,
                foreground: AppColors.secondary,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUIDADO COMPARTILHADO',
                      style: t.labelSmall?.copyWith(color: AppColors.secondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$name ainda não registrou hoje',
                      style: t.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uma palavra gentil pode transformar o dia de alguém. '
                      'Envie um lembrete caloroso sem pressão.',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: busy ? null : onSend,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Enviar Lembrança Afetuosa 💌'),
          ),
        ],
      ),
    );
  }
}

class _Wall extends StatelessWidget {
  const _Wall({required this.vm});

  final CommunityViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_outlined, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Mural de Incentivo', style: t.titleMedium),
            ],
          ),
          const SizedBox(height: Dimens.spaceSm),
          for (final e in vm.wall.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(user: e.from, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.message, style: t.bodySmall),
                        Text(
                          '${Dates.relative(e.createdAt, vm.now)} · para ${e.to.firstName}',
                          style: t.labelSmall?.copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
