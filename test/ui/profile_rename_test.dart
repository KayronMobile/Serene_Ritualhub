import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/ui/profile/view_models/profile_viewmodel.dart';
import 'package:ritualhub/ui/profile/widgets/profile_screen.dart';

import '../../testing/fakes/fake_environment.dart';

void main() {
  testWidgets('editar o nome salva sem erros', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final env = await FakeEnvironment.create();
    await env.signIn();
    final vm = ProfileViewModel(
      authRepository: env.auth,
      healthRepository: env.health,
    );
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(viewModel: vm)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lucas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'A');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Mínimo de 2 letras'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Lucas Lima');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(env.auth.currentUser!.name, 'Lucas Lima');
    expect(find.text('Lucas Lima'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
