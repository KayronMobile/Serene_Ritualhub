import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../domain/models/health.dart';
import '../../../domain/models/user_profile.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

/// Perfil, metas diárias dos rastreadores e sessão.
class ProfileViewModel extends ViewModel {
  ProfileViewModel({
    required AuthRepository authRepository,
    required HealthRepository healthRepository,
  }) : _auth = authRepository,
       _health = healthRepository {
    load = Command0(_load)..execute();
    saveGoals = Command1<void, HealthGoals>(_saveGoals);
    rename = Command1<void, String>(_rename);
    logout = Command0(_logout);
  }

  final AuthRepository _auth;
  final HealthRepository _health;

  late final Command0<void> load;
  late final Command1<void, HealthGoals> saveGoals;
  late final Command1<void, String> rename;
  late final Command0<void> logout;

  UserProfile? get user => _auth.currentUser;

  HealthGoals _goals = const HealthGoals();
  HealthGoals get goals => _goals;

  /// Edição local (salva ao confirmar).
  void editGoals(HealthGoals g) {
    _goals = g;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    final r = await _health.getGoals();
    if (r is Error<HealthGoals>) return Result.error(r.error);
    _goals = (r as Ok<HealthGoals>).value;
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _saveGoals(HealthGoals g) async {
    final r = await _health.updateGoals(g);
    return r is Error<HealthGoals>
        ? Result.error(r.error)
        : const Result.ok(null);
  }

  Future<Result<void>> _rename(String name) async {
    final u = user;
    if (u == null || name.trim().length < 2) {
      return const Result.error(AppException('Nome muito curto.'));
    }
    final r = await _auth.updateProfile(u.copyWith(name: name.trim()));
    notifyListeners();
    return r;
  }

  Future<Result<void>> _logout() => _auth.logout();
}
