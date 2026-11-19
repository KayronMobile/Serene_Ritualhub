import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/ui/auth/view_models/login_viewmodel.dart';
import 'package:ritualhub/ui/auth/widgets/login_screen.dart';

import '../../testing/fakes/fake_environment.dart';

void main() {
  testWidgets('Login valida a senha e autentica o usuário', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final env = await FakeEnvironment.create();
    final vm = LoginViewModel(authRepository: env.auth);
    await tester.pumpWidget(MaterialApp(home: LoginScreen(viewModel: vm)));
    await tester.pumpAndSettle();

    expect(find.text('Que bom te ver de volta'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'lucas@serene.com');
    await tester.enterText(fields.at(1), '123');
    await tester.tap(find.text('Entrar no Serene'));
    await tester.pump();
    expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);

    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.text('Entrar no Serene'));
    await tester.pumpAndSettle();

    expect(await env.auth.isAuthenticated, isTrue);
    expect(env.auth.currentUser!.name, 'Lucas');
  });
}
