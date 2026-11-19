import 'dart:math';

import '../../../domain/models/health.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../services/local_storage_service.dart';
import '../../services/seed_data.dart';
import 'health_repository.dart';

class HealthRepositoryLocal extends HealthRepository {
  HealthRepositoryLocal({
    required LocalStorageService storage,
    DateTime Function()? clock,
  }) : _storage = storage,
       _clock = clock ?? DateTime.now;

  static const _kGoals = 'health.goals';
  static const _kLogs = 'health.logs';

  final LocalStorageService _storage;
  final DateTime Function() _clock;

  HealthGoals? _goals;
  Map<String, DailyHealthLog>? _logs;

  Future<Result<void>>? _loading;

  /// Carrega uma única vez, mesmo com chamadas concorrentes.
  Future<Result<void>> _ensureLoaded() async {
    final r = await (_loading ??= _load());
    if (r is Error<void>) _loading = null; // permite nova tentativa
    return r;
  }

  Future<Result<void>> _load() async {
    if (_goals != null && _logs != null) return const Result.ok(null);

    final goalsRaw = await _storage.readJson(_kGoals);
    final logsRaw = await _storage.readJson(_kLogs);
    if (goalsRaw is Error<Object?>) return Result.error(goalsRaw.error);
    if (logsRaw is Error<Object?>) return Result.error(logsRaw.error);

    final gv = (goalsRaw as Ok<Object?>).value;
    final lv = (logsRaw as Ok<Object?>).value;

    _goals = gv == null
        ? const HealthGoals()
        : HealthGoals.fromJson(gv as Map<String, Object?>);

    if (lv == null) {
      _logs = {
        for (final l in SeedData.healthLogs(_clock(), _goals!))
          Dates.key(l.date): l,
      };
      await _persist();
      await _storage.writeJson(_kGoals, _goals!.toJson());
    } else {
      _logs = {
        for (final e in lv as List<Object?>)
          if (e case final Map<String, Object?> m)
            Dates.key(DateTime.parse(m['date']! as String)):
                DailyHealthLog.fromJson(m),
      };
    }
    return const Result.ok(null);
  }

  Future<Result<void>> _persist() =>
      _storage.writeJson(_kLogs, _logs!.values.map((l) => l.toJson()).toList());

  DailyHealthLog _logFor(DateTime date) {
    final d = Dates.dateOnly(date);
    return _logs![Dates.key(d)] ?? DailyHealthLog.empty(d);
  }

  Future<Result<DailyHealthLog>> _update(
    DateTime date,
    DailyHealthLog Function(DailyHealthLog current) change,
  ) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final updated = change(_logFor(date)).copyWith(updatedAt: _clock());
    _logs![Dates.key(updated.date)] = updated;
    final saved = await _persist();
    if (saved is Error<void>) return Result.error(saved.error);
    notifyListeners();
    return Result.ok(updated);
  }

  @override
  Future<Result<HealthGoals>> getGoals() async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    return Result.ok(_goals!);
  }

  @override
  Future<Result<HealthGoals>> updateGoals(HealthGoals goals) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    _goals = goals;
    final saved = await _storage.writeJson(_kGoals, goals.toJson());
    if (saved is Error<void>) return Result.error(saved.error);
    notifyListeners();
    return Result.ok(goals);
  }

  @override
  Future<Result<DailyHealthLog>> getLog(DateTime date) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    return Result.ok(_logFor(date));
  }

  @override
  Future<Result<List<DailyHealthLog>>> getLogs(
    DateTime from,
    DateTime to,
  ) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final out = <DailyHealthLog>[];
    var day = Dates.dateOnly(from);
    final end = Dates.dateOnly(to);
    while (!day.isAfter(end)) {
      out.add(_logFor(day));
      day = Dates.addDays(day, 1);
    }
    return Result.ok(out);
  }

  @override
  Future<Result<DailyHealthLog>> addWater(DateTime date, int ml) =>
      _update(date, (l) => l.copyWith(waterMl: max(0, l.waterMl + ml)));

  @override
  Future<Result<DailyHealthLog>> setSleep(
    DateTime date,
    int minutes, {
    int? qualityPercent,
  }) => _update(
    date,
    (l) => l.copyWith(
      sleepMinutes: max(0, minutes),
      deepSleepPercent: qualityPercent,
    ),
  );

  @override
  Future<Result<DailyHealthLog>> addActivity(DateTime date, int minutes) =>
      _update(
        date,
        (l) => l.copyWith(activityMinutes: max(0, l.activityMinutes + minutes)),
      );

  @override
  Future<Result<DailyHealthLog>> addReading(DateTime date, int minutes) =>
      _update(
        date,
        (l) => l.copyWith(readingMinutes: max(0, l.readingMinutes + minutes)),
      );
}
