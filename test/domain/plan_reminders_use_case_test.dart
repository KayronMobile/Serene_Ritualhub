import 'package:flutter_test/flutter_test.dart';
import 'package:ritualhub/domain/models/health.dart';
import 'package:ritualhub/domain/models/reminder_settings.dart';
import 'package:ritualhub/domain/models/ritual.dart';
import 'package:ritualhub/domain/use_cases/plan_reminders_use_case.dart';
import 'package:ritualhub/utils/dates.dart';

void main() {
  final now = DateTime(2026, 11, 18, 10, 0);
  const goals = HealthGoals(waterMl: 2000);

  const morning = Ritual(
    id: 'm',
    name: 'Despertar',
    period: RitualPeriod.morning,
    steps: [
      RitualStep(
        id: 's',
        title: 'Água',
        type: StepType.hydration,
        durationSeconds: 60,
      ),
    ],
    activeWeekdays: {1, 2, 3, 4, 5},
    startMinutes: 7 * 60,
    reminderLeadMinutes: 15,
  );
  const night = Ritual(
    id: 'n',
    name: 'Desaceleração',
    period: RitualPeriod.night,
    steps: [
      RitualStep(
        id: 'n1',
        title: 'Chá',
        type: StepType.custom,
        durationSeconds: 300,
      ),
    ],
    activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
    startMinutes: 21 * 60 + 30,
    reminderEnabled: false,
  );

  List<ScheduledReminder> plan({
    ReminderSettings settings = const ReminderSettings(),
    int waterToday = 0,
  }) => PlanRemindersUseCase.build(
    settings: settings,
    rituals: const [morning, night],
    goals: goals,
    today: DailyHealthLog(date: Dates.dateOnly(now), waterMl: waterToday),
    now: now,
  );

  test('agenda o início do ritual com antecedência em cada dia ativo', () {
    final ritual = plan().where((r) => r.channel == ReminderChannel.rituals);
    expect(ritual.length, 5); // ritual noturno está com lembrete desligado
    expect(ritual.every((r) => r.minutesOfDay == 7 * 60 - 15), isTrue);
    expect(ritual.map((r) => r.weekday).toSet(), {1, 2, 3, 4, 5});
  });

  test('lembretes de água de hoje informam quanto falta e respeitam o horário', () {
    final water = plan(waterToday: 500)
        .where((r) => r.channel == ReminderChannel.water)
        .toList();
    final today = water.where((r) => Dates.isSameDay(r.date!, now)).toList();
    expect(today, isNotEmpty);
    expect(today.every((r) => r.minutesOfDay > 10 * 60), isTrue);
    expect(today.first.body, contains('1,5 L'));
  });

  test('água silencia no dia quando a meta já foi batida', () {
    final water = plan(waterToday: 2100)
        .where((r) => r.channel == ReminderChannel.water)
        .toList();
    expect(water.where((r) => Dates.isSameDay(r.date!, now)), isEmpty);
    // Dias seguintes continuam com lembretes.
    expect(water, isNotEmpty);
  });

  test('antecipa o alerta de telas no dia vulnerável', () {
    final screens = plan(
      settings: const ReminderSettings(vulnerableWeekday: DateTime.friday),
    ).where((r) => r.channel == ReminderChannel.wellbeing).toList();

    expect(screens.length, 7);
    final friday = screens.singleWhere((r) => r.weekday == DateTime.friday);
    final monday = screens.singleWhere((r) => r.weekday == DateTime.monday);
    expect(friday.minutesOfDay, 21 * 60);
    expect(monday.minutesOfDay, 21 * 60 + 30);
  });

  test('ids de notificação são únicos', () {
    final all = plan(
      settings: const ReminderSettings(vulnerableWeekday: DateTime.friday),
    );
    expect(all.map((r) => r.id).toSet().length, all.length);
  });
}
