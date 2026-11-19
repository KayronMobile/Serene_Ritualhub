import 'dart:convert';

import '../../../domain/models/user_profile.dart';
import '../../../utils/result.dart';
import '../../services/biometric_service.dart';
import '../../services/local_storage_service.dart';
import 'auth_repository.dart';

/// Implementação local (sem backend) do [AuthRepository].
///
/// Guarda um único perfil no aparelho. A senha é armazenada apenas como
/// hash simples para fins de demonstração — substitua por um
/// `AuthRepositoryRemote` (Firebase/Supabase/API própria) em produção.
class AuthRepositoryLocal extends AuthRepository {
  AuthRepositoryLocal({
    required LocalStorageService storage,
    required BiometricService biometrics,
  }) : _storage = storage,
       _biometrics = biometrics;

  /// Id fixo do usuário local (o app é single-user no modo local).
  static const localUserId = 'me';

  static const _kProfile = 'auth.profile';
  static const _kSession = 'auth.session';
  static const _kRemember = 'auth.remember';
  static const _kSecret = 'auth.secret';

  final LocalStorageService _storage;
  final BiometricService _biometrics;

  bool? _authenticated;
  UserProfile? _user;

  @override
  UserProfile? get currentUser => _user;

  @override
  Future<bool> get isAuthenticated async {
    if (_authenticated != null) return _authenticated!;
    final session = await _storage.readString(_kSession);
    final active = session is Ok<String?> && session.value == 'active';
    if (active) await _loadProfile();
    _authenticated = active && _user != null;
    return _authenticated!;
  }

  @override
  Future<String?> get rememberedEmail async {
    final r = await _storage.readString(_kRemember);
    return r is Ok<String?> ? r.value : null;
  }

  @override
  Future<bool> get canUseBiometrics async =>
      (await rememberedEmail) != null && await _biometrics.isAvailable();

  Future<void> _loadProfile() async {
    final r = await _storage.readJson(_kProfile);
    if (r is Ok<Object?> && r.value != null) {
      _user = UserProfile.fromJson(r.value! as Map<String, Object?>);
    }
  }

  String _hash(String email, String password) =>
      base64Encode(utf8.encode('${email.toLowerCase()}::$password'));

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!normalized.contains('@') && normalized.length < 3) {
      return const Result.error(AppException('Informe um e-mail ou usuário.'));
    }
    if (password.length < 6) {
      return const Result.error(
        AppException('A senha precisa ter ao menos 6 caracteres.'),
      );
    }

    await _loadProfile();
    final secret = await _storage.readString(_kSecret);
    final stored = secret is Ok<String?> ? secret.value : null;

    if (_user == null || stored == null) {
      // Primeiro acesso neste aparelho: cria o perfil automaticamente.
      final name = _nameFromEmail(normalized);
      _user = UserProfile(id: localUserId, name: name, email: normalized);
      await _storage.writeJson(_kProfile, _user!.toJson());
      await _storage.writeString(_kSecret, _hash(normalized, password));
    } else if (_user!.email.toLowerCase() != normalized ||
        stored != _hash(normalized, password)) {
      return const Result.error(AppException('E-mail ou senha incorretos.'));
    }

    if (rememberMe) {
      await _storage.writeString(_kRemember, normalized);
    } else {
      await _storage.remove(_kRemember);
    }
    return _startSession();
  }

  @override
  Future<Result<void>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (name.trim().length < 2) {
      return const Result.error(AppException('Informe seu nome.'));
    }
    if (!normalized.contains('@')) {
      return const Result.error(AppException('E-mail inválido.'));
    }
    if (password.length < 6) {
      return const Result.error(
        AppException('A senha precisa ter ao menos 6 caracteres.'),
      );
    }
    _user = UserProfile(id: localUserId, name: name.trim(), email: normalized);
    await _storage.writeJson(_kProfile, _user!.toJson());
    await _storage.writeString(_kSecret, _hash(normalized, password));
    await _storage.writeString(_kRemember, normalized);
    return _startSession();
  }

  @override
  Future<Result<void>> loginWithBiometrics() async {
    if (!await canUseBiometrics) {
      return const Result.error(
        AppException(
          'Ative "Lembrar de mim" e entre com senha uma vez para usar a '
          'biometria.',
        ),
      );
    }
    final r = await _biometrics.authenticate('Entre no Serene com segurança');
    switch (r) {
      case Ok<bool>():
        if (!r.value) {
          return const Result.error(AppException('Autenticação cancelada.'));
        }
        await _loadProfile();
        return _startSession();
      case Error<bool>():
        return Result.error(r.error);
    }
  }

  @override
  Future<Result<void>> updateProfile(UserProfile profile) async {
    _user = profile;
    final r = await _storage.writeJson(_kProfile, profile.toJson());
    notifyListeners();
    return r;
  }

  @override
  Future<Result<void>> logout() async {
    await _storage.remove(_kSession);
    _authenticated = false;
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _startSession() async {
    final r = await _storage.writeString(_kSession, 'active');
    if (r is Error<void>) return r;
    _authenticated = true;
    notifyListeners();
    return const Result.ok(null);
  }

  static String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._\-]+'), ' ');
    final words = local.split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return 'Você';
    return words
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
