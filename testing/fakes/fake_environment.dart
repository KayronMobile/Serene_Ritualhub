import 'package:ritualhub/data/repositories/achievement/achievement_repository_local.dart';
import 'package:ritualhub/data/repositories/auth/auth_repository_local.dart';
import 'package:ritualhub/data/repositories/challenge/challenge_repository_local.dart';
import 'package:ritualhub/data/repositories/health/health_repository_local.dart';
import 'package:ritualhub/data/repositories/reminder/reminder_repository_local.dart';
import 'package:ritualhub/data/repositories/ritual/ritual_repository_local.dart';
import 'package:ritualhub/data/services/local_storage_service.dart';
import 'package:ritualhub/domain/use_cases/complete_ritual_step_use_case.dart';
import 'package:ritualhub/domain/use_cases/evaluate_achievements_use_case.dart';
import 'package:ritualhub/domain/use_cases/plan_reminders_use_case.dart';
import 'package:ritualhub/domain/use_cases/weekly_report_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_services.dart';

/// Monta toda a camada de dados local sobre um SharedPreferences em memória
/// e um relógio fixo — usado pelos testes de use cases e ViewModels.
class FakeEnvironment {
  FakeEnvironment._(this.now, this.storage);

  static Future<FakeEnvironment> create({DateTime? now}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return FakeEnvironment._(
      now ?? DateTime(2026, 11, 18, 10, 30), // quarta-feira
      LocalStorageService(preferences: prefs),
    );
  }

  DateTime now;
  final LocalStorageService storage;

  DateTime clock() => now;

  final notifications = FakeNotificationService();
  final biometrics = FakeBiometricService();
  final photos = FakePhotoService();
  final audio = FakeAudioService();

  late final auth = AuthRepositoryLocal(
    storage: storage,
    biometrics: biometrics,
  );
  late final rituals = RitualRepositoryLocal(storage: storage, clock: clock);
  late final health = HealthRepositoryLocal(storage: storage, clock: clock);
  late final challenges = ChallengeRepositoryLocal(
    storage: storage,
    clock: clock,
  );
  late final achievements = AchievementRepositoryLocal(storage: storage);
  late final reminders = ReminderRepositoryLocal(
    storage: storage,
    notifications: notifications,
  );

  late final weeklyReport = WeeklyReportUseCase(
    ritualRepository: rituals,
    healthRepository: health,
  );
  late final evaluateAchievements = EvaluateAchievementsUseCase(
    ritualRepository: rituals,
    healthRepository: health,
    challengeRepository: challenges,
    achievementRepository: achievements,
  );
  late final planReminders = PlanRemindersUseCase(
    ritualRepository: rituals,
    healthRepository: health,
    reminderRepository: reminders,
  );
  late final completeStep = CompleteRitualStepUseCase(
    ritualRepository: rituals,
    healthRepository: health,
    challengeRepository: challenges,
  );

  /// Cria (cadastro) e autentica o usuário local de testes.
  Future<void> signIn() => auth.register(
    name: 'Lucas',
    email: 'lucas@serene.com',
    password: '123456',
  );
}
