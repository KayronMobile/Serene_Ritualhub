import 'package:flutter/material.dart';

import '../../../utils/result.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../view_models/login_viewmodel.dart';

/// Cadastro rápido (bottom sheet).
class RegisterSheet extends StatefulWidget {
  const RegisterSheet({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<RegisterSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.viewModel.register.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.register.removeListener(_onResult);
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onResult() {
    final r = widget.viewModel.register.result;
    if (!mounted || r == null) return;
    if (r is Error<void>) {
      showSnack(context, errorMessage(r.error));
    } else {
      Navigator.of(context).pop();
    }
    widget.viewModel.register.clearResult();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.viewModel.register.execute((
      name: _name.text,
      email: _email.text,
      password: _password.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimens.margin,
        0,
        Dimens.margin,
        MediaQuery.viewInsetsOf(context).bottom + Dimens.spaceLg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comece sua jornada', style: t.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Crie sua conta para montar rituais e desafiar sua tribo.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: Dimens.spaceLg),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Seu nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
            ),
            const SizedBox(height: Dimens.spaceMd),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
            ),
            const SizedBox(height: Dimens.spaceMd),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Senha (mín. 6 caracteres)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
            ),
            const SizedBox(height: Dimens.spaceLg),
            ListenableBuilder(
              listenable: widget.viewModel.register,
              builder: (context, _) => FilledButton(
                onPressed: widget.viewModel.register.running ? null : _submit,
                child: const Text('Criar conta e entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
