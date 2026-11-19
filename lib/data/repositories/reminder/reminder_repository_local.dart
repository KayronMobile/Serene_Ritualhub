import '../../../domain/models/reminder_settings.dart';
import '../../../utils/result.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import 'reminder_repository.dart';

class ReminderRepositoryLocal extends ReminderRepository {
  ReminderRepositoryLocal({
    required LocalStorageService storage,
    required NotificationService notifications,
  }) : _storage = storage,
       _notifications = notifications;

  static const _kSettings = 'reminders.settings';

  final LocalStorageService _storage;
  final NotificationService _notifications;

  ReminderSettings? _settings;
  int _scheduledCount = 0;

  @override
  int get scheduledCount => _scheduledCount;

  @override
  Future<Result<ReminderSettings>> getSettings() async {
    if (_settings != null) return Result.ok(_settings!);
    final r = await _storage.readJson(_kSettings);
    switch (r) {
      case Ok<Object?>():
        _settings = r.value == null
            ? const ReminderSettings()
            : ReminderSettings.fromJson(r.value! as Map<String, Object?>);
        return Result.ok(_settings!);
      case Error<Object?>():
        return Result.error(r.error);
    }
  }

  @override
  Future<Result<ReminderSettings>> saveSettings(
    ReminderSettings settings,
  ) async {
    final r = await _storage.writeJson(_kSettings, settings.toJson());
    if (r is Error<void>) return Result.error(r.error);
    _settings = settings;
    notifyListeners();
    return Result.ok(settings);
  }

  @override
  Future<Result<bool>> requestPermission() =>
      _notifications.requestPermission();

  @override
  Future<Result<void>> applySchedule(List<ScheduledReminder> reminders) async {
    final r = await _notifications.replaceAll(reminders);
    if (r is Ok<void>) {
      _scheduledCount = reminders.length;
      notifyListeners();
    }
    return r;
  }
}
