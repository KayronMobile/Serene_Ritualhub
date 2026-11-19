import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/challenge/challenge_repository.dart';
import '../../../data/services/image_picker_service.dart';
import '../../../domain/models/challenge.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/consistency_calculator.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Dados do formulário de novo check-in.
typedef CheckInDraft = ({String caption, String? photoPath, String? tag});

/// Dados do formulário de novo desafio.
typedef ChallengeDraft = ({
  String title,
  String description,
  ChallengeCategory category,
  int durationDays,
  String dailyGoal,
  List<UserProfile> invited,
});

enum CommunityTab { active, groups, discover }

class CommunityViewModel extends ViewModel {
  CommunityViewModel({
    required AuthRepository authRepository,
    required ChallengeRepository challengeRepository,
    required PhotoService photoService,
    DateTime Function()? clock,
  }) : _auth = authRepository,
       _repo = challengeRepository,
       _photos = photoService,
       _clock = clock ?? DateTime.now {
    load = Command0(_load)..execute();
    toggleReaction = Command1<void, ({String checkInId, Reaction reaction})>(
      _toggleReaction,
    );
    addComment = Command1<void, ({String checkInId, String text})>(_addComment);
    sendEncouragement = Command1<void, UserProfile>(_sendEncouragement);
    createCheckIn = Command1<void, CheckInDraft>(_createCheckIn);
    pickPhoto = Command1<String?, bool>(_pickPhoto);
    createChallenge = Command1<Challenge, ChallengeDraft>(_createChallenge);
    _repo.addListener(_onChanged);
  }

  final AuthRepository _auth;
  final ChallengeRepository _repo;
  final PhotoService _photos;
  final DateTime Function() _clock;

  late final Command0<void> load;
  late final Command1<void, ({String checkInId, Reaction reaction})>
  toggleReaction;
  late final Command1<void, ({String checkInId, String text})> addComment;
  late final Command1<void, UserProfile> sendEncouragement;
  late final Command1<void, CheckInDraft> createCheckIn;
  late final Command1<String?, bool> pickPhoto;
  late final Command1<Challenge, ChallengeDraft> createChallenge;

  DateTime get now => _clock();

  UserProfile? get user => _auth.currentUser;

  CommunityTab _tab = CommunityTab.active;
  CommunityTab get tab => _tab;

  List<Challenge> _challenges = const [];
  List<Challenge> get challenges => _challenges;
  List<Challenge> get activeChallenges =>
      _challenges.where((c) => c.isActive(now)).toList();

  String? _selectedId;
  Challenge? get selected =>
      _challenges.where((c) => c.id == _selectedId).firstOrNull;

  List<CheckIn> _feed = const [];

  /// Feed de check-ins do desafio selecionado (apenas os com legenda/foto
  /// mais recentes — os 30 últimos).
  List<CheckIn> get feed => _feed;

  List<LeaderboardEntry> _leaderboard = const [];
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  double get groupRate => ConsistencyCalculator.groupRate(_leaderboard);

  List<Encouragement> _wall = const [];

  /// Mural de incentivo do desafio selecionado.
  List<Encouragement> get wall => _wall;

  /// Membro que ainda não registrou hoje (para o card "Cuidado
  /// compartilhado"), excluindo quem já recebeu um carinho hoje.
  LeaderboardEntry? get careTarget {
    final sentToday = {
      for (final e in _wall)
        if (Dates.isSameDay(e.createdAt, now) && e.from.id == user?.id) e.to.id,
    };
    return _leaderboard
        .where(
          (e) =>
              !e.checkedInToday &&
              e.member.id != user?.id &&
              !sentToday.contains(e.member.id),
        )
        .firstOrNull;
  }

  bool get checkedInToday =>
      _leaderboard.any((e) => e.member.id == user?.id && e.checkedInToday);

  /// Placar de cada desafio (aba "Meus Grupos").
  final Map<String, double> _myConsistency = {};
  double myConsistencyIn(String challengeId) =>
      _myConsistency[challengeId] ?? 0;

  List<UserProfile> _friends = const [];
  List<UserProfile> get friends => _friends;

  List<ChallengeTemplate> _templates = const [];
  List<ChallengeTemplate> get templates => _templates;

  void setTab(CommunityTab tab) {
    _tab = tab;
    notifyListeners();
  }

  Future<void> select(String challengeId) async {
    _selectedId = challengeId;
    _tab = CommunityTab.active;
    await _loadSelected();
    notifyListeners();
  }

  /// Substitui o placeholder "me" pelos dados reais do usuário.
  UserProfile _resolve(UserProfile p) => p.id == user?.id ? (user ?? p) : p;

  void _onChanged() => scheduleReload(() async {
    await _load();
  });

  Future<Result<void>> _load() async {
    final r = await _repo.getChallenges();
    if (r is Error<List<Challenge>>) return Result.error(r.error);
    _challenges = [
      for (final c in (r as Ok<List<Challenge>>).value)
        c.copyWith(members: c.members.map(_resolve).toList()),
    ];

    if (_selectedId == null || !_challenges.any((c) => c.id == _selectedId)) {
      _selectedId =
          activeChallenges.firstOrNull?.id ?? _challenges.firstOrNull?.id;
    }

    final fr = await _repo.getFriends();
    if (fr is Ok<List<UserProfile>>) _friends = fr.value;
    final tr = await _repo.getTemplates();
    if (tr is Ok<List<ChallengeTemplate>>) _templates = tr.value;

    // Consistência pessoal em cada desafio.
    for (final c in _challenges) {
      final cr = await _repo.getCheckIns(c.id);
      if (cr is Ok<List<CheckIn>>) {
        final board = ConsistencyCalculator.leaderboard(
          challenge: c,
          checkIns: cr.value,
          now: now,
        );
        final mine = board.where((e) => e.member.id == user?.id).firstOrNull;
        _myConsistency[c.id] = mine?.consistency ?? 0;
      }
    }

    await _loadSelected();
    notifyListeners();
    return const Result.ok(null);
  }

  Future<void> _loadSelected() async {
    final c = selected;
    if (c == null) {
      _feed = const [];
      _leaderboard = const [];
      _wall = const [];
      return;
    }
    final cr = await _repo.getCheckIns(c.id);
    final all = cr is Ok<List<CheckIn>> ? cr.value : <CheckIn>[];
    _leaderboard = ConsistencyCalculator.leaderboard(
      challenge: c,
      checkIns: all,
      now: now,
    );
    _feed = [
      for (final ci in all.take(30))
        CheckIn(
          id: ci.id,
          challengeId: ci.challengeId,
          author: _resolve(ci.author),
          createdAt: ci.createdAt,
          caption: ci.caption,
          photoPath: ci.photoPath,
          tag: ci.tag,
          context: ci.context,
          reactions: ci.reactions,
          myReactions: ci.myReactions,
          comments: ci.comments,
        ),
    ];
    final wr = await _repo.getEncouragements(c.id);
    _wall = wr is Ok<List<Encouragement>> ? wr.value : const [];
  }

  Future<Result<void>> _toggleReaction(
    ({String checkInId, Reaction reaction}) input,
  ) async {
    final r = await _repo.toggleReaction(input.checkInId, input.reaction);
    return r is Error<CheckIn> ? Result.error(r.error) : const Result.ok(null);
  }

  Future<Result<void>> _addComment(
    ({String checkInId, String text}) input,
  ) async {
    final me = user;
    if (me == null) return const Result.error(AppException('Faça login.'));
    final r = await _repo.addComment(
      input.checkInId,
      CheckInComment(
        id: Ids.generate('cm'),
        author: me,
        text: input.text.trim(),
        createdAt: now,
      ),
    );
    return r is Error<CheckIn> ? Result.error(r.error) : const Result.ok(null);
  }

  Future<Result<void>> _sendEncouragement(UserProfile to) async {
    final me = user;
    final c = selected;
    if (me == null || c == null) {
      return const Result.error(AppException('Selecione um desafio.'));
    }
    final r = await _repo.sendEncouragement(
      Encouragement(
        id: Ids.generate('enc'),
        challengeId: c.id,
        from: me,
        to: to,
        message:
            '${me.firstName} enviou uma lembrança afetuosa: “Estamos juntos, '
            '${to.firstName}! Seu check-in de hoje faz falta 💛”',
        createdAt: now,
      ),
    );
    return r is Error<Encouragement>
        ? Result.error(r.error)
        : const Result.ok(null);
  }

  Future<Result<String?>> _pickPhoto(bool fromCamera) =>
      _photos.pick(fromCamera: fromCamera);

  Future<Result<void>> _createCheckIn(CheckInDraft draft) async {
    final me = user;
    final c = selected;
    if (me == null || c == null) {
      return const Result.error(AppException('Selecione um desafio.'));
    }
    if (!c.isActive(now)) {
      return const Result.error(
        AppException('Este desafio não está em andamento.'),
      );
    }
    if (draft.caption.trim().isEmpty && draft.photoPath == null) {
      return const Result.error(
        AppException('Adicione uma foto ou conte como foi seu dia.'),
      );
    }
    final r = await _repo.addCheckIn(
      CheckIn(
        id: Ids.generate('ci'),
        challengeId: c.id,
        author: me,
        createdAt: now,
        caption: draft.caption.trim(),
        photoPath: draft.photoPath,
        tag: (draft.tag?.trim().isEmpty ?? true) ? null : draft.tag!.trim(),
        context: 'Dia ${c.currentDay(now)}/${c.durationDays}',
      ),
    );
    return r is Error<CheckIn> ? Result.error(r.error) : const Result.ok(null);
  }

  Future<Result<Challenge>> _createChallenge(ChallengeDraft d) async {
    final me = user;
    if (me == null) return const Result.error(AppException('Faça login.'));
    final r = await _repo.createChallenge(
      title: d.title,
      description: d.description,
      category: d.category,
      durationDays: d.durationDays,
      dailyGoal: d.dailyGoal,
      startDate: now,
      creator: me,
      invited: d.invited,
    );
    if (r is Ok<Challenge>) {
      _selectedId = r.value.id;
      _tab = CommunityTab.active;
    }
    return r;
  }

  @override
  void dispose() {
    _repo.removeListener(_onChanged);
    super.dispose();
  }
}
