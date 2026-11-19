import 'dart:async';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/ritual/ritual_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/ritual.dart';
import '../../../domain/use_cases/complete_ritual_step_use_case.dart';
import '../../../domain/use_cases/evaluate_achievements_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Player guiado por temporizador que executa os passos em sequência.
class RitualPlayerViewModel extends ViewModel {
  RitualPlayerViewModel({
    required String ritualId,
    required RitualRepository ritualRepository,
    required AuthRepository authRepository,
    required CompleteRitualStepUseCase completeStep,
    required EvaluateAchievementsUseCase evaluateAchievements,
    DateTime Function()? clock,
    Duration tick = const Duration(seconds: 1),
  }) : _ritualId = ritualId,
       _rituals = ritualRepository,
       _auth = authRepository,
       _completeStep = completeStep,
       _evaluate = evaluateAchievements,
       _clock = clock ?? DateTime.now,
       _tick = tick {
    load = Command0(_load)..execute();
    complete = Command0<StepOutcome>(() => _advance(skipped: false));
    skip = Command0<StepOutcome>(() => _advance(skipped: true));
  }

  final String _ritualId;
  final RitualRepository _rituals;
  final AuthRepository _auth;
  final CompleteRitualStepUseCase _completeStep;
  final EvaluateAchievementsUseCase _evaluate;
  final DateTime Function() _clock;
  final Duration _tick;

  late final Command0<void> load;
  late final Command0<StepOutcome> complete;
  late final Command0<StepOutcome> skip;

  Timer? _timer;

  Ritual? _ritual;
  Ritual? get ritual => _ritual;

  int _index = 0;
  int get index => _index;

  RitualStep? get step => _ritual == null || _finished
      ? null
      : _ritual!.steps[_index.clamp(0, _ritual!.steps.length - 1)];

  RitualStep? get nextStep {
    final r = _ritual;
    if (r == null) return null;
    for (var i = _index + 1; i < r.steps.length; i++) {
      if (!_completedIds.contains(r.steps[i].id)) return r.steps[i];
    }
    return null;
  }

  int _planned = 0;
  int get plannedSeconds => _planned;

  int _remaining = 0;
  int get remainingSeconds => _remaining;

  int _elapsedInStep = 0;
  int _sessionSeconds = 0;
  int get sessionSeconds => _sessionSeconds;

  /// 0..1 do anel do temporizador.
  double get ringProgress =>
      _planned == 0 ? 0 : (1 - _remaining / _planned).clamp(0.0, 1.0);

  bool _paused = false;
  bool get paused => _paused;

  bool _soundOn = true;
  bool get soundOn => _soundOn;

  bool _timeUp = false;

  /// O tempo planejado do passo terminou (o usuário decide quando avançar).
  bool get timeUp => _timeUp;

  bool _finished = false;
  bool get finished => _finished;

  Set<String> _completedIds = {};
  Set<String> get completedIds => _completedIds;

  StepOutcome? _lastOutcome;
  StepOutcome? get lastOutcome => _lastOutcome;

  List<Achievement> _unlocked = const [];

  /// Medalhas desbloqueadas ao concluir o ritual.
  List<Achievement> get unlocked => _unlocked;

  bool get focusMode => _ritual?.focusMode ?? false;

  Future<Result<void>> _load() async {
    final r = await _rituals.getRitual(_ritualId);
    if (r is Error<Ritual>) return Result.error(r.error);
    final ritual = (r as Ok<Ritual>).value;
    if (ritual.steps.isEmpty) {
      return const Result.error(AppException('Este ritual não tem passos.'));
    }
    _ritual = ritual;

    final logR = await _rituals.getLog(ritual.id, _clock());
    final log = logR is Ok<RitualLog?> ? logR.value : null;
    _completedIds = {...?log?.completedStepIds};

    final firstPending = ritual.steps.indexWhere(
      (s) => !_completedIds.contains(s.id),
    );
    _goTo(firstPending < 0 ? 0 : firstPending);
    _startTimer();
    return const Result.ok(null);
  }

  void _goTo(int i) {
    _index = i;
    _planned = _ritual!.steps[i].durationSeconds;
    _remaining = _planned;
    _elapsedInStep = 0;
    _timeUp = false;
    _paused = false;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (_paused || _finished || _ritual == null) return;
    _elapsedInStep++;
    _sessionSeconds++;
    if (_remaining > 0) {
      _remaining--;
      if (_remaining == 0) _timeUp = true;
    }
    notifyListeners();
  }

  void togglePause() {
    _paused = !_paused;
    notifyListeners();
  }

  void addMinute() {
    _remaining += 60;
    _planned += 60;
    _timeUp = false;
    notifyListeners();
  }

  void toggleSound() {
    _soundOn = !_soundOn;
    notifyListeners();
  }

  /// Pula diretamente para um passo (pela lista de passos).
  void jumpTo(int i) {
    if (_ritual == null || i < 0 || i >= _ritual!.steps.length) return;
    _goTo(i);
  }

  Future<Result<StepOutcome>> _advance({required bool skipped}) async {
    final ritual = _ritual;
    final current = step;
    final user = _auth.currentUser;
    if (ritual == null || current == null || user == null) {
      return const Result.error(AppException('Sessão indisponível.'));
    }
    final r = await _completeStep.execute(
      ritual: ritual,
      step: current,
      now: _clock(),
      author: user,
      elapsedSeconds: skipped ? 0 : _elapsedInStep,
      skipped: skipped,
    );
    if (r is Error<StepOutcome>) return r;
    final outcome = (r as Ok<StepOutcome>).value;
    _lastOutcome = outcome;
    _completedIds = {...outcome.log.completedStepIds};

    // Próximo passo pendente depois do atual; senão, encerra a sessão.
    var next = -1;
    for (var i = _index + 1; i < ritual.steps.length; i++) {
      if (!_completedIds.contains(ritual.steps[i].id)) {
        next = i;
        break;
      }
    }
    if (next >= 0) {
      _goTo(next);
    } else {
      await _finish();
    }
    return r;
  }

  Future<void> _finish() async {
    _finished = true;
    _timer?.cancel();
    final user = _auth.currentUser;
    if (user != null) {
      final r = await _evaluate.evaluate(userId: user.id, now: _clock());
      if (r is Ok<AchievementEvaluation>) _unlocked = r.value.newlyUnlocked;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
