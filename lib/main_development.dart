import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';

/// Ambiente de desenvolvimento: repositórios locais com dados de
/// demonstração (sem backend).
///
/// `flutter run --target lib/main_development.dart`
void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    debugPrint('[${r.level.name}] ${r.loggerName}: ${r.message}'
        '${r.error != null ? ' — ${r.error}' : ''}');
  });

  runApp(MultiProvider(providers: providersLocal, child: const MainApp()));
}
