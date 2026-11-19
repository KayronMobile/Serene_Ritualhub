import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ritualhub/data/repositories/achievement/achievement_repository.dart';
import 'package:ritualhub/data/repositories/auth/auth_repository.dart';
import 'package:ritualhub/data/repositories/challenge/challenge_repository.dart';
import 'package:ritualhub/data/repositories/health/health_repository.dart';
import 'package:ritualhub/data/repositories/reminder/reminder_repository.dart';
import 'package:ritualhub/data/repositories/ritual/ritual_repository.dart';
import 'package:ritualhub/data/services/audio_service.dart';
import 'package:ritualhub/data/services/biometric_service.dart';
import 'package:ritualhub/data/services/image_picker_service.dart';
import 'package:ritualhub/data/services/notification_service.dart';
import 'package:ritualhub/routing/router.dart';
import 'package:ritualhub/routing/routes.dart';

import '../../testing/fakes/fake_environment.dart';

/// Renderiza cada tela em larguras de celulares pequenos e falha se
/// algum widget estourar (RenderFlex overflow).
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const sizes = [Size(320, 568), Size(360, 640), Size(412, 915)];
  final routes = <String>[
    Routes.login,
    Routes.register,
    Routes.home,
    Routes.rituals,
    Routes.newRitual,
    Routes.editRitual('ritual_morning'),
    Routes.player('ritual_morning'),
    Routes.community,
    Routes.progress,
    Routes.reminders,
    Routes.profile,
  ];

  for (final size in sizes) {
    for (final route in routes) {
      testWidgets('sem overflow em $route @ ${size.width.toInt()}x'
          '${size.height.toInt()}', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final env = await FakeEnvironment.create();
        if (route != Routes.login && route != Routes.register) {
          await env.signIn();
        }
        final router = buildTestRouter(env.auth, route);

        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final msg = d.exceptionAsString();
          if (msg.contains('overflowed')) {
            final where = d
                .toString()
                .split('\n')
                .firstWhere((l) => l.contains('file:///'), orElse: () => '');
            errors.add('$msg ${where.trim()}');
          } else if (!msg.contains('google_fonts') &&
              !msg.contains('GoogleFonts') &&
              !msg.contains('font')) {
            old?.call(d);
          }
        };

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<NotificationService>.value(value: env.notifications),
              Provider<BiometricService>.value(value: env.biometrics),
              Provider<PhotoService>.value(value: env.photos),
              Provider<AudioService>.value(value: env.audio),
              ChangeNotifierProvider<AuthRepository>.value(value: env.auth),
              ChangeNotifierProvider<RitualRepository>.value(
                value: env.rituals,
              ),
              ChangeNotifierProvider<HealthRepository>.value(value: env.health),
              ChangeNotifierProvider<ChallengeRepository>.value(
                value: env.challenges,
              ),
              ChangeNotifierProvider<AchievementRepository>.value(
                value: env.achievements,
              ),
              ChangeNotifierProvider<ReminderRepository>.value(
                value: env.reminders,
              ),
              Provider.value(value: env.weeklyReport),
              Provider.value(value: env.evaluateAchievements),
              Provider.value(value: env.planReminders),
              Provider.value(value: env.completeStep),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        // Rola até o fim para renderizar o conteúdo preguiçoso.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          for (var i = 0; i < 6; i++) {
            await tester.drag(
              scrollables.first,
              const Offset(0, -500),
              warnIfMissed: false,
            );
            await tester.pump(const Duration(milliseconds: 200));
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        FlutterError.onError = old;
        expect(errors.toSet().toList(), isEmpty);
      });
    }
  }
}

GoRouter buildTestRouter(AuthRepository auth, String initial) {
  final r = router(auth);
  Future.microtask(() => r.go(initial));
  return r;
}
