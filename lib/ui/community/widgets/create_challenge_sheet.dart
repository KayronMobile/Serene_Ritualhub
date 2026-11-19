import 'package:flutter/material.dart';

import '../../../domain/models/challenge.dart';
import '../../../domain/models/user_profile.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/community_viewmodel.dart';

/// Formulário de criação de desafio temporário com amigos.
Future<bool?> showCreateChallengeSheet(
  BuildContext context,
  CommunityViewModel vm, {
  ChallengeTemplate? template,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  builder: (_) => CreateChallengeSheet(viewModel: vm, template: template),
);

class CreateChallengeSheet extends StatefulWidget {
  const CreateChallengeSheet({
    super.key,
    required this.viewModel,
    this.template,
  });

  final CommunityViewModel viewModel;
  final ChallengeTemplate? template;

  @override
  State<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<CreateChallengeSheet> {
  late final _title = TextEditingController(text: widget.template?.title);
  late final _description = TextEditingController(
    text: widget.template?.description,
  );
  late final _goal = TextEditingController(text: widget.template?.dailyGoal);
  late ChallengeCategory _category =
      widget.template?.category ?? ChallengeCategory.mindfulness;
  late int _days = widget.template?.durationDays ?? 21;
  final Set<String> _invited = {};

  CommunityViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.createChallenge.addListener(_onResult);
  }

  @override
  void dispose() {
    vm.createChallenge.removeListener(_onResult);
    _title.dispose();
    _description.dispose();
    _goal.dispose();
    super.dispose();
  }

  void _onResult() {
    final r = vm.createChallenge.result;
    if (r == null || !mounted) return;
    if (r is Error<Challenge>) {
      showSnack(context, errorMessage(r.error));
    } else {
      Navigator.pop(context, true);
    }
    vm.createChallenge.clearResult();
  }

  void _submit() {
    final invited = <UserProfile>[
      for (final f in vm.friends)
        if (_invited.contains(f.id)) f,
    ];
    if (invited.isEmpty) {
      showSnack(context, 'Convide ao menos um amigo — desafios são coletivos 🤝');
      return;
    }
    vm.createChallenge.execute((
      title: _title.text,
      description: _description.text,
      category: _category,
      durationDays: _days,
      dailyGoal: _goal.text,
      invited: invited,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            Dimens.margin,
            0,
            Dimens.margin,
            Dimens.spaceXl,
          ),
          children: [
            Text('Novo desafio coletivo', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Temporário, gentil e com placar de consistência.',
              style: t.bodySmall,
            ),
            const SizedBox(height: Dimens.spaceLg),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                hintText: 'Nome (ex.: 21 Dias Sem Açúcar)',
              ),
            ),
            const SizedBox(height: Dimens.spaceMd),
            TextField(
              controller: _description,
              decoration: const InputDecoration(hintText: 'Intenção do grupo'),
            ),
            const SizedBox(height: Dimens.spaceMd),
            TextField(
              controller: _goal,
              decoration: const InputDecoration(
                hintText: 'Meta diária para o check-in',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: Dimens.spaceLg),
            Text('CATEGORIA', style: t.labelSmall),
            const SizedBox(height: Dimens.spaceSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ChallengeCategory.values)
                  ChoiceChip(
                    selected: _category == c,
                    showCheckmark: false,
                    avatar: Icon(
                      Visuals.categoryIcon(c),
                      size: 16,
                      color: _category == c
                          ? AppColors.onPrimary
                          : AppColors.primaryContainer,
                    ),
                    label: Text(c.label),
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: Dimens.spaceLg),
            Text('DURAÇÃO: $_days DIAS', style: t.labelSmall),
            Slider(
              value: _days.toDouble(),
              min: 7,
              max: 60,
              divisions: 53,
              label: '$_days dias',
              onChanged: (v) => setState(() => _days = v.round()),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [7, 14, 21, 30])
                  ActionChip(
                    label: Text('$d dias'),
                    onPressed: () => setState(() => _days = d),
                  ),
              ],
            ),
            const SizedBox(height: Dimens.spaceLg),
            Text('CONVIDAR AMIGOS', style: t.labelSmall),
            const SizedBox(height: Dimens.spaceSm),
            for (final f in vm.friends)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _invited.contains(f.id),
                onChanged: (v) => setState(
                  () => (v ?? false) ? _invited.add(f.id) : _invited.remove(f.id),
                ),
                secondary: UserAvatar(user: f, size: 36),
                title: Text(f.name),
                activeColor: AppColors.primaryContainer,
              ),
            const SizedBox(height: Dimens.spaceLg),
            ListenableBuilder(
              listenable: vm.createChallenge,
              builder: (context, _) => FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                ),
                onPressed: vm.createChallenge.running ? null : _submit,
                icon: const Icon(Icons.local_fire_department_outlined),
                label: Text('Começar desafio (${_invited.length + 1} pessoas)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
