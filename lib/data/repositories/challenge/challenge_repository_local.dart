import '../../../domain/models/challenge.dart';
import '../../../domain/models/user_profile.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../services/local_storage_service.dart';
import '../../services/seed_data.dart';
import 'challenge_repository.dart';

/// Implementação local do [ChallengeRepository].
///
/// Sem backend, a atividade dos amigos é *simulada* de forma determinística
/// (mesmo resultado a cada abertura) para que placar e feed tenham vida.
/// Em produção, troque por um `ChallengeRepositoryRemote` que consome a API
/// (ex.: Firestore com listeners em tempo real).
class ChallengeRepositoryLocal extends ChallengeRepository {
  ChallengeRepositoryLocal({
    required LocalStorageService storage,
    DateTime Function()? clock,
  }) : _storage = storage,
       _clock = clock ?? DateTime.now;

  static const _kChallenges = 'challenges.items';
  static const _kCheckIns = 'challenges.checkins';
  static const _kEncouragements = 'challenges.encouragements';

  final LocalStorageService _storage;
  final DateTime Function() _clock;

  List<Challenge>? _challenges;
  List<CheckIn>? _checkIns;
  List<Encouragement>? _encouragements;

  Future<Result<void>>? _loading;

  Future<Result<void>> _ensureLoaded() async {
    final r = await (_loading ??= _load());
    if (r is Error<void>) {
      _loading = null;
      return r;
    }
    // Sempre "sincroniza" a atividade simulada da tribo (novos dias).
    if (_simulateTribe(_clock())) await _persistAll();
    return r;
  }

  Future<Result<void>> _load() async {
    var seeded = false;
    if (_challenges == null) {
      final cr = await _storage.readJson(_kChallenges);
      final kr = await _storage.readJson(_kCheckIns);
      final er = await _storage.readJson(_kEncouragements);
      if (cr is Error<Object?>) return Result.error(cr.error);
      if (kr is Error<Object?>) return Result.error(kr.error);
      if (er is Error<Object?>) return Result.error(er.error);

      final cv = (cr as Ok<Object?>).value;
      if (cv == null) {
        seeded = true;
        final now = _clock();
        _challenges = SeedData.challenges(now);
        _checkIns = SeedData.checkIns(_challenges!, now);
        _encouragements = [];
      } else {
        _challenges = (cv as List<Object?>)
            .map((e) => Challenge.fromJson(e! as Map<String, Object?>))
            .toList();
        _checkIns = (((kr as Ok<Object?>).value as List<Object?>?) ?? const [])
            .map((e) => CheckIn.fromJson(e! as Map<String, Object?>))
            .toList();
        _encouragements =
            (((er as Ok<Object?>).value as List<Object?>?) ?? const [])
                .map((e) => Encouragement.fromJson(e! as Map<String, Object?>))
                .toList();
      }
    }
    if (seeded) await _persistAll();
    return const Result.ok(null);
  }

  Future<void> _persistAll() async {
    await _storage.writeJson(
      _kChallenges,
      _challenges!.map((c) => c.toJson()).toList(),
    );
    await _persistCheckIns();
    await _storage.writeJson(
      _kEncouragements,
      _encouragements!.map((e) => e.toJson()).toList(),
    );
  }

  Future<Result<void>> _persistCheckIns() => _storage.writeJson(
    _kCheckIns,
    _checkIns!.map((c) => c.toJson()).toList(),
  );

  /// Gera check-ins dos amigos para os dias ainda não simulados.
  /// Retorna `true` se algo foi criado.
  bool _simulateTribe(DateTime now) {
    final today = Dates.dateOnly(now);
    final existing = <String>{
      for (final c in _checkIns!)
        '${c.challengeId}|${c.author.id}|${Dates.key(c.createdAt)}',
    };
    var created = false;

    for (final ch in _challenges!) {
      final last = ch.isFinished(now) ? ch.endDate : today;
      var day = Dates.dateOnly(ch.startDate);
      var index = 0;
      while (!day.isAfter(last)) {
        for (final m in ch.members) {
          if (m.id == SeedData.me.id) continue;
          final reliability = SeedData.reliability[m.id] ?? 0.85;
          final key = '${ch.id}|${m.id}|${Dates.key(day)}';
          if (existing.contains(key)) continue;
          if (SeedData.unitRandom(key) > reliability) continue;

          // Horário em que o amigo costuma registrar (7h–21h);
          // Beatriz é sempre a última, para ilustrar o "cuidado
          // compartilhado".
          final hour = m.id == SeedData.beatriz.id
              ? 23
              : 7 + SeedData.stableHash('$key#h') % 14;
          final at = day.add(
            Duration(hours: hour, minutes: SeedData.stableHash(key) % 60),
          );
          if (at.isAfter(now)) continue;

          _checkIns!.add(
            CheckIn(
              id: 'sim_$key',
              challengeId: ch.id,
              author: m,
              createdAt: at,
              caption: SeedData.captionFor(
                ch.category,
                SeedData.stableHash(key) + index,
              ),
              context: 'Check-in diário',
            ),
          );
          existing.add(key);
          created = true;
        }
        day = Dates.addDays(day, 1);
        index++;
      }
    }
    return created;
  }

  @override
  Future<Result<List<Challenge>>> getChallenges() async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final now = _clock();
    final sorted = [..._challenges!]
      ..sort((a, b) {
        final aa = a.isActive(now) ? 0 : 1;
        final bb = b.isActive(now) ? 0 : 1;
        if (aa != bb) return aa.compareTo(bb);
        return b.startDate.compareTo(a.startDate);
      });
    return Result.ok(sorted);
  }

  @override
  Future<Result<Challenge>> getChallenge(String id) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    for (final c in _challenges!) {
      if (c.id == id) return Result.ok(c);
    }
    return const Result.error(AppException('Desafio não encontrado.'));
  }

  @override
  Future<Result<Challenge>> createChallenge({
    required String title,
    required String description,
    required ChallengeCategory category,
    required int durationDays,
    required String dailyGoal,
    required DateTime startDate,
    required UserProfile creator,
    required List<UserProfile> invited,
  }) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    if (title.trim().isEmpty) {
      return const Result.error(AppException('Dê um nome ao desafio.'));
    }
    if (durationDays < 3) {
      return const Result.error(
        AppException('Um desafio precisa de ao menos 3 dias.'),
      );
    }
    final challenge = Challenge(
      id: Ids.generate('ch'),
      title: title.trim(),
      description: description.trim(),
      category: category,
      startDate: Dates.dateOnly(startDate),
      durationDays: durationDays,
      members: [SeedData.me, ...invited.where((u) => u.id != creator.id)],
      createdBy: creator.id,
      dailyGoal: dailyGoal.trim(),
    );
    _challenges!.add(challenge);
    await _persistAll();
    notifyListeners();
    return Result.ok(challenge);
  }

  @override
  Future<Result<List<UserProfile>>> getFriends() async =>
      const Result.ok(SeedData.friends);

  @override
  Future<Result<List<ChallengeTemplate>>> getTemplates() async =>
      const Result.ok(SeedData.templates);

  @override
  Future<Result<List<CheckIn>>> getCheckIns(String challengeId) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final list = _checkIns!.where((c) => c.challengeId == challengeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Result.ok(list);
  }

  @override
  Future<Result<CheckIn>> addCheckIn(CheckIn checkIn) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final already = _checkIns!.any(
      (c) =>
          c.challengeId == checkIn.challengeId &&
          c.author.id == checkIn.author.id &&
          Dates.isSameDay(c.createdAt, checkIn.createdAt),
    );
    if (already) {
      return const Result.error(
        AppException('Você já fez o check-in de hoje neste desafio. 🌿'),
      );
    }
    _checkIns!.add(checkIn);
    final saved = await _persistCheckIns();
    if (saved is Error<void>) return Result.error(saved.error);
    notifyListeners();
    return Result.ok(checkIn);
  }

  Future<Result<CheckIn>> _updateCheckIn(
    String id,
    CheckIn Function(CheckIn) change,
  ) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    final i = _checkIns!.indexWhere((c) => c.id == id);
    if (i < 0) {
      return const Result.error(AppException('Check-in não encontrado.'));
    }
    final updated = change(_checkIns![i]);
    _checkIns![i] = updated;
    final saved = await _persistCheckIns();
    if (saved is Error<void>) return Result.error(saved.error);
    notifyListeners();
    return Result.ok(updated);
  }

  @override
  Future<Result<CheckIn>> toggleReaction(String checkInId, Reaction reaction) =>
      _updateCheckIn(checkInId, (c) {
        final mine = {...c.myReactions};
        final counts = {...c.reactions};
        if (mine.remove(reaction)) {
          counts[reaction] = ((counts[reaction] ?? 1) - 1).clamp(0, 1 << 30);
        } else {
          mine.add(reaction);
          counts[reaction] = (counts[reaction] ?? 0) + 1;
        }
        return c.copyWith(reactions: counts, myReactions: mine);
      });

  @override
  Future<Result<CheckIn>> addComment(String checkInId, CheckInComment comment) {
    if (comment.text.trim().isEmpty) {
      return Future.value(
        const Result.error(AppException('Escreva uma palavra de força.')),
      );
    }
    return _updateCheckIn(
      checkInId,
      (c) => c.copyWith(comments: [...c.comments, comment]),
    );
  }

  @override
  Future<Result<List<Encouragement>>> getEncouragements(
    String challengeId,
  ) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    return Result.ok(
      _encouragements!.where((e) => e.challengeId == challengeId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<Result<Encouragement>> sendEncouragement(
    Encouragement encouragement,
  ) async {
    final r = await _ensureLoaded();
    if (r is Error<void>) return Result.error(r.error);
    _encouragements!.add(encouragement);
    await _storage.writeJson(
      _kEncouragements,
      _encouragements!.map((e) => e.toJson()).toList(),
    );
    notifyListeners();
    return Result.ok(encouragement);
  }
}
