import '../../../data/repositories/challenge/challenge_repository.dart';
import '../../../data/repositories/ritual/ritual_repository.dart';
import '../../../domain/models/challenge.dart';
import '../../../domain/models/ritual.dart';
import '../../../domain/use_cases/plan_reminders_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Estado editável do construtor de rituais sequenciais.
class RitualBuilderViewModel extends ViewModel {
  RitualBuilderViewModel({
    required RitualRepository ritualRepository,
    required ChallengeRepository challengeRepository,
    required PlanRemindersUseCase planReminders,
    String? ritualId,
    DateTime Function()? clock,
  }) : _rituals = ritualRepository,
       _challenges = challengeRepository,
       _planReminders = planReminders,
       _clock = clock ?? DateTime.now,
       _editingId = ritualId {
    load = Command0(_load)..execute();
    save = Command0<Ritual>(_save);
  }

  final RitualRepository _rituals;
  final ChallengeRepository _challenges;
  final PlanRemindersUseCase _planReminders;
  final DateTime Function() _clock;
  final String? _editingId;

  late final Command0<void> load;
  late final Command0<Ritual> save;

  bool get isNew => _editingId == null;

  late String _id = _editingId ?? Ids.generate('ritual');
  String get id => _id;

  String _name = '';
  String get name => _name;

  RitualPeriod _period = RitualPeriod.morning;
  RitualPeriod get period => _period;

  List<RitualStep> _steps = [];
  List<RitualStep> get steps => List.unmodifiable(_steps);

  Set<int> _days = {1, 2, 3, 4, 5};
  Set<int> get activeWeekdays => Set.unmodifiable(_days);

  int _startMinutes = 7 * 60;
  int get startMinutes => _startMinutes;

  bool _reminderEnabled = true;
  bool get reminderEnabled => _reminderEnabled;

  int _reminderLead = 15;
  int get reminderLead => _reminderLead;

  bool _focusMode = false;
  bool get focusMode => _focusMode;

  String? _linkedChallengeId;
  bool _shareWithTribe = false;
  bool get shareWithTribe => _shareWithTribe;

  List<Challenge> _activeChallenges = const [];
  List<Challenge> get activeChallenges => _activeChallenges;

  Challenge? get linkedChallenge =>
      _activeChallenges.where((c) => c.id == _linkedChallengeId).firstOrNull;

  int get totalMinutes =>
      (_steps.fold<int>(0, (s, x) => s + x.durationSeconds) / 60).round();

  /// Sugestões rápidas de blocos.
  static const suggestions = [
    RitualStep(
      id: 'sug_meditation',
      title: 'Meditação Guiada',
      type: StepType.meditation,
      durationSeconds: 300,
      description: 'Atenção plena na respiração',
      instruction:
          'Feche os olhos, observe a respiração sem tentar mudá-la. Quando a '
          'mente vagar, volte gentilmente.',
      ambientSound: 'Pássaros ao Amanhecer',
    ),
    RitualStep(
      id: 'sug_cold',
      title: 'Banho Frio',
      type: StepType.custom,
      durationSeconds: 180,
      description: '30–60s de água fria no final',
      instruction: 'Respire devagar e solte o ar pela boca enquanto a água cai.',
    ),
    RitualStep(
      id: 'sug_gratitude',
      title: 'Diário de Gratidão',
      type: StepType.journaling,
      durationSeconds: 300,
      description: 'Três coisas boas de hoje',
      instruction: 'Escreva três coisas pelas quais você é grato hoje.',
    ),
    RitualStep(
      id: 'sug_walk',
      title: 'Caminhada Consciente',
      type: StepType.movement,
      durationSeconds: 900,
      description: '15 minutos ao ar livre',
      instruction: 'Caminhe sentindo o contato dos pés com o chão.',
    ),
    RitualStep(
      id: 'sug_water',
      title: 'Copo d’Água',
      type: StepType.hydration,
      durationSeconds: 60,
      description: '300ml para despertar',
      instruction: 'Beba devagar, em pequenos goles.',
      waterMl: 300,
    ),
  ];

  static const ambientSounds = [
    'Chuva Suave na Floresta',
    'Ondas do Mar',
    'Lareira ao Longe',
    'Pássaros ao Amanhecer',
    'Ruído Branco',
  ];

  Future<Result<void>> _load() async {
    final cr = await _challenges.getChallenges();
    if (cr is Ok<List<Challenge>>) {
      final now = _clock();
      _activeChallenges = cr.value.where((c) => !c.isFinished(now)).toList();
    }
    if (_editingId != null) {
      final r = await _rituals.getRitual(_editingId);
      switch (r) {
        case Ok<Ritual>():
          final x = r.value;
          _id = x.id;
          _name = x.name;
          _period = x.period;
          _steps = [...x.steps];
          _days = {...x.activeWeekdays};
          _startMinutes = x.startMinutes;
          _reminderEnabled = x.reminderEnabled;
          _reminderLead = x.reminderLeadMinutes;
          _focusMode = x.focusMode;
          _linkedChallengeId = x.linkedChallengeId;
          _shareWithTribe = x.shareWithTribe;
        case Error<Ritual>():
          notifyListeners();
          return Result.error(r.error);
      }
    }
    notifyListeners();
    return const Result.ok(null);
  }

  void setName(String value) {
    _name = value;
    // Sem notifyListeners: o TextField já reflete o valor.
  }

  void setPeriod(RitualPeriod p) {
    _period = p;
    if (isNew && _steps.isEmpty) {
      _startMinutes = switch (p) {
        RitualPeriod.morning => 7 * 60,
        RitualPeriod.afternoon => 15 * 60,
        RitualPeriod.night => 21 * 60 + 30,
      };
    }
    notifyListeners();
  }

  void toggleDay(int weekday) {
    if (_days.contains(weekday)) {
      if (_days.length == 1) return; // ao menos um dia ativo
      _days.remove(weekday);
    } else {
      _days.add(weekday);
    }
    notifyListeners();
  }

  void setStart(int minutes) {
    _startMinutes = minutes % (24 * 60);
    notifyListeners();
  }

  void setReminder(bool enabled) {
    _reminderEnabled = enabled;
    notifyListeners();
  }

  void setReminderLead(int minutes) {
    _reminderLead = minutes;
    notifyListeners();
  }

  void setFocusMode(bool enabled) {
    _focusMode = enabled;
    notifyListeners();
  }

  void setLinkedChallenge(String? id) {
    _linkedChallengeId = id;
    if (id == null) _shareWithTribe = false;
    notifyListeners();
  }

  void setShareWithTribe(bool value) {
    _shareWithTribe = value && _linkedChallengeId != null;
    notifyListeners();
  }

  void addStep(RitualStep step) {
    _steps.add(step);
    notifyListeners();
  }

  /// Adiciona uma sugestão com id único.
  void addSuggestion(RitualStep template) =>
      addStep(template.copyWith()._withId(Ids.generate('step')));

  void updateStep(RitualStep step) {
    final i = _steps.indexWhere((s) => s.id == step.id);
    if (i < 0) return;
    _steps[i] = step;
    notifyListeners();
  }

  void duplicateStep(String id) {
    final i = _steps.indexWhere((s) => s.id == id);
    if (i < 0) return;
    _steps.insert(i + 1, _steps[i]._withId(Ids.generate('step')));
    notifyListeners();
  }

  void removeStep(String id) {
    _steps.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Reordenação (semântica do `onReorder` do Flutter).
  void moveStep(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final step = _steps.removeAt(oldIndex);
    _steps.insert(newIndex, step);
    notifyListeners();
  }

  Ritual _build() => Ritual(
    id: _id,
    name: _name.trim(),
    period: _period,
    steps: [..._steps],
    activeWeekdays: {..._days},
    startMinutes: _startMinutes,
    reminderEnabled: _reminderEnabled,
    reminderLeadMinutes: _reminderLead,
    focusMode: _focusMode,
    linkedChallengeId: _linkedChallengeId,
    shareWithTribe: _shareWithTribe,
  );

  Future<Result<Ritual>> _save() async {
    final r = await _rituals.saveRitual(_build());
    if (r is Ok<Ritual>) {
      await _planReminders.execute(now: _clock());
    }
    return r;
  }
}

extension on RitualStep {
  RitualStep _withId(String id) => RitualStep(
    id: id,
    title: title,
    type: type,
    durationSeconds: durationSeconds,
    description: description,
    instruction: instruction,
    ambientSound: ambientSound,
    tip: tip,
    waterMl: waterMl,
    pages: pages,
  );
}
