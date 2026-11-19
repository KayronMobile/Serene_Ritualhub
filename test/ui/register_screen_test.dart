import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/ui/auth/view_models/register_viewmodel.dart';
import 'package:ritualhub/ui/auth/widgets/register_screen.dart';
import 'package:ritualhub/utils/result.dart';

import '../../testing/fakes/fake_environment.dart';

void main() {
  test('força da senha', () {
    expect(RegisterViewModel.evaluateStrength(''), PasswordStrength.empty);
    expect(RegisterViewModel.evaluateStrength('abc'), PasswordStrength.weak);
    expect(RegisterViewModel.evaluateStrength('abcdef'), PasswordStrength.weak);
    expect(
      RegisterViewModel.evaluateStrength('abcdef1'),
      PasswordStrength.medium,
    );
    expect(
      RegisterViewModel.evaluateStrength('Abcdef1!xyz'),
      PasswordStrength.strong,
    );
  });

  test('exige aceite dos termos e bloqueia e-mail duplicado', () async {
    final env = await FakeEnvironment.create();
    final vm = RegisterViewModel(authRepository: env.auth);
    const data = (name: 'Ana', email: 'ana@serene.com', password: '123456');

    await vm.register.execute(data);
    expect(vm.register.result, isA<Error<void>>());

    vm.setAcceptedTerms(true);
    await vm.register.execute(data);
    expect(vm.register.result, isA<Ok<void>>());
    expect(env.auth.currentUser!.email, 'ana@serene.com');

    await env.auth.logout();
    await vm.register.execute(data);
    expect(vm.register.result, isA<Error<void>>());
  });

  testWidgets('cadastro valida campos e cria a conta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final env = await FakeEnvironment.create();
    final vm = RegisterViewModel(authRepository: env.auth);
    await tester.pumpWidget(MaterialApp(home: RegisterScreen(viewModel: vm)));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana Souza');
    await tester.enterText(fields.at(1), 'ana@serene');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '654321');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Criar conta e entrar'));
    await tester.pump();
    expect(find.text('E-mail inválido'), findsOneWidget);
    expect(find.text('As senhas não coincidem'), findsOneWidget);

    await tester.enterText(fields.at(1), 'ana@serene.com');
    await tester.enterText(fields.at(3), '123456');
    await tester.tap(find.text('Criar conta e entrar'));
    await tester.pumpAndSettle();

    expect(await env.auth.isAuthenticated, isTrue);
    expect(env.auth.currentUser!.name, 'Ana Souza');
  });
}
