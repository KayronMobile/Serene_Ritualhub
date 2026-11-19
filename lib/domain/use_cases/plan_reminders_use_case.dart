import '../../data/repositories/health/health_repository.dart';
import '../../data/repositories/reminder/reminder_repository.dart';
import '../../data/repositories/ritual/ritual_repository.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../models/health.dart';
import '../models/reminder_settings.dart';
import '../models/ritual.dart';
import 'consistency_calculator.dart';

/// Gera e aplica o plano de "lembretes inteligentes":
///
/// * aviso 5 min antes e no horário de início de cada ritual nos dias ativos;
/// * resumo diário da sequência de dias;
/// * convites para voltar ao app após alguns dias sem abri-lo (reagendados a
///   cada abertura, então só disparam se o usuário sumir);
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

  /// Antecedência do aviso "falta pouco" antes de cada ritual.
  static const ritualHeadsUpMinutes = 5;

  /// Dias à frente com resumo da sequência agendado.
  static const streakLookaheadDays = 3;

  /// Dias sem abrir o app após os quais enviamos um convite para voltar.
  static const comebackAfterDays = [2, 4, 7];
  static const comebackMinutes = 18 * 60 + 30;

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
    final goals = goalsR is Ok<HealthGoals>
        ? goalsR.value
        : const HealthGoals();
    final todayR = await _health.getLog(now);
    final todayLog = todayR is Ok<DailyHealthLog>
        ? todayR.value
        : DailyHealthLog.empty(Dates.dateOnly(now));

    final logsR = await _rituals.getLogs(Dates.addDays(now, -365), now);
    final logs = logsR is Ok<List<RitualLog>> ? logsR.value : <RitualLog>[];
    final streak = ConsistencyCalculator.ritualStreak(
      rituals: rituals,
      logs: logs,
      now: now,
    );
    final todayKey = Dates.key(now);
    final doneToday = logs.any(
      (l) => l.isComplete && Dates.key(l.date) == todayKey,
    );

    final plan = build(
      settings: settings,
      rituals: rituals,
      goals: goals,
      today: todayLog,
      now: now,
      streakDays: streak,
      completedToday: doneToday,
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
    int streakDays = 0,
    bool completedToday = false,
  }) {
    final out = <ScheduledReminder>[];
    final todayDate = Dates.dateOnly(now);
    final nowMinutes = now.hour * 60 + now.minute;

    // 1) Início dos rituais.
    if (settings.ritualStartEnabled) {
      for (var i = 0; i < rituals.length; i++) {
        final r = rituals[i];
        if (!r.reminderEnabled || r.steps.isEmpty) continue;
        final emoji = switch (r.period) {
          RitualPeriod.morning => '☀️',
          RitualPeriod.afternoon => '🌿',
          RitualPeriod.night => '🌙',
        };
        final first = r.steps.first.title;
        final headsUpAt = (r.startMinutes - ritualHeadsUpMinutes) % (24 * 60);
        for (final weekday in r.activeWeekdays) {
          // Aviso antecipado (5 min antes) — o dia da semana pode recuar se o
          // ritual começa logo após a meia-noite.
          final headsUpWeekday = r.startMinutes < ritualHeadsUpMinutes
              ? (weekday + 5) % 7 + 1
              : weekday;
          out.add(
            ScheduledReminder(
              id: 1000 + i * 20 + weekday,
              title: '$emoji ${r.name} em $ritualHeadsUpMinutes min',
              body:
                  'Prepare o espaço: às ${Dates.hhmm(r.startMinutes)} '
                  'começa com "$first". Você consegue!',
              minutesOfDay: headsUpAt,
              weekday: headsUpWeekday,
            ),
          );
          // No horário: hora de ativar o ritual.
          out.add(
            ScheduledReminder(
              id: 1000 + i * 20 + 10 + weekday,
              title: '$emoji Hora do ${r.name}',
              body:
                  'Toque para começar agora. Primeiro passo: $first '
                  '(${r.totalMinutes} min no total).',
              minutesOfDay: r.startMinutes,
              weekday: weekday,
            ),
          );
        }
      }
    }

    // 2) Água: lembretes pontuais e adaptativos.
    if (settings.waterEnabled) {
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

    // 4) Sequência de dias: um resumo por dia.
    if (settings.streakEnabled) {
      for (var d = 0; d <= streakLookaheadDays; d++) {
        if (d == 0 && settings.streakMinutes <= nowMinutes) continue;
        final String title;
        final String body;
        if (d == 0 && completedToday) {
          title = '🔥 $streakDays ${_dias(streakDays)} seguidos';
          body = 'Sequência garantida hoje. Amanhã tem mais — orgulho de você!';
        } else if (d == 0 && streakDays > 0) {
          title = '🔥 Sua sequência: $streakDays ${_dias(streakDays)}';
          body =
              'Conclua um ritual ainda hoje para chegar a '
              '${streakDays + 1} ${_dias(streakDays + 1)}.';
        } else if (d == 0) {
          title = '🌱 Comece sua sequência hoje';
          body = 'Um ritual concluído hoje é o primeiro dia da sua sequência.';
        } else {
          // Dias futuros: o app reescreve a mensagem a cada abertura/conclusão.
          title = '🔥 Sua sequência está em jogo';
          body = 'Conclua um ritual hoje para manter seus dias seguidos.';
        }
        out.add(
          ScheduledReminder(
            id: 4000 + d,
            title: title,
            body: body,
            minutesOfDay: settings.streakMinutes,
            date: Dates.addDays(todayDate, d),
            channel: ReminderChannel.streak,
          ),
        );
      }
    }

    // 5) Volte ao app: reagendado a cada abertura, só dispara se sumir.
    if (settings.comebackEnabled) {
      const messages = [
        (
          '🌿 Sentimos sua falta',
          'Seus rituais estão te esperando. Que tal 5 minutos só para você?',
        ),
        (
          '☀️ Um novo começo',
          'Não importa quanto tempo passou: o melhor dia para voltar é hoje.',
        ),
        (
          '💚 Sua tribo está ativa',
          'Volte, registre um ritual e retome o seu ritmo.',
        ),
      ];
      for (var k = 0; k < comebackAfterDays.length; k++) {
        out.add(
          ScheduledReminder(
            id: 5000 + k,
            title: messages[k].$1,
            body: messages[k].$2,
            minutesOfDay: comebackMinutes,
            date: Dates.addDays(todayDate, comebackAfterDays[k]),
            channel: ReminderChannel.engagement,
          ),
        );
      }
    }
    return out;
  }

  static String _dias(int n) => n == 1 ? 'dia' : 'dias';

  static String _ml(int ml) {
    if (ml >= 1000) {
      final l = ml / 1000;
      return '${l.toStringAsFixed(l == l.roundToDouble() ? 0 : 1).replaceAll('.', ',')} L';
    }
    return '$ml ml';
  }
}
