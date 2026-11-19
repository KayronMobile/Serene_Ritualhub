import 'package:flutter/foundation.dart';

import '../../../domain/models/ritual.dart';
import '../../../utils/result.dart';

/// Fonte da verdade para rituais e seus registros de execução.
///
/// Notifica ouvintes quando algo muda, para que telas mantidas vivas
/// pelo `StatefulShellRoute` (Hoje, Progresso) se atualizem.
abstract class RitualRepository extends ChangeNotifier {
  Future<Result<List<Ritual>>> getRituals();

  Future<Result<Ritual>> getRitual(String id);

  /// Cria ou atualiza um ritual.
  Future<Result<Ritual>> saveRitual(Ritual ritual);

  Future<Result<void>> deleteRitual(String id);

  /// Registros entre [from] e [to] (inclusive, por data).
  Future<Result<List<RitualLog>>> getLogs(DateTime from, DateTime to);

  /// Registro de um ritual em uma data (ou `null`).
  Future<Result<RitualLog?>> getLog(String ritualId, DateTime date);

  Future<Result<RitualLog>> saveLog(RitualLog log);
}
