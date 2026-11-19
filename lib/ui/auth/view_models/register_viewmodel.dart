import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_model.dart';

typedef Registration = ({String name, String email, String password});

/// Força da senha exibida enquanto o usuário digita.
enum PasswordStrength {
  empty(0, ''),
  weak(1, 'Fraca'),
  medium(2, 'Média'),
  strong(3, 'Forte');

  const PasswordStrength(this.level, this.label);

  final int level;
  final String label;
}

/// ViewModel da tela de cadastro (e-mail + senha).
///
/// Mantém apenas o estado da UI (visibilidade da senha, aceite dos termos,
/// força da senha) e delega a criação da conta ao [AuthRepository]. Ao
/// concluir, o repositório inicia a sessão e o roteador redireciona para a
/// Home automaticamente.
class RegisterViewModel extends ViewModel {
  RegisterViewModel({required AuthRepository authRepository})
    : _auth = authRepository {
    register = Command1<void, Registration>(_register);
  }

  final AuthRepository _auth;

  late final Command1<void, Registration> register;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _acceptedTerms = false;
  bool get acceptedTerms => _acceptedTerms;

  PasswordStrength _strength = PasswordStrength.empty;
  PasswordStrength get strength => _strength;

  void toggleObscure() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setAcceptedTerms(bool value) {
    _acceptedTerms = value;
    notifyListeners();
  }

  void onPasswordChanged(String password) {
    final next = evaluateStrength(password);
    if (next == _strength) return;
    _strength = next;
    notifyListeners();
  }

  /// Regra pura (testável) de força da senha.
  static PasswordStrength evaluateStrength(String p) {
    if (p.isEmpty) return PasswordStrength.empty;
    if (p.length < 6) return PasswordStrength.weak;
    var score = 0;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    if (score >= 3) return PasswordStrength.strong;
    if (score >= 1) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  Future<Result<void>> _register(Registration r) async {
    if (!_acceptedTerms) {
      return const Result.error(
        AppException('Aceite os termos de uso para continuar.'),
      );
    }
    return _auth.register(name: r.name, email: r.email, password: r.password);
  }
}
