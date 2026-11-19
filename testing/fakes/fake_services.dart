import 'package:ritualhub/data/services/audio_service.dart';
import 'package:ritualhub/data/services/biometric_service.dart';
import 'package:ritualhub/data/services/image_picker_service.dart';
import 'package:ritualhub/data/services/notification_service.dart';
import 'package:ritualhub/domain/models/reminder_settings.dart';
import 'package:ritualhub/utils/result.dart';

/// Guarda os lembretes "agendados" em memória.
class FakeNotificationService implements NotificationService {
  List<ScheduledReminder> scheduled = [];
  bool granted = true;

  @override
  Future<Result<void>> initialize() async => const Result.ok(null);

  @override
  Future<Result<bool>> requestPermission() async => Result.ok(granted);

  @override
  Future<Result<void>> replaceAll(List<ScheduledReminder> reminders) async {
    scheduled = [...reminders];
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> showNow({
    required String title,
    required String body,
  }) async => const Result.ok(null);

  String? ongoingTitle;

  @override
  Future<Result<void>> showOngoing({
    required String title,
    required String body,
    int? progress,
    int? maxProgress,
  }) async {
    ongoingTitle = title;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> cancelOngoing() async {
    ongoingTitle = null;
    return const Result.ok(null);
  }
}

class FakeBiometricService implements BiometricService {
  FakeBiometricService({this.available = true, this.succeeds = true});

  bool available;
  bool succeeds;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Result<bool>> authenticate(String reason) async => Result.ok(succeeds);
}

class FakePhotoService implements PhotoService {
  String? path = '/tmp/fake.jpg';

  @override
  Future<Result<String?>> pick({required bool fromCamera}) async =>
      Result.ok(path);
}

/// Registra as chamadas de áudio em memória.
class FakeAudioService implements AudioService {
  String? playing;
  int bells = 0;

  @override
  Future<void> playAmbient(String name) async => playing = name;

  @override
  Future<void> pauseAmbient() async => playing = null;

  @override
  Future<void> resumeAmbient() async {}

  @override
  Future<void> stopAmbient() async => playing = null;

  @override
  Future<void> playBell() async => bells++;

  @override
  Future<void> dispose() async {}
}
