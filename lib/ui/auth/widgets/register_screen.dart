import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/auth/auth_repository_local.dart';
import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../view_models/register_viewmodel.dart';

/// Tela de cadastro com nome, e-mail e senha.
///
/// View "burra": lê o estado do [RegisterViewModel] e dispara seus comandos.
/// Ao criar a conta, a sessão é iniciada pelo repositório e o roteador leva
/// o usuário para a Home.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.viewModel});

  final RegisterViewModel viewModel;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  RegisterViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.register.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant RegisterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.register.removeListener(_onResult);
      vm.register.addListener(_onResult);
    }
  }

  @override
  void dispose() {
    vm.register.removeListener(_onResult);
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onResult() {
    final r = vm.register.result;
    if (!mounted || r == null) return;
    if (r is Error<void>) {
      showSnack(context, errorMessage(r.error));
      vm.register.clearResult();
    }
    // Sucesso: o redirect do roteador navega para a Home.
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    vm.register.execute((
      name: _name.text,
      email: _email.text,
      password: _password.text,
    ));
  }

  void _goToLogin() =>
      context.canPop() ? context.pop() : context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Voltar ao login',
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToLogin,
        ),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Dimens.margin,
                Dimens.spaceSm,
                Dimens.margin,
                Dimens.spaceXl,
              ),
              children: [
                Center(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: Dimens.spaceMd),
                Text(
                  'Comece sua jornada',
                  style: t.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimens.spaceXs),
                Text(
                  'Crie sua conta para montar rituais, acompanhar sua '
                  'sequência e desafiar sua tribo.',
                  style: t.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimens.spaceLg),
                SereneCard(
                  padding: const EdgeInsets.all(Dimens.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          hintText: 'Como quer ser chamado(a)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Informe seu nome'
                            : null,
                      ),
                      const SizedBox(height: Dimens.spaceMd),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'voce@exemplo.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) =>
                            AuthRepositoryLocal.emailPattern.hasMatch(
                              (v ?? '').trim().toLowerCase(),
                            )
                            ? null
                            : 'E-mail inválido',
                      ),
                      const SizedBox(height: Dimens.spaceMd),
                      TextFormField(
                        controller: _password,
                        obscureText: vm.obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: vm.onPasswordChanged,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Mínimo de 6 caracteres',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: vm.obscurePassword
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            icon: Icon(
                              vm.obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: vm.toggleObscure,
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mínimo de 6 caracteres'
                            : null,
                      ),
                      _StrengthMeter(strength: vm.strength),
                      const SizedBox(height: Dimens.spaceMd),
                      TextFormField(
                        controller: _confirm,
                        obscureText: vm.obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (v) => v != _password.text
                            ? 'As senhas não coincidem'
                            : null,
                      ),
                      const SizedBox(height: Dimens.spaceSm),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: vm.acceptedTerms,
                        onChanged: (v) => vm.setAcceptedTerms(v ?? false),
                        title: Text(
                          'Li e aceito os termos de uso e a política de '
                          'privacidade',
                          style: t.bodySmall,
                        ),
                      ),
                      const SizedBox(height: Dimens.spaceSm),
                      ListenableBuilder(
                        listenable: vm.register,
                        builder: (context, _) => FilledButton.icon(
                          onPressed: vm.register.running || !vm.acceptedTerms
                              ? null
                              : _submit,
                          icon: vm.register.running
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.spa_outlined),
                          label: const Text('Criar conta e entrar'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimens.spaceLg),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Já tem uma conta? ',
                        style: t.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToLogin,
                        child: Text(
                          'Entrar',
                          style: t.bodyLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();
    final color = switch (strength) {
      PasswordStrength.weak => AppColors.error,
      PasswordStrength.medium => AppColors.secondary,
      _ => AppColors.primary,
    };
    return Padding(
      padding: const EdgeInsets.only(top: Dimens.spaceSm),
      child: Row(
        children: [
          for (var i = 1; i <= 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= strength.level ? color : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: 4),
          ],
          const SizedBox(width: Dimens.spaceSm),
          Text(
            strength.label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
