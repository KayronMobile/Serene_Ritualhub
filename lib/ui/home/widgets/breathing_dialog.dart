import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';

/// Micro-pausa guiada de 1 minuto: ciclos 4-4-6 (inspira, retém, expira).
class BreathingDialog extends StatefulWidget {
  const BreathingDialog({super.key});

  @override
  State<BreathingDialog> createState() => _BreathingDialogState();
}

class _BreathingDialogState extends State<BreathingDialog> {
  static const _phases = [
    ('Inspire', 4, 1.0),
    ('Retenha', 4, 1.0),
    ('Expire', 6, 0.55),
  ];
  static const _total = 60;

  Timer? _timer;
  int _elapsed = 0;
  bool _kicked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _kicked = true);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _elapsed++);
      if (_phaseStart(_elapsed)) HapticFeedback.selectionClick();
      if (_elapsed >= _total) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _phaseStart(int s) {
    final c = s % 14;
    return c == 0 || c == 4 || c == 8;
  }

  (String, int, double) get _phase {
    final c = _elapsed % 14;
    if (c < 4) return _phases[0];
    if (c < 8) return _phases[1];
    return _phases[2];
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final done = _elapsed >= _total;
    final (label, seconds, scale) = _phase;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Micro-pausa', style: t.headlineSmall),
            const SizedBox(height: Dimens.spaceLg),
            SizedBox(
              width: 180,
              height: 180,
              child: Center(
                child: AnimatedScale(
                  scale: done ? 0.8 : (_kicked ? scale : 0.55),
                  duration: Duration(seconds: done ? 1 : seconds),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryFixed,
                          AppColors.primaryFixedDim.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      done ? 'Pronto' : label,
                      style: t.headlineMedium?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Dimens.spaceMd),
            Text(
              done
                  ? 'Seu ritmo cardíaco agradece. 🌿'
                  : '${_total - _elapsed}s restantes',
              style: t.bodyMedium,
            ),
            const SizedBox(height: Dimens.spaceLg),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(done ? 'Concluir' : 'Encerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
