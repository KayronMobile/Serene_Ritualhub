import '../../../data/repositories/ritual/ritual_repository.dart';
import '../../../domain/models/ritual.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Item da lista de rituais com o status de hoje e da semana.
class RitualListItem {
  const RitualListItem({
    required this.ritual,
    required this.scheduledToday,
    required this.completedToday,
    required this.stepsDoneToday,
    required this.weekCompleted,
    required this.weekScheduled,
  });

  final Ritual ritual;
  final bool scheduledToday;
  final bool completedToday;
  final int stepsDoneToday;
  final int weekCompleted;
  final int weekScheduled;
}

class RitualsViewModel extends ViewModel {
  RitualsViewModel({
    required RitualRepository ritualRepository,
    DateTime Function()? clock,
  }) : _repo = ritualRepository,
       _clock = clock ?? DateTime.now {
    load = Command0(_load)..execute();
    delete = Command1<void, String>(_delete);
    _repo.addListener(_onChanged);
  }

  final RitualRepository _repo;
  final DateTime Function() _clock;

  late final Command0<void> load;
  late final Command1<void, String> delete;

  List<RitualListItem> _items = const [];
  List<RitualListItem> get items => _items;

  void _onChanged() => scheduleReload(_load);

  Future<Result<void>> _load() async {
    final now = _clock();
    final today = Dates.dateOnly(now);
    final weekAgo = Dates.addDays(today, -6);

    final r = await _repo.getRituals();
    if (r is Error<List<Ritual>>) return Result.error(r.error);
    final rituals = (r as Ok<List<Ritual>>).value;

    final logsR = await _repo.getLogs(weekAgo, today);
    final logs = logsR is Ok<List<RitualLog>> ? logsR.value : <RitualLog>[];

    _items = [
      for (final ritual in rituals)
        () {
          final mine = logs.where((l) => l.ritualId == ritual.id).toList();
          final todayLog = mine
              .where((l) => Dates.isSameDay(l.date, today))
              .firstOrNull;
          var scheduled = 0;
          for (var i = 0; i < 7; i++) {
            if (ritual.isScheduledOn(Dates.addDays(weekAgo, i))) scheduled++;
          }
          return RitualListItem(
            ritual: ritual,
            scheduledToday: ritual.isScheduledOn(today),
            completedToday: todayLog?.isComplete ?? false,
            stepsDoneToday: todayLog?.completedStepIds.length ?? 0,
            weekCompleted: mine.where((l) => l.isComplete).length,
            weekScheduled: scheduled,
          );
        }(),
    ];
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _delete(String id) => _repo.deleteRitual(id);

  @override
  void dispose() {
    _repo.removeListener(_onChanged);
    super.dispose();
  }
}
