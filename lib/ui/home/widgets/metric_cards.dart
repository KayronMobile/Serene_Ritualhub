import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../domain/models/health.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import 'metric_sheets.dart';

/// Grade 2x2 com os rastreadores de saúde (água, sono, leitura, movimento).
class MetricGrid extends StatelessWidget {
  const MetricGrid({
    super.key,
    required this.log,
    required this.goals,
    required this.onAddWater,
    required this.onLogSleep,
    required this.onAddReading,
    required this.onAddActivity,
  });

  final DailyHealthLog log;
  final HealthGoals goals;
  final void Function(int ml) onAddWater;
  final void Function(int minutes, int? quality) onLogSleep;
  final void Function(int minutes) onAddReading;
  final void Function(int minutes) onAddActivity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _hydration(context)),
              const SizedBox(width: Dimens.gutter),
              Expanded(child: _sleep(context)),
            ],
          ),
        ),
        const SizedBox(height: Dimens.gutter),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.menu_book_outlined,
                  tint: AppColors.secondaryFixed,
                  accent: AppColors.secondary,
                  label: 'Leitura & Mente',
                  value: '${log.readingMinutes}',
                  goal: ' /${goals.readingMinutes} min',
                  progress: log.readingProgress(goals),
                  onTap: () => showMinutesSheet(
                    context,
                    title: 'Registrar leitura',
                    icon: Icons.menu_book_outlined,
                    onSave: onAddReading,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.gutter),
              Expanded(
                child: _MetricCard(
                  icon: Icons.directions_run,
                  tint: AppColors.surfaceHighest,
                  accent: AppColors.primaryContainer,
                  label: 'Movimento Leve',
                  value: '${log.activityMinutes}',
                  goal: ' /${goals.activityMinutes} min',
                  progress: log.activityProgress(goals),
                  onTap: () => showMinutesSheet(
                    context,
                    title: 'Registrar atividade física',
                    icon: Icons.directions_run,
                    onSave: onAddActivity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hydration(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = (log.waterProgress(goals) * 100).round();
    return SereneCard(
      padding: const EdgeInsets.all(Dimens.spaceMd + 2),
      onTap: () => showWaterSheet(context, goals: goals, onSave: onAddWater),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.water_drop_outlined,
                background: AppColors.tertiaryFixed,
                foreground: AppColors.tertiaryContainer,
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: t.labelLarge?.copyWith(color: AppColors.tertiaryContainer),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Text('Hidratação', style: t.labelMedium),
          const SizedBox(height: 2),
          _ValueLine(value: _thousands(log.waterMl), goal: ' /${_thousands(goals.waterMl)}ml'),
          const SizedBox(height: Dimens.spaceMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: AppColors.tertiaryFixed,
                foregroundColor: AppColors.tertiary,
                padding: EdgeInsets.zero,
              ),
              onPressed: () => onAddWater(goals.waterIncrementMl),
              icon: const Icon(Icons.add, size: 18),
              label: Text('+${goals.waterIncrementMl}ml'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sleep(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hit = log.sleepMinutes >= goals.sleepMinutes;
    return SereneCard(
      padding: const EdgeInsets.all(Dimens.spaceMd + 2),
      onTap: () => showSleepSheet(
        context,
        initialMinutes: log.sleepMinutes == 0 ? goals.sleepMinutes : log.sleepMinutes,
        initialQuality: log.deepSleepPercent ?? 85,
        onSave: onLogSleep,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.bedtime_outlined,
                background: AppColors.primaryFixed,
                foreground: AppColors.primaryContainer,
              ),
              const Spacer(),
              if (hit)
                const PillBadge(label: 'Meta ✓', dense: true)
              else if (log.sleepMinutes > 0)
                Text(
                  '${(log.sleepProgress(goals) * 100).round()}%',
                  style: t.labelLarge,
                ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Text('Descanso', style: t.labelMedium),
          const SizedBox(height: 2),
          Text(
            log.sleepMinutes == 0 ? 'Registrar' : Dates.hoursMinutes(log.sleepMinutes),
            style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (log.deepSleepPercent != null)
            Row(
              children: [
                Text('Profundo', style: t.bodySmall),
                const Spacer(),
                Text(
                  '${log.deepSleepPercent}% eficácia',
                  style: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _thousands(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.value, required this.goal});

  final String value;
  final String goal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: t.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: goal,
            style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.tint,
    required this.accent,
    required this.label,
    required this.value,
    required this.goal,
    required this.progress,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color accent;
  final String label;
  final String value;
  final String goal;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      padding: const EdgeInsets.all(Dimens.spaceMd + 2),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, background: tint, foreground: accent),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: t.labelLarge?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          Text(label, style: t.labelMedium),
          const SizedBox(height: 2),
          _ValueLine(value: value, goal: goal),
          const SizedBox(height: Dimens.spaceSm),
          ProgressTrack(value: progress, color: accent, height: 6),
        ],
      ),
    );
  }
}
