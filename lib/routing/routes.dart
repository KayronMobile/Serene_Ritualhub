/// Caminhos das rotas do app.
abstract final class Routes {
  static const login = '/login';
  static const register = '/cadastro';
  static const home = '/';
  static const rituals = '/rituais';
  static const newRitual = '/rituais/novo';
  static String editRitual(String id) => '/rituais/$id/editar';
  static String player(String id) => '/player/$id';
  static const community = '/comunidade';
  static const progress = '/progresso';
  static const reminders = '/lembretes';
  static const profile = '/perfil';
}
