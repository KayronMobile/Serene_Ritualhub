import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

typedef Credentials = ({String email, String password});
typedef Registration = ({String name, String email, String password});

class LoginViewModel extends ViewModel {
  LoginViewModel({required AuthRepository authRepository})
    : _auth = authRepository {
    load = Command0(_load)..execute();
    login = Command1<void, Credentials>(_login);
    register = Command1<void, Registration>(_register);
    biometricLogin = Command0(_biometricLogin);
  }

  final AuthRepository _auth;

  late final Command0<void> load;
  late final Command1<void, Credentials> login;
  late final Command1<void, Registration> register;
  late final Command0<void> biometricLogin;

  bool _rememberMe = true;
  bool get rememberMe => _rememberMe;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _rememberedEmail;
  String? get rememberedEmail => _rememberedEmail;

  bool _biometricsAvailable = false;
  bool get biometricsAvailable => _biometricsAvailable;

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void toggleObscure() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    _rememberedEmail = await _auth.rememberedEmail;
    _biometricsAvailable = await _auth.canUseBiometrics;
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _login(Credentials c) => _auth.login(
    email: c.email,
    password: c.password,
    rememberMe: _rememberMe,
  );

  Future<Result<void>> _register(Registration r) =>
      _auth.register(name: r.name, email: r.email, password: r.password);

  Future<Result<void>> _biometricLogin() => _auth.loginWithBiometrics();
}
