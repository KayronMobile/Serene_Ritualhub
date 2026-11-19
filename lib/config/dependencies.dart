import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/achievement/achievement_repository.dart';
import '../data/repositories/achievement/achievement_repository_local.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local.dart';
import '../data/repositories/challenge/challenge_repository.dart';
import '../data/repositories/challenge/challenge_repository_local.dart';
import '../data/repositories/health/health_repository.dart';
import '../data/repositories/health/health_repository_local.dart';
import '../data/repositories/reminder/reminder_repository.dart';
import '../data/repositories/reminder/reminder_repository_local.dart';
import '../data/repositories/ritual/ritual_repository.dart';
import '../data/repositories/ritual/ritual_repository_local.dart';
import '../data/services/biometric_service.dart';
import '../data/services/image_picker_service.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/notification_service.dart';
import '../domain/use_cases/complete_ritual_step_use_case.dart';
import '../domain/use_cases/evaluate_achievements_use_case.dart';
import '../domain/use_cases/plan_reminders_use_case.dart';
import '../domain/use_cases/weekly_report_use_case.dart';

/// Use cases compartilhados por qualquer configuração de repositórios.
List<SingleChildWidget> get _sharedProviders => [
  Provider(
    lazy: true,
    create: (context) => WeeklyReportUseCase(
      ritualRepository: context.read(),
      healthRepository: context.read(),
    ),
  ),
  Provider(
    lazy: true,
    create: (context) => EvaluateAchievementsUseCase(
      ritualRepository: context.read(),
      healthRepository: context.read(),
      challengeRepository: context.read(),
      achievementRepository: context.read(),
    ),
  ),
  Provider(
    lazy: true,
    create: (context) => PlanRemindersUseCase(
      ritualRepository: context.read(),
      healthRepository: context.read(),
      reminderRepository: context.read(),
    ),
  ),
  Provider(
    lazy: true,
    create: (context) => CompleteRitualStepUseCase(
      ritualRepository: context.read(),
      healthRepository: context.read(),
      challengeRepository: context.read(),
    ),
  ),
];

/// Configuração "local": persistência no aparelho, sem backend.
///
/// Para conectar um backend, crie `providersRemote` trocando apenas as
/// implementações dos repositórios (ex.: `RitualRepositoryRemote`), sem
/// alterar ViewModels ou Views.
List<SingleChildWidget> get providersLocal => [
  Provider(create: (context) => LocalStorageService()),
  Provider<NotificationService>(
    create: (context) => LocalNotificationService(),
  ),
  Provider<BiometricService>(create: (context) => LocalBiometricService()),
  Provider<PhotoService>(create: (context) => ImagePickerPhotoService()),
  ChangeNotifierProvider<AuthRepository>(
    create: (context) => AuthRepositoryLocal(
      storage: context.read(),
      biometrics: context.read(),
    ),
  ),
  ChangeNotifierProvider<RitualRepository>(
    create: (context) => RitualRepositoryLocal(storage: context.read()),
  ),
  ChangeNotifierProvider<HealthRepository>(
    create: (context) => HealthRepositoryLocal(storage: context.read()),
  ),
  ChangeNotifierProvider<ChallengeRepository>(
    create: (context) => ChallengeRepositoryLocal(storage: context.read()),
  ),
  ChangeNotifierProvider<AchievementRepository>(
    create: (context) => AchievementRepositoryLocal(storage: context.read()),
  ),
  ChangeNotifierProvider<ReminderRepository>(
    create: (context) => ReminderRepositoryLocal(
      storage: context.read(),
      notifications: context.read(),
    ),
  ),
  ..._sharedProviders,
];
