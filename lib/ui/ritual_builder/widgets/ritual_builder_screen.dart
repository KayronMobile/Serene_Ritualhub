import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/ritual.dart';
import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/ritual_builder_viewmodel.dart';
import 'step_card.dart';
import 'step_editor_sheet.dart';

/// Construtor de rituais sequenciais.
class RitualBuilderScreen extends StatefulWidget {
  const RitualBuilderScreen({super.key, required this.viewModel});

  final RitualBuilderViewModel viewModel;

  @override
  State<RitualBuilderScreen> createState() => _RitualBuilderScreenState();
}

class _RitualBuilderScreenState extends State<RitualBuilderScreen> {
  final _name = TextEditingController();
  bool _openPlayerAfterSave = false;

  RitualBuilderViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.load.addListener(_onLoaded);
    vm.save.addListener(_onSaved);
  }

  @override
  void dispose() {
    vm.load.removeListener(_onLoaded);
    vm.save.removeListener(_onSaved);
    _name.dispose();
    super.dispose();
  }

  void _onLoaded() {
    if (vm.load.completed) _name.text = vm.name;
    if (vm.load.error && mounted) {
      showSnack(context, 'Não foi possível abrir este ritual.');
    }
  }

  void _onSaved() {
    final r = vm.save.result;
    if (r == null || !mounted) return;
    switch (r) {
      case Ok<Ritual>():
        showSnack(context, 'Ritual salvo e lembretes atualizados 🌿');
        if (_openPlayerAfterSave) {
          context.pushReplacement(Routes.player(r.value.id));
        } else {
          context.pop();
        }
      case Error<Ritual>():
        showSnack(context, errorMessage(r.error));
    }
    vm.save.clearResult();
  }

  void _save({bool openPlayer = false}) {
    _openPlayerAfterSave = openPlayer;
    vm.setName(_name.text);
    vm.save.execute();
  }

  Future<void> _addStep() async {
    final step = await showStepEditor(context);
    if (step != null) vm.addStep(step);
  }

  Future<void> _editStep(RitualStep step) async {
    final edited = await showStepEditor(context, step: step);
    if (edited != null) vm.updateStep(edited);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: vm.startMinutes ~/ 60,
        minute: vm.startMinutes % 60,
      ),
    );
    if (picked != null) vm.setStart(picked.hour * 60 + picked.minute);
  }

  Future<void> _pickChallenge() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Nenhum desafio'),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final c in vm.activeChallenges)
              ListTile(
                leading: IconBadge.tint(
                  Visuals.categoryIcon(c.category),
                  Visuals.categoryTint(c.category),
                ),
                title: Text(c.title),
                subtitle: Text('${c.members.length} participantes'),
                onTap: () => Navigator.pop(context, c.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    vm.setLinkedChallenge(selected.isEmpty ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isNew ? 'Novo Ritual' : 'Construtor de Rituais'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: AppColors.primary,
              ),
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Salvar'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.load]),
        builder: (context, _) {
          if (vm.load.running) return const LoadingView();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: Dimens.screenPadding,
                sliver: SliverToBoxAdapter(child: _header(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.margin,
                  Dimens.spaceXl,
                  Dimens.margin,
                  Dimens.spaceMd,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.reorder,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Passos Consecutivos',
                          style: t.headlineMedium,
                        ),
                      ),
                      Text(
                        'ARRASTE PARA\nORDENAR',
                        textAlign: TextAlign.end,
                        style: t.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: Dimens.screenPadding,
                sliver: SliverReorderableList(
                  itemCount: vm.steps.length,
                  onReorder: vm.moveStep,
                  itemBuilder: (context, i) {
                    final step = vm.steps[i];
                    return Padding(
                      key: ValueKey(step.id),
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          StepCard(
                            index: i,
                            step: step,
                            onEdit: () => _editStep(step),
                            onDuplicate: () => vm.duplicateStep(step.id),
                            onDelete: () => vm.removeStep(step.id),
                          ),
                          if (i < vm.steps.length - 1) const StepConnector(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: Dimens.screenPadding,
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: Dimens.spaceMd),
                    SereneCard(
                      radius: 999,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onTap: _addStep,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Adicionar Novo Bloco de Ação',
                              style: t.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.spaceMd),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text('Sugestões:', style: t.labelMedium),
                          const SizedBox(width: 8),
                          for (final s in RitualBuilderViewModel.suggestions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text('+ ${s.title}'),
                                onPressed: () => vm.addSuggestion(s),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.spaceXl),
                    _schedule(context),
                    const SizedBox(height: Dimens.spaceLg),
                    _tribe(context),
                    const SizedBox(height: Dimens.spaceXl),
                    ListenableBuilder(
                      listenable: vm.save,
                      builder: (context, _) => FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: vm.save.running ? null : _save,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Salvar & Ativar Ritual'),
                      ),
                    ),
                    const SizedBox(height: Dimens.spaceMd),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLowest,
                      ),
                      onPressed: vm.steps.isEmpty
                          ? null
                          : () => _save(openPlayer: true),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Testar no Player Agora'),
                    ),
                    const SizedBox(height: Dimens.spaceXl),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Dimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(Dimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(Dimens.radius),
                ),
                child: Icon(Visuals.periodIcon(vm.period), size: 28),
              ),
              const SizedBox(width: Dimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOME DA JORNADA', style: t.labelSmall),
                    TextField(
                      controller: _name,
                      onChanged: vm.setName,
                      style: t.headlineSmall,
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        hintText: 'Ex.: Despertar & Foco Sereno',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        suffixIcon: Icon(Icons.edit_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Wrap(
            spacing: 8,
            children: [
              for (final p in RitualPeriod.values)
                ChoiceChip(
                  selected: vm.period == p,
                  showCheckmark: false,
                  avatar: Icon(
                    Visuals.periodIcon(p),
                    size: 16,
                    color: vm.period == p
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                  label: Text(p.label),
                  onSelected: (_) => vm.setPeriod(p),
                ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(Icons.timelapse, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tempo Total Estimado',
                    style: t.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PillBadge(label: '${vm.totalMinutes} min', dense: true),
                const SizedBox(width: 8),
                Text('• ${vm.steps.length}', style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _schedule(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      radius: Dimens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.event_repeat,
                background: AppColors.surfaceContainer,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frequência & Horário', style: t.headlineSmall),
                    Text(
                      'Constância ritmada para sua semana',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceLg),
          Text('DIAS ATIVOS', style: t.labelSmall),
          const SizedBox(height: Dimens.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 1; d <= 7; d++)
                Flexible(
                  child: InkResponse(
                    onTap: () => vm.toggleDay(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: vm.activeWeekdays.contains(d)
                            ? AppColors.primary
                            : AppColors.surfaceContainer,
                      ),
                      child: Text(
                        Dates.weekdayLetter[d - 1],
                        style: t.labelLarge?.copyWith(
                          color: vm.activeWeekdays.contains(d)
                              ? AppColors.onPrimary
                              : AppColors.outline,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Dimens.spaceLg),
          _SettingTile(
            icon: Icons.alarm,
            title: 'Início Desejado',
            subtitleWidget: Text(
              Dates.hhmm(vm.startMinutes),
              style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            trailing: ActionChip(
              label: const Text('Alterar'),
              onPressed: _pickTime,
            ),
          ),
          const SizedBox(height: Dimens.spaceSm),
          _SettingTile(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.secondary,
            title: 'Lembrete Suave',
            subtitle: 'Notificação ${vm.reminderLead} min antes',
            onTap: vm.reminderEnabled
                ? () => vm.setReminderLead(switch (vm.reminderLead) {
                    5 => 10,
                    10 => 15,
                    15 => 30,
                    _ => 5,
                  })
                : null,
            trailing: Switch(
              value: vm.reminderEnabled,
              onChanged: vm.setReminder,
            ),
          ),
          const SizedBox(height: Dimens.spaceSm),
          _SettingTile(
            icon: Icons.do_not_disturb_on_outlined,
            title: 'Pausa de Telas (Zen)',
            subtitle: 'Player em tela cheia, sem distrações',
            trailing: Switch(value: vm.focusMode, onChanged: vm.setFocusMode),
          ),
        ],
      ),
    );
  }

  Widget _tribe(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final linked = vm.linkedChallenge;
    return SereneCard(
      radius: Dimens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.groups_outlined,
                background: AppColors.secondaryFixed,
                foreground: AppColors.secondary,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tribo & Desafios', style: t.headlineSmall),
                    Text('A força do compromisso coletivo', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          InkWell(
            borderRadius: BorderRadius.circular(Dimens.radius),
            onTap: _pickChallenge,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(Dimens.radius),
              ),
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.local_fire_department_outlined,
                    background: AppColors.terracotta,
                    foreground: AppColors.onSecondary,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: linked == null
                        ? Text(
                            'Vincular a um desafio coletivo',
                            style: t.titleSmall,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DESAFIO COLETIVO · ATIVO',
                                style: t.labelSmall?.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                              Text(linked.title, style: t.titleSmall),
                              Text(
                                '${linked.members.length} participantes',
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                  ),
                  const Icon(Icons.sync_alt),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimens.spaceMd),
          Row(
            children: [
              const Icon(Icons.share_outlined, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Compartilhar conclusão com a tribo (check-in automático)',
                  style: t.bodyMedium,
                ),
              ),
              Switch(
                value: vm.shareWithTribe,
                onChanged: linked == null ? null : vm.setShareWithTribe,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.subtitleWidget,
    this.iconColor = AppColors.onSurfaceVariant,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget trailing;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(Dimens.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleSmall),
                    if (subtitleWidget != null) subtitleWidget!,
                    if (subtitle != null) Text(subtitle!, style: t.bodySmall),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
