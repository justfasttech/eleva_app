import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth_error_translator.dart';
import '../../../core/eleva_design.dart';
import '../../profile/presentation/privacy_policy_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpSurnameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirm = true;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpSurnameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _showForgotPassword() {
    final resetEmailController = TextEditingController();
    String? errorMessage;
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EDColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recuperar senha', style: EDText.display(size: 24)),
                  const SizedBox(height: 8),
                  Text(
                    'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                    style: EDText.body(color: EDColors.inkMuted, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 18, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: EDText.body(size: 15),
                    decoration: EDDecor.input(hint: 'seu@email.com'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: EDDecor.primaryButton(),
                      onPressed: isSending
                          ? null
                          : () async {
                              final email =
                                  resetEmailController.text.trim();
                              if (email.isEmpty || !email.contains('@')) {
                                setSheetState(() => errorMessage =
                                    'Informe um e-mail válido');
                                return;
                              }

                              setSheetState(() {
                                isSending = true;
                                errorMessage = null;
                              });

                              try {
                                await Supabase.instance.client.auth
                                    .resetPasswordForEmail(
                                  email,
                                  redirectTo:
                                      'https://eleva-online.com/reset-password.html',
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Link de recuperação enviado para seu e-mail.'),
                                      backgroundColor: EDColors.blue,
                                    ),
                                  );
                                }
                              } on AuthException catch (e) {
                                if (sheetContext.mounted) {
                                  setSheetState(() {
                                    errorMessage =
                                        translateAuthError(e.message);
                                  });
                                }
                              } finally {
                                if (sheetContext.mounted) {
                                  setSheetState(() => isSending = false);
                                }
                              }
                            },
                      child: isSending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enviar link'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleMode() {
    _loginEmailController.clear();
    _loginPasswordController.clear();
    _signUpNameController.clear();
    _signUpSurnameController.clear();
    _signUpEmailController.clear();
    _signUpPasswordController.clear();
    _signUpConfirmPasswordController.clear();
    setState(() {
      _isSignUp = !_isSignUp;
      _obscureLoginPassword = true;
      _obscureSignUpPassword = true;
      _obscureSignUpConfirm = true;
    });
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translateAuthError(e.message)),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _signUpNameController.text.trim();
      final surname = _signUpSurnameController.text.trim();

      await Supabase.instance.client.auth.signUp(
        email: _signUpEmailController.text.trim(),
        password: _signUpPasswordController.text,
        data: {
          'name': name,
          'surname': surname,
          'full_name': '$name $surname',
        },
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translateAuthError(e.message)),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EDColors.navy,
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: SafeArea(
              bottom: false,
              child: _isSignUp ? _buildCompactHeader() : _buildHero(),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: EDColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _isSignUp
                            ? _buildSignUpForm()
                            : _buildLoginForm(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      key: const ValueKey('hero'),
      width: double.infinity,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _HaloPainter())),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo_lotus.png', height: 56),
              const SizedBox(height: 14),
              Text(
                'Eleva',
                style: EDText.display(
                  size: 34,
                  color: EDColors.gold,
                ).copyWith(letterSpacing: 0.6),
              ),
              const SizedBox(height: 6),
              Text(
                'Eleve sua fé, todos os dias.',
                style: EDText.body(color: EDColors.onNavyMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Padding(
      key: const ValueKey('compact'),
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 20),
      child: Row(
        children: [
          Material(
            color: EDColors.navySoft,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Voltar para entrar',
              onPressed: _toggleMode,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const Spacer(),
          Image.asset('assets/images/logo_lotus.png', height: 30),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(text, style: EDText.body(size: 13, weight: FontWeight.w700)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _eyeButton(bool obscure, VoidCallback onPressed) {
    return IconButton(
      tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: EDColors.inkMuted,
      ),
      onPressed: onPressed,
    );
  }

  Widget _submitButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: EDDecor.primaryButton(),
      onPressed: _isLoading ? null : onPressed,
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }

  Widget _switchModeRow(String question, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: EDText.body(color: EDColors.inkMuted)),
        TextButton(
          onPressed: _toggleMode,
          style: TextButton.styleFrom(foregroundColor: EDColors.blue),
          child: Text(
            action,
            style: EDText.body(weight: FontWeight.w800, color: EDColors.blue),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu e-mail';
    if (!value.contains('@')) return 'E-mail inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: AutofillGroup(
        child: Column(
          key: const ValueKey('login'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bem-vindo de volta', style: EDText.display()),
            const SizedBox(height: 4),
            Text(
              'Entre para continuar sua jornada.',
              style: EDText.body(color: EDColors.inkMuted),
            ),
            const SizedBox(height: 24),
            _fieldLabel('E-mail'),
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: EDText.body(size: 15),
              decoration: EDDecor.input(hint: 'seu@email.com'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 18),
            _fieldLabel(
              'Senha',
              trailing: GestureDetector(
                onTap: _showForgotPassword,
                child: Text(
                  'Esqueci minha senha',
                  style: EDText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: EDColors.blue,
                  ),
                ),
              ),
            ),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _login(),
              style: EDText.body(size: 15),
              decoration: EDDecor.input(
                hint: 'Sua senha',
                suffixIcon: _eyeButton(
                  _obscureLoginPassword,
                  () => setState(
                    () => _obscureLoginPassword = !_obscureLoginPassword,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 28),
            _submitButton('Entrar', _login),
            const SizedBox(height: 20),
            _switchModeRow('Não tem uma conta?', 'Cadastre-se'),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: AutofillGroup(
        child: Column(
          key: const ValueKey('signup'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Criar conta', style: EDText.display()),
            const SizedBox(height: 4),
            Text(
              'Plante a sua semente de fé hoje.',
              style: EDText.body(color: EDColors.inkMuted),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _fieldLabel('Nome'),
                      TextFormField(
                        controller: _signUpNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.givenName],
                        style: EDText.body(size: 15),
                        decoration: EDDecor.input(),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe seu nome'
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _fieldLabel('Sobrenome'),
                      TextFormField(
                        controller: _signUpSurnameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.familyName],
                        style: EDText.body(size: 15),
                        decoration: EDDecor.input(),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe seu sobrenome'
                                : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _fieldLabel('E-mail'),
            TextFormField(
              controller: _signUpEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: EDText.body(size: 15),
              decoration: EDDecor.input(hint: 'seu@email.com'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Senha'),
            TextFormField(
              controller: _signUpPasswordController,
              obscureText: _obscureSignUpPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              style: EDText.body(size: 15),
              decoration: EDDecor.input(
                hint: 'Mínimo 6 caracteres',
                suffixIcon: _eyeButton(
                  _obscureSignUpPassword,
                  () => setState(
                    () => _obscureSignUpPassword = !_obscureSignUpPassword,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _signUpPasswordController,
              builder: (context, value, _) =>
                  _PasswordStrength(password: value.text),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Confirmar senha'),
            TextFormField(
              controller: _signUpConfirmPasswordController,
              obscureText: _obscureSignUpConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signUp(),
              style: EDText.body(size: 15),
              decoration: EDDecor.input(
                hint: 'Repita a senha',
                suffixIcon: _eyeButton(
                  _obscureSignUpConfirm,
                  () => setState(
                    () => _obscureSignUpConfirm = !_obscureSignUpConfirm,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme sua senha';
                }
                if (value != _signUpPasswordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            _submitButton('Criar conta', _signUp),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Ao criar a conta, você concorda com a ',
                  style: EDText.body(size: 12, color: EDColors.inkMuted),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  ),
                  child: Text(
                    'Política de Privacidade',
                    style: EDText.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: EDColors.blue,
                    ),
                  ),
                ),
                Text(
                  '.',
                  style: EDText.body(size: 12, color: EDColors.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _switchModeRow('Já tem uma conta?', 'Entrar'),
          ],
        ),
      ),
    );
  }
}

/// Indicador simples de força da senha (3 barras).
class _PasswordStrength extends StatelessWidget {
  final String password;

  const _PasswordStrength({required this.password});

  int get _score {
    if (password.isEmpty) return 0;
    var score = password.length >= 6 ? 1 : 0;
    if (password.length >= 8 &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[A-Za-z]').hasMatch(password)) {
      score++;
    }
    if (password.length >= 10 && RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    const labels = ['Muito curta', 'Fraca', 'Média', 'Forte'];
    return Semantics(
      label: 'Força da senha: ${labels[score]}',
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i < score ? EDColors.blue : EDColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 72,
            child: Text(
              password.isEmpty ? '' : labels[score],
              style: EDText.body(
                size: 12,
                weight: FontWeight.w700,
                color: EDColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculos concêntricos atrás do logo no topo da tela de login.
class _HaloPainter extends CustomPainter {
  const _HaloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = EDColors.navyLine;
    canvas.drawCircle(center, 140, line);
    canvas.drawCircle(center, 100, line);
    canvas.drawCircle(center, 60, Paint()..color = EDColors.navySoft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
