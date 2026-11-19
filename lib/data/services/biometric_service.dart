import 'package:local_auth/local_auth.dart';

import '../../utils/result.dart';

/// Contrato do serviço de biometria.
abstract class BiometricService {
  Future<bool> isAvailable();
  Future<Result<bool>> authenticate(String reason);
}

/// Implementação com `local_auth` (API 3.x).
class LocalBiometricService implements BiometricService {
  LocalBiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  @override
  Future<Result<bool>> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return Result.ok(ok);
    } on Exception catch (e) {
      return Result.error(AppException('Biometria indisponível: $e'));
    }
  }
}
