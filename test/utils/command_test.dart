import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/utils/command.dart';
import 'package:ritualhub/utils/result.dart';

void main() {
  group('Command', () {
    test('Command0 expõe running e resultado Ok', () async {
      final command = Command0<int>(() async => const Result.ok(42));
      final runningStates = <bool>[];
      command.addListener(() => runningStates.add(command.running));

      await command.execute();

      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect((command.result! as Ok<int>).value, 42);
      expect(runningStates, [true, false]);
    });

    test('Command1 propaga erro sem lançar exceção', () async {
      final command = Command1<void, String>(
        (msg) async => Result.error(AppException(msg)),
      );

      await command.execute('falhou');

      expect(command.error, isTrue);
      expect((command.result! as Error<void>).error.toString(), 'falhou');
    });

    test('ignora execuções concorrentes', () async {
      var calls = 0;
      final command = Command0<void>(() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Result.ok(null);
      });

      await Future.wait([command.execute(), command.execute()]);

      expect(calls, 1);
    });

    test('clearResult limpa o estado', () async {
      final command = Command0<int>(() async => const Result.ok(1));
      await command.execute();
      command.clearResult();
      expect(command.result, isNull);
    });
  });
}
