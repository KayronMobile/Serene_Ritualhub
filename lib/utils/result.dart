/// Tipo utilitário para tratamento de erros, conforme o padrão "Result"
/// do guia de arquitetura do Flutter
/// (https://docs.flutter.dev/app-architecture/design-patterns/result).
///
/// Repositórios e serviços retornam `Result` em vez de lançar exceções,
/// forçando a camada de UI a tratar explicitamente o caso de erro.
///
/// ```dart
/// switch (result) {
///   case Ok(): print(result.value);
///   case Error(): print(result.error);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Cria uma instância de [Result] contendo um valor.
  const factory Result.ok(T value) = Ok._;

  /// Cria uma instância de [Result] contendo um erro.
  const factory Result.error(Exception error) = Error._;
}

/// Subclasse de [Result] com valor.
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// Subclasse de [Result] com erro.
final class Error<T> extends Result<T> {
  const Error._(this.error);

  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}

/// Exceção de domínio com mensagem amigável para a UI.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
