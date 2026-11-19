import 'package:flutter/material.dart';

import '../../../domain/models/health.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';

/// Registro de água com atalhos de volume.
Future<void> showWaterSheet(
  BuildContext context, {
  required HealthGoals goals,
  required void Function(int ml) onSave,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) {
    final t = Theme.of(context).textTheme;
    const presets = [150, 250, 350, 500, 750];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.margin,
        0,
        Dimens.margin,
        Dimens.spaceLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.water_drop_outlined,
                background: AppColors.tertiaryFixed,
                foreground: AppColors.tertiaryContainer,
              ),
              const SizedBox(width: 12),
              Text('Quanto você bebeu?', style: t.headlineSmall),
            ],
          ),
          const SizedBox(height: Dimens.spaceLg),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final ml in presets)
                ActionChip(
                  avatar: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.tertiary,
                  ),
                  label: Text('$ml ml'),
                  backgroundColor: AppColors.tertiaryFixed,
                  onPressed: () {
                    onSave(ml);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          TextButton.icon(
            onPressed: () {
              onSave(-goals.waterIncrementMl);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.undo),
            label: Text('Desfazer ${goals.waterIncrementMl} ml'),
          ),
        ],
      ),
    );
  },
);

/// Registro de sono com duração e eficácia percebida.
Future<void> showSleepSheet(
  BuildContext context, {
  required int initialMinutes,
  required int initialQuality,
  required void Function(int minutes, int? quality) onSave,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) {
    var minutes = initialMinutes.clamp(180, 720).toDouble();
    var quality = initialQuality.clamp(40, 100).toDouble();
    final t = Theme.of(context).textTheme;
    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.margin,
          0,
          Dimens.margin,
          Dimens.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(
                  icon: Icons.bedtime_outlined,
                  background: AppColors.restContainer,
                  foreground: AppColors.rest,
                ),
                const SizedBox(width: 12),
                Text('Como foi sua noite?', style: t.headlineSmall),
              ],
            ),
            const SizedBox(height: Dimens.spaceLg),
            Text('Horas de sono', style: t.labelMedium),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: minutes,
                    min: 180,
                    max: 720,
                    divisions: 36,
                    activeColor: AppColors.rest,
                    onChanged: (v) => setState(() => minutes = v),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    Dates.hoursMinutes(minutes.round()),
                    textAlign: TextAlign.end,
                    style: t.titleMedium,
                  ),
                ),
              ],
            ),
            Text('Eficácia percebida', style: t.labelMedium),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: quality,
                    min: 40,
                    max: 100,
                    divisions: 12,
                    activeColor: AppColors.primaryContainer,
                    onChanged: (v) => setState(() => quality = v),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${quality.round()}%',
                    textAlign: TextAlign.end,
                    style: t.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimens.spaceMd),
            FilledButton(
              onPressed: () {
                onSave(minutes.round(), quality.round());
                Navigator.pop(context);
              },
              child: const Text('Salvar descanso'),
            ),
          ],
        ),
      ),
    );
  },
);

/// Registro de minutos (leitura/atividade).
Future<void> showMinutesSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required void Function(int minutes) onSave,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) {
    var value = 10;
    final t = Theme.of(context).textTheme;
    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.margin,
          0,
          Dimens.margin,
          Dimens.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: icon),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: t.headlineSmall)),
              ],
            ),
            const SizedBox(height: Dimens.spaceLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: value > 5 ? () => setState(() => value -= 5) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    '$value min',
                    textAlign: TextAlign.center,
                    style: t.headlineLarge,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(() => value += 5),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: Dimens.spaceLg),
            FilledButton(
              onPressed: () {
                onSave(value);
                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  },
);
