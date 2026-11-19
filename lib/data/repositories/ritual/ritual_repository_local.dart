import '../../../domain/models/ritual.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../services/local_storage_service.dart';
import '../../services/seed_data.dart';
import 'ritual_repository.dart';

/// Implementação local do [RitualRepository] com cache em memória.
class RitualRepositoryLocal extends RitualRepository {
  RitualRepositoryLocal({
    required LocalStorageService storage,
    DateTime Function()? clock,
  }) : _storage = storage,
       _clock = clock ?? DateTime.now;

  static const _kRituals = 'rituals.items';
  static const _kLogs = 'rituals.logs';

  final LocalStorageService _storage;
  final DateTime Function() _clock;

  List<Ritual>? _rituals;

  /// Chave: "ritualId|yyyy-MM-dd".
  Map<String, RitualLog>? _logs;

  String _logKey(String ritualId, DateTime date) =>
      '$ritualId|${Dates.key(date)}';

  Future<Result<void>>? _loading;

  /// Carrega uma única vez, mesmo com chamadas concorrentes.
  Future<Result<void>> _ensureLoaded() async {
    final r = await (_loading ??= _load());
    if (r is Error<void>) _loading = null; // permite nova tentativa
    return r;
  }

  Future<Result<void>> _load() async {
    if (_rituals != null && _logs != null) return const Result.ok(null);

    final ritualsRaw = await _storage.readJson(_kRituals);
    final logsRaw = await _storage.readJson(_kLogs);
    if (ritualsRaw is Error<Object?>) return Result.error(ritualsRaw.error);
    if (logsRaw is Error<Object?>) return Result.error(logsRaw.error);

    final rv = (ritualsRaw as Ok<Object?>).value;
    final lv = (logsRaw as Ok<Object?>).value;

    if (rv == null) {
      // Primeiro uso: dados de demonstração para a experiência completa.
      final seed = SeedData.rituals();
      _rituals = [...seed];
      _logs = {
        for (final l in SeedData.ritualLogs(seed, _clock()))
          _logKey(l.ritualId, l.date): l,
      };
      await _persistRituals();
      await _persistLogs();
    } else {
      _rituals = (rv as List<Object?>)
          .map((e) => Ritual.fromJson(e! as Map<String, Object?>))
          .toList();
      _logs = {
        for (final e in ((lv as List<Object?>?) ?? const []))
          if (e case final Map<String, Object?> m)
            _logKey(m['ritualId']! as String, DateTime.parse(m['date']! as String)):
                RitualLog.fromJson(m),
      };
    }
    return const Result.ok(null);
  }

  Future<Result<void>> _persistRituals() =>
      _storage.writeJson(_kRituals, _rituals!.map((r) => r.toJson()).toList());

  Future<Result<void>> _persistLogs() =>
      _storage.writeJson(_kLogs, _logs!.values.map((l) => l.toJson()).toList());

  @override
  Future<Result<List<Ritual>>> getRituals() async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final sorted = [..._rituals!]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return Result.ok(sorted);
  }

  @override
  Future<Result<Ritual>> getRitual(String id) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    for (final ritual in _rituals!) {
      if (ritual.id == id) return Result.ok(ritual);
    }
    return const Result.error(AppException('Ritual não encontrado.'));
  }

  @override
  Future<Result<Ritual>> saveRitual(Ritual ritual) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    if (ritual.name.trim().isEmpty) {
      return const Result.error(AppException('Dê um nome ao seu ritual.'));
    }
    if (ritual.steps.isEmpty) {
      return const Result.error(
        AppException('Adicione ao menos um bloco de ação.'),
      );
    }
    final index = _rituals!.indexWhere((x) => x.id == ritual.id);
    if (index >= 0) {
      _rituals![index] = ritual;
    } else {
      _rituals!.add(ritual);
    }
    final saved = await _persistRituals();
    if (saved is Error<void>) return Result.error(saved.error);
    notifyListeners();
    return Result.ok(ritual);
  }

  @override
  Future<Result<void>> deleteRitual(String id) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return r;
    _rituals!.removeWhere((x) => x.id == id);
    _logs!.removeWhere((key, _) => key.startsWith('$id|'));
    await _persistLogs();
    final saved = await _persistRituals();
    notifyListeners();
    return saved;
  }

  @override
  Future<Result<List<RitualLog>>> getLogs(DateTime from, DateTime to) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final start = Dates.dateOnly(from);
    final end = Dates.dateOnly(to);
    return Result.ok(
      _logs!.values
          .where((l) => !l.date.isBefore(start) && !l.date.isAfter(end))
          .toList(),
    );
  }

  @override
  Future<Result<RitualLog?>> getLog(String ritualId, DateTime date) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    return Result.ok(_logs![_logKey(ritualId, Dates.dateOnly(date))]);
  }

  @override
  Future<Result<RitualLog>> saveLog(RitualLog log) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    _logs![_logKey(log.ritualId, log.date)] = log;
    final saved = await _persistLogs();
    if (saved is Error<void>) return Result.error(saved.error);
    notifyListeners();
    return Result.ok(log);
  }
}
