import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/domain/models/reminder_settings.dart';
import 'package:ritualhub/ui/home/view_models/home_viewmodel.dart';

import '../../testing/fakes/fake_environment.dart';
import '../../testing/utils.dart';

void main() {
  late FakeEnvironment env;
  late HomeViewModel vm;

  setUp(() async {
    env = await FakeEnvironment.create();
    await env.signIn();
    vm = HomeViewModel(
      authRepository: env.auth,
      ritualRepository: env.rituals,
      healthRepository: env.health,
      challengeRepository: env.challenges,
      planReminders: env.planReminders,
      clock: env.clock,
    );
    await settle(vm.load);
  });

  tearDown(() => vm.dispose());

  test('monta o dia com saudação, ritual em destaque e desafios', () {
    expect(vm.greeting, 'Bom dia');
    expect(vm.user!.firstName, 'Lucas');
    expect(vm.featured, isNotNull);
    expect(vm.featured!.ritual.id, 'ritual_morning');
    expect(vm.featured!.completedCount, 1);
    expect(vm.activeChallenges, isNotEmpty);
    expect(vm.streak, greaterThan(0));
  });

  test('+250ml atualiza a hidratação e replaneja os lembretes', () async {
    final before = vm.healthLog!.waterMl;
    await vm.addWater.execute(250);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(vm.healthLog!.waterMl, before + 250);
    expect(
      env.notifications.scheduled.where(
        (r) => r.channel == ReminderChannel.water,
      ),
      isNotEmpty,
    );
  });

  test('registrar sono substitui o valor do dia', () async {
    await vm.logSleep.execute((minutes: 420, quality: 88));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(vm.healthLog!.sleepMinutes, 420);
    expect(vm.healthLog!.deepSleepPercent, 88);
  });
}
