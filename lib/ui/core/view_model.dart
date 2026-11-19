import 'package:flutter/widgets.dart';

/// Base dos ViewModels: um [ChangeNotifier] que ignora notificações após o
/// `dispose` (evita erros quando uma operação assíncrona termina depois que
/// a tela foi fechada) e coalesce recarregamentos disparados por
/// repositórios.
abstract class ViewModel extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  bool _reloading = false;
  bool _dirty = false;

  /// Agenda [reload]; se já houver um em andamento, executa mais uma vez ao
  /// final (garante que a última mudança sempre seja refletida).
  void scheduleReload(Future<void> Function() reload) {
    if (_disposed) return;
    if (_reloading) {
      _dirty = true;
      return;
    }
    _reloading = true;
    reload().whenComplete(() {
      _reloading = false;
      if (_dirty && !_disposed) {
        _dirty = false;
        scheduleReload(reload);
      }
    });
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Cria o ViewModel uma única vez (no `initState`) e o descarta junto com a
/// tela. Evita recriar ViewModels quando o roteador reconstrói as páginas.
class ViewModelBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ViewModelBuilder({
    super.key,
    required this.create,
    required this.builder,
  });

  final T Function(BuildContext context) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends ChangeNotifier>
    extends State<ViewModelBuilder<T>> {
  late final T _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.create(context);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _viewModel);
}
