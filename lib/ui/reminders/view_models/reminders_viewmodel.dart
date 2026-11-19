import '../../../data/repositories/reminder/reminder_repository.dart';
import '../../../data/repositories/ritual/ritual_repository.dart';
import '../../../domain/models/reminder_settings.dart';
import '../../../domain/models/ritual.dart';
import '../../../domain/use_cases/plan_reminders_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Configuração dos lembretes inteligentes.
class RemindersViewModel extends ViewModel {
  RemindersViewModel({
    required ReminderRepository reminderRepository,
    required RitualRepository ritualRepository,
    required PlanRemindersUseCase planReminders,
    DateTime Function()? clock,
  }) : _reminders = reminderRepository,
       _rituals = ritualRepository,
       _plan = planReminders,
       _clock = clock ?? DateTime.now {
    load = Command0(_load)..execute();
    update = Command1<void, ReminderSettings>(_update);
    toggleRitual = Command1<void, Ritual>(_toggleRitual);
  }

  final ReminderRepository _reminders;
  final RitualRepository _rituals;
  final PlanRemindersUseCase _plan;
  final DateTime Function() _clock;

  late final Command0<void> load;
  late final Command1<void, ReminderSettings> update;
  late final Command1<void, Ritual> toggleRitual;

  ReminderSettings _settings = const ReminderSettings();
  ReminderSettings get settings => _settings;

  List<Ritual> _ritualList = const [];
  List<Ritual> get rituals => _ritualList;

  int _scheduled = 0;
  int get scheduledCount => _scheduled;

  bool? _permissionGranted;
  bool? get permissionGranted => _permissionGranted;

  Future<Result<void>> _load() async {
    final s = await _reminders.getSettings();
    if (s is Error<ReminderSettings>) return Result.error(s.error);
    _settings = (s as Ok<ReminderSettings>).value;
    final r = await _rituals.getRituals();
    if (r is Ok<List<Ritual>>) _ritualList = r.value;
    final p = await _reminders.requestPermission();
    if (p is Ok<bool>) _permissionGranted = p.value;
    await _replan();
    notifyListeners();
    return const Result.ok(null);
  }

  Future<void> _replan() async {
    final r = await _plan.execute(now: _clock());
    if (r is Ok<List<ScheduledReminder>>) _scheduled = r.value.length;
  }

  Future<Result<void>> _update(ReminderSettings s) async {
    _settings = s; // resposta imediata na UI
    notifyListeners();
    final r = await _reminders.saveSettings(s);
    if (r is Error<ReminderSettings>) return Result.error(r.error);
    await _replan();
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _toggleRitual(Ritual ritual) async {
    final r = await _rituals.saveRitual(
      ritual.copyWith(reminderEnabled: !ritual.reminderEnabled),
    );
    if (r is Error<Ritual>) return Result.error(r.error);
    final list = await _rituals.getRituals();
    if (list is Ok<List<Ritual>>) _ritualList = list.value;
    await _replan();
    notifyListeners();
    return const Result.ok(null);
  }
}
