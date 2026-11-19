import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/ui/ritual_player/view_models/ritual_player_viewmodel.dart';

import '../../testing/fakes/fake_environment.dart';
import '../../testing/utils.dart';

void main() {
  late FakeEnvironment env;
  late RitualPlayerViewModel vm;

  setUp(() async {
    env = await FakeEnvironment.create();
    await env.signIn();
    vm = RitualPlayerViewModel(
      ritualId: 'ritual_morning',
      ritualRepository: env.rituals,
      authRepository: env.auth,
      completeStep: env.completeStep,
      evaluateAchievements: env.evaluateAchievements,
      clock: env.clock,
      tick: const Duration(hours: 1), // o timer não interfere no teste
    );
    await settle(vm.load);
  });

  tearDown(() => vm.dispose());

  test('retoma no primeiro passo pendente do dia', () {
    expect(vm.load.completed, isTrue);
    // O seed marca a hidratação (passo 1) como concluída hoje.
    expect(vm.index, 1);
    expect(vm.step!.title, 'Alongamento & Mobilidade');
    expect(vm.remainingSeconds, 420);
    expect(vm.nextStep!.title, 'Respiração Focada & Leitura');
  });

  test('+1 minuto e pausa alteram o estado do temporizador', () {
    vm.addMinute();
    expect(vm.remainingSeconds, 480);
    expect(vm.plannedSeconds, 480);
    vm.togglePause();
    expect(vm.paused, isTrue);
  });

  test('concluir avança e, no último passo, encerra a sessão', () async {
    await vm.complete.execute();
    expect(vm.index, 2);
    expect(vm.finished, isFalse);

    await vm.complete.execute();
    expect(vm.finished, isTrue);
    expect(vm.lastOutcome!.ritualCompleted, isTrue);
    expect(vm.lastOutcome!.sharedWithTribe, isTrue);
  });

  test('pular avança sem marcar o passo como concluído', () async {
    await vm.skip.execute();
    expect(vm.index, 2);
    expect(vm.completedIds.contains('m2'), isFalse);
  });
}
