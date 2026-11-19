import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminder_settings.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';

/// Contrato do serviço de notificações (permite fakes nos testes).
abstract class NotificationService {
  Future<Result<void>> initialize();
  Future<Result<bool>> requestPermission();
  Future<Result<void>> replaceAll(List<ScheduledReminder> reminders);
  Future<Result<void>> showNow({required String title, required String body});

  /// Notificação fixa (não removível) enquanto um ritual está em andamento.
  Future<Result<void>> showOngoing({
    required String title,
    required String body,
    int? progress,
    int? maxProgress,
  });

  Future<Result<void>> cancelOngoing();
}

/// Implementação com `flutter_local_notifications` (API 20+: parâmetros
/// nomeados).
///
/// Os horários são convertidos do fuso local do aparelho para UTC no momento
/// do agendamento. Repetições diárias/semanais preservam o horário local
/// enquanto o fuso não mudar (o app reagenda tudo a cada abertura).
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _log = Logger('LocalNotificationService');
  bool _initialized = false;

  static const _channels = {
    ReminderChannel.rituals: (
      'rituals',
      'Rituais',
      'Início dos rituais e pausas de telas',
    ),
    ReminderChannel.water: (
      'water',
      'Hidratação',
      'Intervalos de água ao longo do dia',
    ),
    ReminderChannel.wellbeing: (
      'wellbeing',
      'Bem-estar',
      'Desligar telas e desaceleração noturna',
    ),
    ReminderChannel.streak: (
      'streak',
      'Sequência',
      'Resumo diário da sua sequência de dias',
    ),
    ReminderChannel.engagement: (
      'engagement',
      'Incentivos',
      'Convites para voltar aos seus rituais',
    ),
  };

  static const _ongoingId = 900;

  @override
  Future<Result<void>> initialize() async {
    if (_initialized) return const Result.ok(null);
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Falha ao inicializar notificações', e);
      return Result.error(e);
    }
  }

  @override
  Future<Result<bool>> requestPermission() async {
    try {
      await initialize();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      bool? granted;
      if (android != null) {
        granted = await android.requestNotificationsPermission();
      }
      if (ios != null) {
        granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return Result.ok(granted ?? true);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  NotificationDetails _details(ReminderChannel channel) {
    final c = _channels[channel]!;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        c.$1,
        c.$2,
        channelDescription: c.$3,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// Próxima ocorrência local (dia + horário) convertida para UTC.
  tz.TZDateTime _nextInstance(ScheduledReminder r, DateTime now) {
    final h = r.minutesOfDay ~/ 60;
    final m = r.minutesOfDay % 60;
    DateTime local;
    if (r.date != null) {
      local = DateTime(r.date!.year, r.date!.month, r.date!.day, h, m);
    } else {
      local = DateTime(now.year, now.month, now.day, h, m);
      if (r.weekday != null) {
        final delta = (r.weekday! - local.weekday) % 7;
        local = Dates.addDays(local, delta);
        local = DateTime(local.year, local.month, local.day, h, m);
        if (!local.isAfter(now)) {
          final next = Dates.addDays(local, 7);
          local = DateTime(next.year, next.month, next.day, h, m);
        }
      } else if (!local.isAfter(now)) {
        final next = Dates.addDays(local, 1);
        local = DateTime(next.year, next.month, next.day, h, m);
      }
    }
    return tz.TZDateTime.from(local, tz.UTC);
  }

  @override
  Future<Result<void>> replaceAll(List<ScheduledReminder> reminders) async {
    try {
      await initialize();
      // Só os pendentes: preserva a notificação fixa do ritual em andamento.
      await _plugin.cancelAllPendingNotifications();
      final now = DateTime.now();
      for (final r in reminders) {
        final when = _nextInstance(r, now);
        if (r.date != null && !when.isAfter(tz.TZDateTime.now(tz.UTC))) {
          continue; // lembrete pontual já passou
        }
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: when,
          notificationDetails: _details(r.channel),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: r.date != null
              ? null
              : (r.weekday != null
                    ? DateTimeComponents.dayOfWeekAndTime
                    : DateTimeComponents.time),
        );
      }
      _log.fine('${reminders.length} lembretes agendados');
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Falha ao agendar lembretes', e);
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> showNow({
    required String title,
    required String body,
  }) async {
    try {
      await initialize();
      await _plugin.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: _details(ReminderChannel.wellbeing),
      );
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> showOngoing({
    required String title,
    required String body,
    int? progress,
    int? maxProgress,
  }) async {
    try {
      await initialize();
      final hasProgress = progress != null && maxProgress != null;
      await _plugin.show(
        id: _ongoingId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'active_ritual',
            'Ritual em andamento',
            channelDescription: 'Mostra o ritual ativo e o passo atual',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: false,
            category: AndroidNotificationCategory.progress,
            showProgress: hasProgress,
            progress: progress ?? 0,
            maxProgress: maxProgress ?? 0,
          ),
          iOS: const DarwinNotificationDetails(presentSound: false),
        ),
      );
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> cancelOngoing() async {
    try {
      await _plugin.cancel(id: _ongoingId);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
