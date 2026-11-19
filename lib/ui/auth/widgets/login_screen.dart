import 'package:flutter/material.dart';

import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../view_models/login_viewmodel.dart';
import 'register_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.login.addListener(_onLoginResult);
    vm.biometricLogin.addListener(_onBiometricResult);
    vm.load.addListener(_onLoaded);
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.login.removeListener(_onLoginResult);
      oldWidget.viewModel.biometricLogin.removeListener(_onBiometricResult);
      oldWidget.viewModel.load.removeListener(_onLoaded);
      vm.login.addListener(_onLoginResult);
      vm.biometricLogin.addListener(_onBiometricResult);
      vm.load.addListener(_onLoaded);
    }
  }

  @override
  void dispose() {
    vm.login.removeListener(_onLoginResult);
    vm.biometricLogin.removeListener(_onBiometricResult);
    vm.load.removeListener(_onLoaded);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onLoaded() {
    if (vm.load.completed && _email.text.isEmpty) {
      _email.text = vm.rememberedEmail ?? '';
    }
  }

  void _onLoginResult() => _handle(vm.login);

  void _onBiometricResult() => _handle(vm.biometricLogin);

  void _handle(Command<void> command) {
    final result = command.result;
    if (result is Error<void> && mounted) {
      showSnack(context, errorMessage(result.error));
      command.clearResult();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    vm.login.execute((email: _email.text, password: _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.person_outline, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.margin,
              Dimens.spaceSm,
              Dimens.margin,
              Dimens.spaceXl,
            ),
            children: [
              const _Hero(),
              const SizedBox(height: Dimens.spaceLg),
              Center(
                child: PillBadge(
                  label: 'MOMENTO PRESENTE',
                  background: AppColors.primaryFixed,
                  foreground: AppColors.primary,
                ),
              ),
              const SizedBox(height: Dimens.spaceMd),
              Text(
                'Que bom te ver de volta',
                textAlign: TextAlign.center,
                style: t.displayMedium,
              ),
              const SizedBox(height: Dimens.spaceSm),
              Text(
                'Respire fundo e retome sua jornada de rituais e equilíbrio '
                'diário.',
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: Dimens.spaceLg),
              SereneCard(
                radius: Dimens.radiusLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('E-mail ou nome de usuário'),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          hintText: 'ex: lucas@serene.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe seu e-mail'
                            : null,
                      ),
                      const SizedBox(height: Dimens.spaceMd),
                      _FieldLabel('Senha de acesso'),
                      TextFormField(
                        controller: _password,
                        obscureText: vm.obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: vm.toggleObscure,
                            icon: Icon(
                              vm.obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mínimo de 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: Dimens.spaceSm),
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: vm.toggleRememberMe,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: vm.rememberMe
                                          ? AppColors.primaryContainer
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: AppColors.primaryContainer,
                                        width: 2,
                                      ),
                                    ),
                                    child: vm.rememberMe
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: AppColors.onPrimary,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Lembrar de mim', style: t.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => showSnack(
                              context,
                              'No modo local, sua senha fica apenas neste '
                              'aparelho. Use "Cadastre-se" para redefini-la.',
                            ),
                            child: const Text('Esqueceu a senha?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimens.spaceSm),
                      ListenableBuilder(
                        listenable: vm.login,
                        builder: (context, _) => DecoratedBox(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                            boxShadow: Dimens.floatingShadow,
                          ),
                          child: FilledButton(
                            onPressed: vm.login.running ? null : _submit,
                            child: vm.login.running
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Entrar no Serene'),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimens.spaceMd),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainer,
                          foregroundColor: AppColors.primaryContainer,
                        ),
                        onPressed: vm.biometricLogin.running
                            ? null
                            : () {
                                if (!vm.biometricsAvailable) {
                                  showSnack(
                                    context,
                                    'Entre uma vez com "Lembrar de mim" ativo '
                                    'para liberar a biometria.',
                                  );
                                  return;
                                }
                                vm.biometricLogin.execute();
                              },
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Entrar com Biometria'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimens.spaceLg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OU CONTINUE COM SUA TRIBO',
                      style: t.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: Dimens.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.apple,
                      label: 'Apple',
                      onTap: () => _socialUnavailable(context),
                    ),
                  ),
                  const SizedBox(width: Dimens.gutter),
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      onTap: () => _socialUnavailable(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spaceLg),
              SereneCard(
                color: AppColors.surfaceContainer,
                shadow: false,
                radius: Dimens.radiusLg,
                padding: const EdgeInsets.all(Dimens.spaceMd),
                child: Row(
                  children: [
                    const IconBadge(
                      icon: Icons.local_fire_department_outlined,
                      background: AppColors.secondaryFixed,
                      foreground: AppColors.secondary,
                      size: 48,
                    ),
                    const SizedBox(width: Dimens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RITMO DA COMUNIDADE',
                            style: t.labelSmall?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sua tribo está construindo consistência juntos, '
                            'um dia de cada vez.',
                            style: t.bodyMedium,
                          ),
                        ],
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
                      'Ainda não tem uma conta? ',
                      style: t.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => RegisterSheet(viewModel: vm),
                      ),
                      child: Text(
                        'Cadastre-se gratuitamente',
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
    );
  }

  void _socialUnavailable(BuildContext context) => showSnack(
    context,
    'Login social requer um backend (ex.: Firebase Auth). Disponível ao '
    'conectar um AuthRepository remoto.',
  );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryFixed.withValues(alpha: 0.7),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLow,
            ),
            child: const Icon(Icons.spa_outlined, size: 44, color: AppColors.primary),
          ),
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer,
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                size: 20,
                color: AppColors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SereneCard(
    padding: const EdgeInsets.symmetric(vertical: 14),
    radius: 999,
    onTap: onTap,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.onSurface),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}
