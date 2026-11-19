import 'package:ritualhub/utils/command.dart';

/// Aguarda um comando (normalmente disparado no construtor do ViewModel)
/// terminar.
Future<void> settle(Command<Object?> command) async {
  for (var i = 0; i < 500 && (command.running || command.result == null); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
