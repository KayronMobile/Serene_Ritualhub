import 'package:flutter/foundation.dart';

import '../../../domain/models/achievement.dart';
import '../../../utils/result.dart';

/// Guarda quais medalhas foram desbloqueadas e quando.
abstract class AchievementRepository extends ChangeNotifier {
  Future<Result<List<AchievementUnlock>>> getUnlocks();

  Future<Result<void>> saveUnlocks(List<AchievementUnlock> unlocks);

  Future<Result<void>> markAllSeen();
}
