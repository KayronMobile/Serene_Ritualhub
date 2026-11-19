import 'package:flutter/foundation.dart';

import '../../../domain/models/health.dart';
import '../../../utils/result.dart';

/// Fonte da verdade dos rastreadores de saúde (água, sono, atividade,
/// leitura) e das metas diárias.
abstract class HealthRepository extends ChangeNotifier {
  Future<Result<HealthGoals>> getGoals();

  Future<Result<HealthGoals>> updateGoals(HealthGoals goals);

  Future<Result<DailyHealthLog>> getLog(DateTime date);

  Future<Result<List<DailyHealthLog>>> getLogs(DateTime from, DateTime to);

  /// Soma (ou subtrai, se negativo) água em ml.
  Future<Result<DailyHealthLog>> addWater(DateTime date, int ml);

  Future<Result<DailyHealthLog>> setSleep(
    DateTime date,
    int minutes, {
    int? qualityPercent,
  });

  Future<Result<DailyHealthLog>> addActivity(DateTime date, int minutes);

  Future<Result<DailyHealthLog>> addReading(DateTime date, int minutes);
}
