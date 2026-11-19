import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/weekly_report.dart';
import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/reports_viewmodel.dart';
import 'charts.dart';

/// Aba "Progresso": relatório semanal de consistência e medalhas.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.viewModel});

  final ReportsViewModel viewModel;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportsViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.scheduleSmartReminder.addListener(_onSmartReminder);
  }

  @override
  void dispose() {
    vm.scheduleSmartReminder.removeListener(_onSmartReminder);
    super.dispose();
  }

  void _onSmartReminder() {
    final r = vm.scheduleSmartReminder.result;
    if (r == null || !mounted) return;
    showSnack(
      context,
      r is Error<void>
          ? errorMessage(r.error)
          : 'Lembrete inteligente programado: telas off 30 min mais cedo 🌙',
    );
    vm.scheduleSmartReminder.clearResult();
  }

  Future<void> _share() async {
    await Clipboard.setData(ClipboardData(text: vm.shareText()));
    if (mounted) {
      showSnack(context, 'Resumo copiado! Cole no grupo da sua tribo 💬');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([vm, vm.load]),
          builder: (context, _) {
            final report = vm.report;
            if (report == null && vm.load.error) {
              return ErrorIndicator(
                title: 'Não foi possível montar seu relatório.',
                onRetry: vm.load.execute,
              );
            }
            if (report == null) return const LoadingView();
            return RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: vm.load.execute,
              child: ListView(
                padding: const EdgeInsets.only(bottom: Dimens.spaceXl),
                children: [
                  SereneTopBar(
                    user: vm.user,
                    streak: report.streakDays,
                    onAvatarTap: () => context.push(Routes.profile),
                  ),
                  Padding(
                    padding: Dimens.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RELATÓRIO DE EVOLUÇÃO',
                                    style: t.labelSmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text('Ritmo & Conquistas', style: t.displaySmall),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Lembretes',
                              onPressed: () => context.push(Routes.reminders),
                              icon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimens.spaceMd),
                        _WeekToggle(
                          offset: vm.weekOffset,
                          currentLabel: vm.currentWeekLabel,
                          onSelect: vm.selectWeek,
                        ),
                        const SizedBox(height: Dimens.spaceLg),
                        _ConsistencyCard(report: report),
                        if (report.vulnerability != null) ...[
                          const SizedBox(height: Dimens.spaceLg),
                          _PatternCard(
                            insight: report.vulnerability!,
                            active: vm.smartReminderActive,
                            busy: vm.scheduleSmartReminder.running,
                            onSchedule: vm.scheduleSmartReminder.execute,
                          ),
                        ],
                        const SizedBox(height: Dimens.spaceLg),
                        _HarmonyCard(days: report.streakDays),
                        const SizedBox(height: Dimens.spaceXl),
                        SectionHeader(
                          title: 'Rastreadores Holísticos',
                          trailing: Text('Médias da Semana', style: t.bodySmall),
                        ),
                        const SizedBox(height: Dimens.spaceMd),
                        _HydrationCard(report: report),
                        const SizedBox(height: Dimens.spaceMd),
                        _MiniStat(
                          icon: Icons.bedtime_outlined,
                          tint: (
                            background: AppColors.primaryFixed,
                            foreground: AppColors.primaryContainer,
                          ),
                          title: 'Média de Sono',
                          subtitle: report.sleepRegularityMinutes <= 30
                              ? 'Horário estável (±${report.sleepRegularityMinutes} min)'
                              : 'Variação de ±${report.sleepRegularityMinutes} min',
                          value: Dates.hoursMinutes(report.averageSleepMinutes),
                          unit: '/noite',
                          badge: report.sleepRegularityMinutes <= 30
                              ? 'Ótima regularidade'
                              : 'Busque regularidade',
                        ),
                        const SizedBox(height: Dimens.spaceMd),
                        _MiniStat(
                          icon: Icons.self_improvement,
                          tint: (
                            background: AppColors.secondaryFixed,
                            foreground: AppColors.secondary,
                          ),
                          title: 'Rituais Guiados',
                          subtitle: 'Meditação, respiração & movimento',
                          value: '${report.guidedMinutes}',
                          unit: ' min',
                          badge: _delta(
                            report.guidedMinutes - report.previousGuidedMinutes,
                          ),
                          badgeColor: AppColors.secondary,
                        ),
                        const SizedBox(height: Dimens.spaceXl),
                        SectionHeader(
                          eyebrow: 'Gamificação consciente',
                          title: 'Medalhas & Marcos',
                          trailing: vm.newAchievements > 0
                              ? GestureDetector(
                                  onTap: vm.markAchievementsSeen.execute,
                                  child: PillBadge(
                                    label: '${vm.newAchievements} Novas!',
                                    background: AppColors.secondaryFixed,
                                    foreground: AppColors.secondary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: Dimens.spaceMd),
                        for (final a in vm.achievements) ...[
                          _AchievementCard(achievement: a),
                          const SizedBox(height: Dimens.spaceMd),
                        ],
                        const SizedBox(height: Dimens.spaceMd),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: _share,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Compartilhar Relatório no Grupo'),
                        ),
                        const SizedBox(height: Dimens.spaceMd),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surfaceHigh,
                            foregroundColor: AppColors.onSurface,
                          ),
                          onPressed: () => context.push(Routes.reminders),
                          icon: const Icon(Icons.alarm),
                          label: const Text(
                            'Ajustar Horários dos Lembretes Inteligentes',
                          ),
                        ),
                        const SizedBox(height: Dimens.spaceXl),
                        const Icon(Icons.eco_outlined, color: AppColors.primaryContainer),
                        const SizedBox(height: 6),
                        Text(
                          '“Pequenos gestos repetidos com gentileza '
                          'transformam destinos.”',
                          textAlign: TextAlign.center,
                          style: t.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _delta(int minutes) =>
      minutes >= 0 ? '+$minutes min vs. ant.' : '$minutes min vs. ant.';
}

class _WeekToggle extends StatelessWidget {
  const _WeekToggle({
    required this.offset,
    required this.currentLabel,
    required this.onSelect,
  });

  final int offset;
  final String currentLabel;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    Widget item(int value, String label) => Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: offset == value ? AppColors.surfaceLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: offset == value ? Dimens.cardShadow : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: offset == value
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          item(0, 'Esta Semana ($currentLabel)'),
          item(-1, 'Semana Anterior'),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = (report.consistency * 100).round();
    final delta = ((report.consistencyDelta) * 100).round();
    return SereneCard(
      radius: Dimens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Consistência Geral', style: t.labelMedium),
                    Row(
                      children: [
                        Text(
                          '$pct%',
                          style: t.displayMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PillBadge(
                          label: '${delta >= 0 ? '+' : ''}$delta% vs. ant.',
                          icon: delta >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          dense: true,
                          background: delta >= 0
                              ? AppColors.primaryFixed
                              : AppColors.secondaryFixed,
                          foreground: delta >= 0
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox.square(
                dimension: 48,
                child: CircularProgressIndicator(
                  value: report.consistency,
                  strokeWidth: 5,
                  backgroundColor: AppColors.surfaceHighest,
                  color: AppColors.primaryContainer,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceLg),
          AdherenceBarChart(
            days: report.days,
            highlightWeekday: report.vulnerability?.weekday,
          ),
          const SizedBox(height: Dimens.spaceMd),
          Row(
            children: [
              const _Legend(color: AppColors.primary, label: 'Rituais Concluídos'),
              const SizedBox(width: Dimens.spaceMd),
              if (report.vulnerability != null)
                const _Legend(color: AppColors.terracotta, label: 'Vulnerabilidade'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.insight,
    required this.active,
    required this.busy,
    required this.onSchedule,
  });

  final VulnerabilityInsight insight;
  final bool active;
  final bool busy;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final day = Dates.weekdayLong[insight.weekday - 1];
    return Container(
      padding: const EdgeInsets.all(Dimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.secondaryFixed.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Dimens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.lightbulb_outline,
            background: AppColors.surfaceLowest,
            foreground: AppColors.secondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PADRÃO DETECTADO • $day',
                  style: t.labelSmall?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: '$day é o seu dia de maior vulnerabilidade para o ',
                      ),
                      TextSpan(
                        text: insight.ritualName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: insight.isNight
                            ? ' (aderência de ${(insight.adherence * 100).round()}%). '
                                  'Que tal agendar o alarme de desligar telas 30 '
                                  'minutos mais cedo?'
                            : ' (aderência de ${(insight.adherence * 100).round()}%). '
                                  'Que tal um lembrete extra na noite anterior, '
                                  'desligando as telas 30 minutos mais cedo?',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimens.spaceSm),
                active
                    ? const PillBadge(
                        label: 'Lembrete inteligente ativo',
                        icon: Icons.check,
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.secondary,
                        ),
                        onPressed: busy ? null : onSchedule,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text('Programar lembrete inteligente'),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 18),
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

class _HarmonyCard extends StatelessWidget {
  const _HarmonyCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      height: 130,
      padding: const EdgeInsets.all(Dimens.spaceLg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [AppColors.primary, AppColors.sage, AppColors.primaryFixedDim],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.spa, size: 110, color: Color(0x22FFFFFF)),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HARMONIA DIÁRIA',
                style: t.labelSmall?.copyWith(color: AppColors.primaryFixed),
              ),
              Text(
                days == 0
                    ? 'Hoje é um ótimo dia para recomeçar'
                    : '$days ${days == 1 ? 'dia' : 'dias'} de consistência '
                          'ininterrupta',
                style: t.headlineSmall?.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      child: Column(
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.water_drop_outlined,
                background: AppColors.tertiaryFixed,
                foreground: AppColors.tertiaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Média de Hidratação', style: t.titleSmall),
                    Text(
                      'Meta diária: ${report.waterGoalMl} ml',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${report.averageWaterMl}',
                      style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                      children: [TextSpan(text: ' ml/dia', style: t.bodySmall)],
                    ),
                  ),
                  Text(
                    '${(report.waterGoalRatio * 100).round()}% da meta',
                    style: t.labelMedium?.copyWith(color: AppColors.tertiaryContainer),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          HydrationLineChart(values: report.waterByDay, goal: report.waterGoalMl),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.badge,
    this.badgeColor = AppColors.primaryContainer,
  });

  final IconData icon;
  final Tint tint;
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      padding: const EdgeInsets.all(Dimens.spaceMd + 2),
      child: Row(
        children: [
          IconBadge.tint(icon, tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall),
                Text(subtitle, style: t.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  text: value,
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  children: [TextSpan(text: unit, style: t.bodySmall)],
                ),
              ),
              Text(badge, style: t.labelSmall?.copyWith(color: badgeColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final a = achievement;
    final def = a.definition;
    final tint = Visuals.achievementTint(def.icon);
    final group = def.scope == AchievementScope.group;
    return SereneCard(
      color: a.unlocked ? AppColors.surfaceLowest : AppColors.surfaceContainer,
      shadow: a.unlocked,
      radius: Dimens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge.tint(
                Visuals.achievementIcon(def.icon),
                a.unlocked
                    ? tint
                    : (
                        background: AppColors.surfaceHighest,
                        foreground: AppColors.onSurfaceVariant,
                      ),
                size: 52,
              ),
              const Spacer(),
              if (a.unlocked)
                PillBadge(
                  label: a.isNew ? 'Nova!' : 'Desbloqueado',
                  icon: Icons.verified_outlined,
                  dense: true,
                  background: a.isNew
                      ? AppColors.secondaryFixed
                      : AppColors.primaryFixed,
                  foreground: a.isNew ? AppColors.secondary : AppColors.primary,
                )
              else
                PillBadge(
                  label: '${a.progress} / ${def.target} ${def.unit}',
                  dense: true,
                  background: AppColors.surfaceLowest,
                ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Row(
            children: [
              Flexible(child: Text(def.title, style: t.headlineSmall)),
              if (group) ...[
                const SizedBox(width: 8),
                const PillBadge(
                  label: 'Em grupo',
                  icon: Icons.groups_outlined,
                  dense: true,
                  background: AppColors.secondaryFixed,
                  foreground: AppColors.secondary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(def.description, style: t.bodySmall),
          const SizedBox(height: Dimens.spaceMd),
          if (a.unlocked)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Conquistado em ${Dates.dayMonth(a.unlockedAt!)}',
                  style: t.labelMedium?.copyWith(color: AppColors.primaryContainer),
                ),
              ],
            )
          else ...[
            ProgressTrack(
              value: a.ratio,
              color: group ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  group ? 'Ritual em círculo' : 'Atenção plena',
                  style: t.bodySmall,
                ),
                const Spacer(),
                Text(
                  'Faltam ${a.remaining} ${def.unit.toLowerCase()}',
                  style: t.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
