import 'package:flutter/foundation.dart';

import '../../../domain/models/user_profile.dart';
import '../../../utils/result.dart';

/// Fonte única da verdade sobre a sessão do usuário.
///
/// Estende [ChangeNotifier] para que o roteador reaja a login/logout
/// (mesma abordagem do app de exemplo "Compass" do guia oficial).
abstract class AuthRepository extends ChangeNotifier {
  /// `true` se há uma sessão ativa.
  Future<bool> get isAuthenticated;

  /// Usuário atual (disponível após [isAuthenticated] retornar `true`).
  UserProfile? get currentUser;

  /// E-mail salvo quando "Lembrar de mim" está ativo.
  Future<String?> get rememberedEmail;

  /// Biometria disponível e há credencial lembrada.
  Future<bool> get canUseBiometrics;

  Future<Result<void>> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<Result<void>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<void>> loginWithBiometrics();

  Future<Result<void>> updateProfile(UserProfile profile);

  Future<Result<void>> logout();
}
