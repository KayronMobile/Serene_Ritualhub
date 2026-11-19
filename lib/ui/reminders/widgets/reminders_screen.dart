import 'package:flutter/material.dart';

import '../../../domain/models/reminder_settings.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/reminders_viewmodel.dart';

/// Ajuste dos lembretes inteligentes.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key, required this.viewModel});

  final RemindersViewModel viewModel;

  Future<int?> _pickTime(BuildContext context, int minutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final vm = viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes Inteligentes')),
      body: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.load]),
        builder: (context, _) {
          if (vm.load.running && vm.rituals.isEmpty) return const LoadingView();
          final s = vm.settings;
          void save(ReminderSettings next) => vm.update.execute(next);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.margin,
              Dimens.spaceSm,
              Dimens.margin,
              Dimens.spaceXl,
            ),
            children: [
              Text(
                'Notificações gentis que se adaptam ao seu dia: a água silencia '
                'quando a meta é batida e o alerta de telas antecipa no seu '
                'dia mais difícil.',
                style: t.bodyMedium,
              ),
              if (vm.permissionGranted == false) ...[
                const SizedBox(height: Dimens.spaceMd),
                const SereneCard(
                  color: AppColors.errorContainer,
                  shadow: false,
                  padding: EdgeInsets.all(Dimens.spaceMd),
                  child: Text(
                    'As notificações estão bloqueadas. Libere-as nos ajustes '
                    'do sistema para receber os lembretes.',
                  ),
                ),
              ],
              const SizedBox(height: Dimens.spaceLg),
              _Section(
                icon: Icons.wb_sunny_outlined,
                title: 'Início dos rituais',
                subtitle: '5 min antes e no horário de cada ritual',
                value: s.ritualStartEnabled,
                onChanged: (v) => save(s.copyWith(ritualStartEnabled: v)),
                children: [
                  for (final r in vm.rituals)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(Visuals.periodIcon(r.period)),
                      title: Text(r.name, style: t.titleSmall),
                      subtitle: Text(
                        '${Dates.hhmm(r.startMinutes)} · '
                        '5 min antes e na hora · '
                        '${r.activeWeekdays.length} dias/semana',
                        style: t.bodySmall,
                      ),
                      value: r.reminderEnabled && s.ritualStartEnabled,
                      onChanged: s.ritualStartEnabled
                          ? (_) => vm.toggleRitual.execute(r)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: Dimens.spaceMd),
              _Section(
                icon: Icons.local_fire_department_outlined,
                iconColor: AppColors.secondary,
                title: 'Sequência de dias',
                subtitle: 'Um resumo por dia da sua sequência',
                value: s.streakEnabled,
                onChanged: (v) => save(s.copyWith(streakEnabled: v)),
                children: [
                  _TimeRow(
                    label: 'Horário',
                    minutes: s.streakMinutes,
                    onTap: () async {
                      final m = await _pickTime(context, s.streakMinutes);
                      if (m != null) save(s.copyWith(streakMinutes: m));
                    },
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spaceMd),
              _Section(
                icon: Icons.favorite_border,
                title: 'Incentivos para voltar',
                subtitle: 'Se você ficar alguns dias sem abrir o app',
                value: s.comebackEnabled,
                onChanged: (v) => save(s.copyWith(comebackEnabled: v)),
                children: const [],
              ),
              const SizedBox(height: Dimens.spaceMd),
              _Section(
                icon: Icons.water_drop_outlined,
                iconColor: AppColors.tertiaryContainer,
                title: 'Intervalos de água',
                subtitle: '${s.waterSlots.length} lembretes por dia',
                value: s.waterEnabled,
                onChanged: (v) => save(s.copyWith(waterEnabled: v)),
                children: [
                  _TimeRow(
                    label: 'Primeiro lembrete',
                    minutes: s.waterStartMinutes,
                    onTap: () async {
                      final m = await _pickTime(context, s.waterStartMinutes);
                      if (m != null && m < s.waterEndMinutes) {
                        save(s.copyWith(waterStartMinutes: m));
                      }
                    },
                  ),
                  _TimeRow(
                    label: 'Último lembrete',
                    minutes: s.waterEndMinutes,
                    onTap: () async {
                      final m = await _pickTime(context, s.waterEndMinutes);
                      if (m != null && m > s.waterStartMinutes) {
                        save(s.copyWith(waterEndMinutes: m));
                      }
                    },
                  ),
                  const SizedBox(height: Dimens.spaceSm),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final i in const [60, 90, 120, 180])
                        ChoiceChip(
                          selected: s.waterIntervalMinutes == i,
                          label: Text(
                            i < 120 ? 'A cada $i min' : 'A cada ${i ~/ 60}h',
                          ),
                          onSelected: (_) =>
                              save(s.copyWith(waterIntervalMinutes: i)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spaceMd),
              _Section(
                icon: Icons.phonelink_off_outlined,
                iconColor: AppColors.rest,
                title: 'Desligar telas',
                subtitle: 'Higiene do sono à noite',
                value: s.screensOffEnabled,
                onChanged: (v) => save(s.copyWith(screensOffEnabled: v)),
                children: [
                  _TimeRow(
                    label: 'Horário',
                    minutes: s.screensOffMinutes,
                    onTap: () async {
                      final m = await _pickTime(context, s.screensOffMinutes);
                      if (m != null) save(s.copyWith(screensOffMinutes: m));
                    },
                  ),
                  if (s.vulnerableWeekday != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.secondary,
                      ),
                      title: Text(
                        '${Dates.weekdayLong[s.vulnerableWeekday! - 1]}: '
                        '${s.vulnerableLeadMinutes} min mais cedo',
                        style: t.titleSmall,
                      ),
                      subtitle: Text(
                        'Ajuste automático do relatório semanal',
                        style: t.bodySmall,
                      ),
                      trailing: IconButton(
                        tooltip: 'Remover ajuste',
                        onPressed: () =>
                            save(s.copyWith(clearVulnerableWeekday: true)),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Dimens.spaceLg),
              Center(
                child: PillBadge(
                  label: '${vm.scheduledCount} lembretes agendados',
                  icon: Icons.notifications_active_outlined,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.children,
    this.iconColor = AppColors.secondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      radius: Dimens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: icon,
                background: AppColors.surfaceContainer,
                foreground: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium),
                    Text(subtitle, style: t.bodySmall),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          if (value && children.isNotEmpty) ...[
            const SizedBox(height: Dimens.spaceSm),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    trailing: ActionChip(
      avatar: const Icon(Icons.schedule, size: 16),
      label: Text(Dates.hhmm(minutes)),
      onPressed: onTap,
    ),
    onTap: onTap,
  );
}
