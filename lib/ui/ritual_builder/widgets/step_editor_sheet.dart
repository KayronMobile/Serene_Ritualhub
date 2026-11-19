import 'package:flutter/material.dart';

import '../../../domain/models/ritual.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/visuals.dart';
import '../view_models/ritual_builder_viewmodel.dart';

/// Abre o editor de um bloco de ação. Retorna o passo editado (ou `null`).
Future<RitualStep?> showStepEditor(BuildContext context, {RitualStep? step}) =>
    showModalBottomSheet<RitualStep>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StepEditorSheet(step: step),
    );

class StepEditorSheet extends StatefulWidget {
  const StepEditorSheet({super.key, this.step});

  final RitualStep? step;

  @override
  State<StepEditorSheet> createState() => _StepEditorSheetState();
}

class _StepEditorSheetState extends State<StepEditorSheet> {
  late final _title = TextEditingController(text: widget.step?.title ?? '');
  late final _description = TextEditingController(
    text: widget.step?.description ?? '',
  );
  late final _instruction = TextEditingController(
    text: widget.step?.instruction ?? '',
  );
  late final _tip = TextEditingController(text: widget.step?.tip ?? '');
  late StepType _type = widget.step?.type ?? StepType.custom;
  late int _seconds = widget.step?.durationSeconds ?? 300;
  late String? _sound = widget.step?.ambientSound;
  late int _waterMl = widget.step?.waterMl ?? 500;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instruction.dispose();
    _tip.dispose();
    super.dispose();
  }

  void _changeDuration(int deltaSeconds) =>
      setState(() => _seconds = (_seconds + deltaSeconds).clamp(30, 120 * 60));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.step;
    final step = RitualStep(
      id: base?.id ?? Ids.generate('step'),
      title: _title.text.trim(),
      type: _type,
      durationSeconds: _seconds,
      description: _description.text.trim(),
      instruction: _instruction.text.trim().isEmpty
          ? _description.text.trim()
          : _instruction.text.trim(),
      ambientSound: _sound,
      tip: _tip.text.trim().isEmpty ? null : _tip.text.trim(),
      waterMl: _type == StepType.hydration ? _waterMl : null,
      pages: base?.pages,
    );
    Navigator.pop(context, step);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, controller) => Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
              Dimens.margin,
              0,
              Dimens.margin,
              Dimens.spaceXl,
            ),
            children: [
              Text(
                widget.step == null ? 'Novo bloco de ação' : 'Editar bloco',
                style: t.headlineMedium,
              ),
              const SizedBox(height: Dimens.spaceLg),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Nome do passo'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Dê um nome ao passo'
                    : null,
              ),
              const SizedBox(height: Dimens.spaceLg),
              Text('TIPO', style: t.labelSmall),
              const SizedBox(height: Dimens.spaceSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in StepType.values)
                    ChoiceChip(
                      selected: _type == type,
                      showCheckmark: false,
                      avatar: Icon(
                        Visuals.stepIcon(type),
                        size: 16,
                        color: _type == type
                            ? AppColors.onPrimary
                            : AppColors.primaryContainer,
                      ),
                      label: Text(
                        type.label,
                        style: TextStyle(
                          color: _type == type
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                        ),
                      ),
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: Dimens.spaceLg),
              Text('DURAÇÃO DO TEMPORIZADOR', style: t.labelSmall),
              const SizedBox(height: Dimens.spaceSm),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _changeDuration(-60),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      Dates.mmss(_seconds),
                      textAlign: TextAlign.center,
                      style: t.headlineLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _changeDuration(60),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (_type == StepType.hydration) ...[
                const SizedBox(height: Dimens.spaceLg),
                Text('META DE VOLUME (ML)', style: t.labelSmall),
                Slider(
                  value: _waterMl.toDouble(),
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  label: '$_waterMl ml',
                  activeColor: AppColors.hydration,
                  onChanged: (v) => setState(() => _waterMl = v.round()),
                ),
                Text(
                  'Ao concluir, $_waterMl ml entram no rastreador de água.',
                  style: t.bodySmall,
                ),
              ],
              if (_type.metric != null && _type != StepType.hydration)
                Padding(
                  padding: const EdgeInsets.only(top: Dimens.spaceSm),
                  child: Text(
                    'Os minutos deste passo alimentam automaticamente o '
                    'rastreador de ${_type.metric == HealthMetric.reading ? 'leitura' : 'atividade física'}.',
                    style: t.bodySmall,
                  ),
                ),
              const SizedBox(height: Dimens.spaceLg),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  hintText: 'Resumo (ex.: 500ml de água morna com limão)',
                ),
              ),
              const SizedBox(height: Dimens.spaceMd),
              TextFormField(
                controller: _instruction,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Instrução exibida no player guiado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: Dimens.spaceMd),
              TextFormField(
                controller: _tip,
                decoration: const InputDecoration(
                  hintText: 'Dica corporal (opcional)',
                ),
              ),
              const SizedBox(height: Dimens.spaceLg),
              Text('SOM AMBIENTE', style: t.labelSmall),
              const SizedBox(height: Dimens.spaceSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _sound == null,
                    label: const Text('Silêncio'),
                    onSelected: (_) => setState(() => _sound = null),
                  ),
                  for (final s in RitualBuilderViewModel.ambientSounds)
                    ChoiceChip(
                      selected: _sound == s,
                      label: Text(s),
                      onSelected: (_) => setState(() => _sound = s),
                    ),
                ],
              ),
              const SizedBox(height: Dimens.spaceXl),
              FilledButton(
                onPressed: _submit,
                child: Text(
                  widget.step == null ? 'Adicionar ao ritual' : 'Salvar bloco',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
