import '../../../domain/models/achievement.dart';
import '../../../utils/result.dart';
import '../../services/local_storage_service.dart';
import 'achievement_repository.dart';

class AchievementRepositoryLocal extends AchievementRepository {
  AchievementRepositoryLocal({required LocalStorageService storage})
    : _storage = storage;

  static const _kUnlocks = 'achievements.unlocks';

  final LocalStorageService _storage;
  List<AchievementUnlock>? _unlocks;

  Future<Result<List<AchievementUnlock>>> _load() async {
    if (_unlocks != null) return Result.ok(_unlocks!);
    final r = await _storage.readJson(_kUnlocks);
    switch (r) {
      case Ok<Object?>():
        _unlocks = ((r.value as List<Object?>?) ?? const [])
            .map((e) => AchievementUnlock.fromJson(e! as Map<String, Object?>))
            .toList();
        return Result.ok(_unlocks!);
      case Error<Object?>():
        return Result.error(r.error);
    }
  }

  @override
  Future<Result<List<AchievementUnlock>>> getUnlocks() async {
    final r = await _load();
    if (r is Ok<List<AchievementUnlock>>) return Result.ok([...r.value]);
    return r;
  }

  @override
  Future<Result<void>> saveUnlocks(List<AchievementUnlock> unlocks) async {
    _unlocks = [...unlocks];
    final r = await _storage.writeJson(
      _kUnlocks,
      unlocks.map((u) => u.toJson()).toList(),
    );
    notifyListeners();
    return r;
  }

  @override
  Future<Result<void>> markAllSeen() async {
    final r = await _load();
    if (r is Error<List<AchievementUnlock>>) return Result.error(r.error);
    if (_unlocks!.every((u) => u.seen)) return const Result.ok(null);
    return saveUnlocks(_unlocks!.map((u) => u.markSeen()).toList());
  }
}
