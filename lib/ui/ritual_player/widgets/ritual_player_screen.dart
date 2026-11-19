import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/ritual.dart';
import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../../domain/use_cases/complete_ritual_step_use_case.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/ritual_player_viewmodel.dart';
import 'session_complete_view.dart';
import 'timer_ring.dart';

/// Player de ritual guiado por temporizador.
class RitualPlayerScreen extends StatefulWidget {
  const RitualPlayerScreen({super.key, required this.viewModel});

  final RitualPlayerViewModel viewModel;

  @override
  State<RitualPlayerScreen> createState() => _RitualPlayerScreenState();
}

class _RitualPlayerScreenState extends State<RitualPlayerScreen> {
  RitualPlayerViewModel get vm => widget.viewModel;
  bool _wasTimeUp = false;
  bool _immersive = false;

  @override
  void initState() {
    super.initState();
    vm.addListener(_onChange);
    vm.complete.addListener(_onCommand);
    vm.skip.addListener(_onCommand);
  }

  @override
  void dispose() {
    vm.removeListener(_onChange);
    vm.complete.removeListener(_onCommand);
    vm.skip.removeListener(_onCommand);
    if (_immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _onChange() {
    // Modo Zen: tela cheia enquanto o ritual acontece.
    if (vm.focusMode && !_immersive && !vm.finished) {
      _immersive = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    if (vm.finished && _immersive) {
      _immersive = false;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (vm.timeUp && !_wasTimeUp) HapticFeedback.mediumImpact();
    _wasTimeUp = vm.timeUp;
  }

  void _onCommand() {
    for (final c in [vm.complete, vm.skip]) {
      final r = c.result;
      if (r is Error<StepOutcome> && mounted) {
        showSnack(context, errorMessage(r.error));
        c.clearResult();
      }
    }
  }

  void _showSteps() {
    final ritual = vm.ritual;
    if (ritual == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < ritual.steps.length; i++)
              ListTile(
                leading: IconBadge.tint(
                  vm.completedIds.contains(ritual.steps[i].id)
                      ? Icons.check
                      : Visuals.stepIcon(ritual.steps[i].type),
                  Visuals.stepTint(ritual.steps[i].type),
                ),
                title: Text('${i + 1}. ${ritual.steps[i].title}'),
                subtitle: Text(Dates.mmss(ritual.steps[i].durationSeconds)),
                selected: i == vm.index,
                onTap: () {
                  vm.jumpTo(i);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([vm, vm.load]),
          builder: (context, _) {
            if (vm.load.running) return const LoadingView();
            if (vm.load.error || vm.ritual == null) {
              return ErrorIndicator(
                title: 'Não foi possível iniciar o ritual.',
                onRetry: vm.load.execute,
              );
            }
            if (vm.finished) {
              return SessionCompleteView(
                ritual: vm.ritual!,
                outcome: vm.lastOutcome,
                sessionSeconds: vm.sessionSeconds,
                unlocked: vm.unlocked,
                onDone: () => context.go(Routes.home),
                onSeeProgress: () => context.go(Routes.progress),
              );
            }
            return _Player(vm: vm, onShowSteps: _showSteps);
          },
        ),
      ),
    );
  }
}

class _Player extends StatelessWidget {
  const _Player({required this.vm, required this.onShowSteps});

  final RitualPlayerViewModel vm;
  final VoidCallback onShowSteps;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ritual = vm.ritual!;
    final step = vm.step!;
    final next = vm.nextStep;
    final busy = vm.complete.running || vm.skip.running;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Dimens.margin,
        0,
        Dimens.margin,
        Dimens.spaceLg,
      ),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Sessão Guiada',
                style: t.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SereneLogo(size: 34),
          ],
        ),
        const SizedBox(height: Dimens.spaceSm),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${ritual.period.eyebrow.toUpperCase()} • '
                '${vm.paused ? 'PAUSADO' : 'ATIVO'}',
                style: t.labelSmall?.copyWith(color: AppColors.primary),
              ),
            ),
            Text(
              'Passo ${vm.index + 1} de ${ritual.steps.length}',
              style: t.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: Dimens.spaceSm),
        Row(
          children: [
            for (var i = 0; i < ritual.steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: ProgressTrack(
                  height: 6,
                  value: vm.completedIds.contains(ritual.steps[i].id)
                      ? 1.0
                      : i == vm.index
                      ? vm.ringProgress
                      : 0.0,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Dimens.spaceMd),
        Row(
          children: [
            IconBadge.tint(
              Visuals.stepIcon(step.type),
              Visuals.stepTint(step.type),
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.title,
                style: t.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton.filledTonal(
              tooltip: vm.paused ? 'Retomar' : 'Pausar',
              onPressed: vm.togglePause,
              icon: Icon(vm.paused ? Icons.play_arrow : Icons.pause),
            ),
            IconButton.filledTonal(
              tooltip: 'Passos',
              onPressed: onShowSteps,
              icon: const Icon(Icons.expand_more),
            ),
          ],
        ),
        const SizedBox(height: Dimens.spaceMd),
        Container(
          padding: const EdgeInsets.all(Dimens.spaceLg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.surfaceContainer, Color(0xFFF5EFEA)],
            ),
            borderRadius: BorderRadius.circular(Dimens.radiusLg),
          ),
          child: Column(
            children: [
              TimerRing(
                progress: vm.ringProgress,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLowest,
                        shape: BoxShape.circle,
                        boxShadow: Dimens.cardShadow,
                      ),
                      child: Icon(
                        Visuals.stepIcon(step.type),
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      vm.timeUp ? '00:00' : Dates.mmss(vm.remainingSeconds),
                      style: t.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      vm.timeUp
                          ? 'tempo concluído ✓'
                          : 'de ${Dates.mmss(vm.plannedSeconds)} planejado',
                      style: t.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimens.spaceLg),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: t.headlineLarge,
              ),
              const SizedBox(height: Dimens.spaceMd),
              if (step.instruction.isNotEmpty)
                SereneCard(
                  padding: const EdgeInsets.all(Dimens.spaceMd + 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBadge(icon: Icons.air, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(step.instruction, style: t.bodyLarge),
                      ),
                    ],
                  ),
                ),
              if (step.ambientSound != null) ...[
                const SizedBox(height: Dimens.spaceMd),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        vm.soundOn
                            ? Icons.graphic_eq
                            : Icons.music_off_outlined,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.ambientSound!, style: t.titleSmall),
                            Text(
                              'Sons da Natureza • Binaural 432Hz',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceLowest,
                          foregroundColor: AppColors.onSurface,
                        ),
                        onPressed: vm.toggleSound,
                        icon: Icon(
                          vm.soundOn
                              ? Icons.volume_up_outlined
                              : Icons.volume_off_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (step.tip != null) ...[
          const SizedBox(height: Dimens.spaceMd),
          _InfoCard(
            icon: Icons.self_improvement,
            eyebrow: 'DICA CORPORAL',
            text: step.tip!,
          ),
        ],
        if (next != null) ...[
          const SizedBox(height: Dimens.spaceMd),
          _InfoCard(
            icon: Visuals.stepIcon(next.type),
            eyebrow: 'A SEGUIR',
            eyebrowColor: AppColors.onSurfaceVariant,
            text: 'Passo ${ritual.steps.indexOf(next) + 1}: ${next.title}',
            trailing: PillBadge(
              label: '${next.durationMinutes} min',
              background: AppColors.surfaceLowest,
            ),
          ),
        ],
        const SizedBox(height: Dimens.spaceLg),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceHigh,
                  foregroundColor: AppColors.onSurface,
                ),
                onPressed: vm.addMinute,
                icon: const Icon(Icons.more_time),
                label: const Text('+1 minuto'),
              ),
            ),
            const SizedBox(width: Dimens.gutter),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceHigh,
                  foregroundColor: AppColors.onSurface,
                ),
                onPressed: step.ambientSound == null ? null : vm.toggleSound,
                icon: Icon(
                  vm.soundOn
                      ? Icons.music_off_outlined
                      : Icons.music_note_outlined,
                ),
                label: Text(vm.soundOn ? 'Pausar som' : 'Tocar som'),
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimens.spaceMd),
        AnimatedScale(
          scale: vm.timeUp ? 1.03 : 1,
          duration: const Duration(milliseconds: 300),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              boxShadow: Dimens.floatingShadow,
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: busy ? null : vm.complete.execute,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Concluir ${_short(step)} (Avançar)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.check_circle_outline),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimens.spaceSm),
        Center(
          child: TextButton(
            onPressed: busy ? null : vm.skip.execute,
            child: Text(
              'Pular esta etapa',
              style: t.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  static String _short(RitualStep step) => step.title.split(' ').first;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.eyebrow,
    required this.text,
    this.eyebrowColor = AppColors.secondary,
    this.trailing,
  });

  final IconData icon;
  final String eyebrow;
  final String text;
  final Color eyebrowColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SereneCard(
      color: AppColors.surfaceContainer,
      shadow: false,
      padding: const EdgeInsets.all(Dimens.spaceMd),
      child: Row(
        children: [
          IconBadge(icon: icon, background: AppColors.surfaceHighest, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: t.labelSmall?.copyWith(color: eyebrowColor),
                ),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
