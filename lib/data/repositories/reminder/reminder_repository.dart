import 'package:flutter/foundation.dart';

import '../../../domain/models/reminder_settings.dart';
import '../../../utils/result.dart';

/// Preferências de lembretes e agendamento efetivo das notificações.
abstract class ReminderRepository extends ChangeNotifier {
  Future<Result<ReminderSettings>> getSettings();

  Future<Result<ReminderSettings>> saveSettings(ReminderSettings settings);

  Future<Result<bool>> requestPermission();

  /// Substitui todas as notificações agendadas por [reminders].
  Future<Result<void>> applySchedule(List<ScheduledReminder> reminders);

  /// Quantidade de lembretes atualmente agendados (informativo).
  int get scheduledCount;
}
