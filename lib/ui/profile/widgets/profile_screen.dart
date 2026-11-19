import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../view_models/profile_viewmodel.dart';

/// Perfil do usuário e metas dos rastreadores de saúde.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.viewModel});

  final ProfileViewModel viewModel;

  Future<void> _rename(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: viewModel.user?.name ?? ''),
    );
    if (name == null) return;
    await viewModel.rename.execute(name);
    final r = viewModel.rename.result;
    if (!context.mounted) return;
    if (r is Error<void>) {
      showSnack(context, errorMessage(r.error));
    } else {
      showSnack(context, 'Nome atualizado.');
    }
    viewModel.rename.clearResult();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final vm = viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil & Metas')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final g = vm.goals;
          final user = vm.user;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.margin,
              Dimens.spaceSm,
              Dimens.margin,
              Dimens.spaceXl,
            ),
            children: [
              if (user != null)
                SereneCard(
                  onTap: () => _rename(context),
                  child: Row(
                    children: [
                      UserAvatar(user: user, size: 56),
                      const SizedBox(width: Dimens.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: t.headlineSmall),
                            Text(user.email, style: t.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined),
                    ],
                  ),
                ),
              const SizedBox(height: Dimens.spaceLg),
              const SectionHeader(title: 'Metas diárias'),
              const SizedBox(height: Dimens.spaceMd),
              SereneCard(
                child: Column(
                  children: [
                    _GoalSlider(
                      icon: Icons.water_drop_outlined,
                      color: AppColors.hydration,
                      label: 'Água',
                      value: g.waterMl.toDouble(),
                      min: 1000,
                      max: 4500,
                      divisions: 35,
                      display: '${g.waterMl} ml',
                      onChanged: (v) =>
                          vm.editGoals(g.copyWith(waterMl: v.round())),
                    ),
                    _GoalSlider(
                      icon: Icons.add_circle_outline,
                      color: AppColors.hydration,
                      label: 'Botão rápido de água',
                      value: g.waterIncrementMl.toDouble(),
                      min: 100,
                      max: 750,
                      divisions: 13,
                      display: '+${g.waterIncrementMl} ml',
                      onChanged: (v) =>
                          vm.editGoals(g.copyWith(waterIncrementMl: v.round())),
                    ),
                    _GoalSlider(
                      icon: Icons.bedtime_outlined,
                      color: AppColors.rest,
                      label: 'Sono',
                      value: g.sleepMinutes.toDouble(),
                      min: 300,
                      max: 600,
                      divisions: 20,
                      display: Dates.hoursMinutes(g.sleepMinutes),
                      onChanged: (v) =>
                          vm.editGoals(g.copyWith(sleepMinutes: v.round())),
                    ),
                    _GoalSlider(
                      icon: Icons.directions_run,
                      color: AppColors.primaryContainer,
                      label: 'Atividade física',
                      value: g.activityMinutes.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 22,
                      display: '${g.activityMinutes} min',
                      onChanged: (v) =>
                          vm.editGoals(g.copyWith(activityMinutes: v.round())),
                    ),
                    _GoalSlider(
                      icon: Icons.menu_book_outlined,
                      color: AppColors.secondary,
                      label: 'Leitura',
                      value: g.readingMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      display: '${g.readingMinutes} min',
                      onChanged: (v) =>
                          vm.editGoals(g.copyWith(readingMinutes: v.round())),
                    ),
                    const SizedBox(height: Dimens.spaceSm),
                    ListenableBuilder(
                      listenable: vm.saveGoals,
                      builder: (context, _) => FilledButton(
                        onPressed: vm.saveGoals.running
                            ? null
                            : () async {
                                await vm.saveGoals.execute(vm.goals);
                                if (context.mounted) {
                                  showSnack(context, 'Metas atualizadas 🌿');
                                }
                              },
                        child: const Text('Salvar metas'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimens.spaceLg),
              SereneCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Lembretes inteligentes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.reminders),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: const Text(
                        'Sair',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: vm.logout.execute,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalSlider extends StatelessWidget {
  const _GoalSlider({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: t.titleSmall)),
            Text(display, style: t.labelLarge),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Diálogo de edição do nome. O [TextEditingController] vive no State do
/// próprio diálogo, então só é descartado depois da animação de fechamento.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Seu nome'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _save(),
        validator: (v) =>
            (v == null || v.trim().length < 2) ? 'Mínimo de 2 letras' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );
}
