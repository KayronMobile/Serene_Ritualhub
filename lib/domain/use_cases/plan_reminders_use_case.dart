import '../../data/repositories/health/health_repository.dart';
import '../../data/repositories/reminder/reminder_repository.dart';
import '../../data/repositories/ritual/ritual_repository.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../models/health.dart';
import '../models/reminder_settings.dart';
import '../models/ritual.dart';

/// Gera e aplica o plano de "lembretes inteligentes":
///
/// * início de cada ritual (com antecedência configurável) nos dias ativos;
/// * intervalos de água — apenas enquanto a meta do dia não foi batida, com
///   mensagem que informa quanto falta (replanejado a cada registro de água);
/// * alerta de "desligar telas", antecipado no dia da semana de maior falha
///   detectado pelo relatório semanal.
class PlanRemindersUseCase {
  PlanRemindersUseCase({
    required RitualRepository ritualRepository,
    required HealthRepository healthRepository,
    required ReminderRepository reminderRepository,
  }) : _rituals = ritualRepository,
       _health = healthRepository,
       _reminders = reminderRepository;

  final RitualRepository _rituals;
  final HealthRepository _health;
  final ReminderRepository _reminders;

  /// Quantos dias à frente os lembretes pontuais de água são agendados.
  static const waterLookaheadDays = 2;

  Future<Result<List<ScheduledReminder>>> execute({
    required DateTime now,
    bool requestPermission = false,
  }) async {
    if (requestPermission) await _reminders.requestPermission();
    final settingsR = await _reminders.getSettings();
    if (settingsR is Error<ReminderSettings>) {
      return Result.error(settingsR.error);
    }
    final settings = (settingsR as Ok<ReminderSettings>).value;

    final ritualsR = await _rituals.getRituals();
    final rituals = ritualsR is Ok<List<Ritual>> ? ritualsR.value : <Ritual>[];

    final goalsR = await _health.getGoals();
    final goals = goalsR is Ok<HealthGoals> ? goalsR.value : const HealthGoals();
    final todayR = await _health.getLog(now);
    final todayLog = todayR is Ok<DailyHealthLog>
        ? todayR.value
        : DailyHealthLog.empty(Dates.dateOnly(now));

    final plan = build(
      settings: settings,
      rituals: rituals,
      goals: goals,
      today: todayLog,
      now: now,
    );
    final applied = await _reminders.applySchedule(plan);
    if (applied is Error<void>) return Result.error(applied.error);
    return Result.ok(plan);
  }

  /// Função pura (testável) que monta o plano de notificações.
  static List<ScheduledReminder> build({
    required ReminderSettings settings,
    required List<Ritual> rituals,
    required HealthGoals goals,
    required DailyHealthLog today,
    required DateTime now,
  }) {
    final out = <ScheduledReminder>[];

    // 1) Início dos rituais.
    if (settings.ritualStartEnabled) {
      for (var i = 0; i < rituals.length; i++) {
        final r = rituals[i];
        if (!r.reminderEnabled || r.steps.isEmpty) continue;
        final at = (r.startMinutes - r.reminderLeadMinutes) % (24 * 60);
        final emoji = switch (r.period) {
          RitualPeriod.morning => '☀️',
          RitualPeriod.afternoon => '🌿',
          RitualPeriod.night => '🌙',
        };
        for (final weekday in r.activeWeekdays) {
          out.add(
            ScheduledReminder(
              id: 1000 + i * 10 + weekday,
              title: '$emoji ${r.name}',
              body: r.reminderLeadMinutes > 0
                  ? 'Começa em ${r.reminderLeadMinutes} min '
                        '(${Dates.hhmm(r.startMinutes)}). Primeiro passo: '
                        '${r.steps.first.title}.'
                  : 'Hora do seu ritual. Primeiro passo: '
                        '${r.steps.first.title}.',
              minutesOfDay: at,
              weekday: weekday,
            ),
          );
        }
      }
    }

    // 2) Água: lembretes pontuais e adaptativos.
    if (settings.waterEnabled) {
      final todayDate = Dates.dateOnly(now);
      final nowMinutes = now.hour * 60 + now.minute;
      final slots = settings.waterSlots;
      for (var d = 0; d <= waterLookaheadDays; d++) {
        final date = Dates.addDays(todayDate, d);
        for (var s = 0; s < slots.length; s++) {
          final slot = slots[s];
          String body;
          if (d == 0) {
            if (slot <= nowMinutes) continue;
            final missing = goals.waterMl - today.waterMl;
            if (missing <= 0) break; // meta batida: silêncio pelo resto do dia
            body =
                'Faltam ${_ml(missing)} para sua meta. Que tal '
                '${goals.waterIncrementMl} ml agora?';
          } else {
            body =
                'Pausa para um copo d’água (${goals.waterIncrementMl} ml). '
                'Seu corpo agradece.';
          }
          out.add(
            ScheduledReminder(
              id: 2000 + d * 100 + s,
              title: '💧 Hora de se hidratar',
              body: body,
              minutesOfDay: slot,
              date: date,
              channel: ReminderChannel.water,
            ),
          );
        }
      }
    }

    // 3) Desligar telas (higiene do sono).
    if (settings.screensOffEnabled) {
      final night = rituals.where((r) => r.period == RitualPeriod.night);
      final suffix = night.isEmpty
          ? 'Prepare o corpo para descansar.'
          : '${night.first.name} às ${Dates.hhmm(night.first.startMinutes)}.';
      final vulnerable = settings.vulnerableWeekday;
      if (vulnerable == null) {
        out.add(
          ScheduledReminder(
            id: 3000,
            title: '📵 Hora de desligar as telas',
            body: suffix,
            minutesOfDay: settings.screensOffMinutes,
            channel: ReminderChannel.wellbeing,
          ),
        );
      } else {
        for (var weekday = 1; weekday <= 7; weekday++) {
          final early = weekday == vulnerable;
          out.add(
            ScheduledReminder(
              id: 3000 + weekday,
              title: early
                  ? '📵 Hoje vale começar mais cedo'
                  : '📵 Hora de desligar as telas',
              body: early
                  ? '${Dates.weekdayLong[weekday - 1]} costuma ser seu dia '
                        'mais difícil. Desligue as telas agora. $suffix'
                  : suffix,
              minutesOfDay:
                  (settings.screensOffMinutes -
                      (early ? settings.vulnerableLeadMinutes : 0)) %
                  (24 * 60),
              weekday: weekday,
              channel: ReminderChannel.wellbeing,
            ),
          );
        }
      }
    }
    return out;
  }

  static String _ml(int ml) {
    if (ml >= 1000) {
      final l = ml / 1000;
      return '${l.toStringAsFixed(l == l.roundToDouble() ? 0 : 1).replaceAll('.', ',')} L';
    }
    return '$ml ml';
  }
}
