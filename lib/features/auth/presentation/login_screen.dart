import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth_error_translator.dart';
import '../../../core/theme.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  const Text(
                    'Recuperar senha',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ElevaColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ElevaColors.textMuted,
                    ),
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
                    decoration: const InputDecoration(
                      hintText: 'E-mail',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: ElevaColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                                    .resetPasswordForEmail(email);
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Link de recuperação enviado para seu e-mail.'),
                                      backgroundColor: ElevaColors.gold,
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
                                color: ElevaColors.white,
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 160),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: _isSignUp
                        ? _buildSignUpForm()
                        : _buildLoginForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'E-mail',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: ElevaColors.gold,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu e-mail';
              }
              if (!value.contains('@')) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              hintText: 'Senha',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: ElevaColors.gold,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: ElevaColors.textMuted,
                ),
                onPressed: () {
                  setState(
                    () => _obscureLoginPassword = !_obscureLoginPassword,
                  );
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe sua senha';
              }
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(
                  color: ElevaColors.gold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ElevaColors.white,
                    ),
                  )
                : const Text('Entrar'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Não tem uma conta?',
                style: TextStyle(color: ElevaColors.textMuted),
              ),
              TextButton(
                onPressed: _toggleMode,
                child: const Text(
                  'Cadastre-se',
                  style: TextStyle(
                    color: ElevaColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        key: const ValueKey('signup'),
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _signUpNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Nome',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: ElevaColors.gold,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe seu nome';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _signUpSurnameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Sobrenome',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: ElevaColors.gold,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe seu sobrenome';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'E-mail',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: ElevaColors.gold,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu e-mail';
              }
              if (!value.contains('@')) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpPasswordController,
            obscureText: _obscureSignUpPassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Senha',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: ElevaColors.gold,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: ElevaColors.textMuted,
                ),
                onPressed: () {
                  setState(
                    () => _obscureSignUpPassword = !_obscureSignUpPassword,
                  );
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe sua senha';
              }
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpConfirmPasswordController,
            obscureText: _obscureSignUpConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _signUp(),
            decoration: InputDecoration(
              hintText: 'Confirmar senha',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: ElevaColors.gold,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: ElevaColors.textMuted,
                ),
                onPressed: () {
                  setState(
                    () => _obscureSignUpConfirm = !_obscureSignUpConfirm,
                  );
                },
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ElevaColors.white,
                    ),
                  )
                : const Text('Criar conta'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Já tem uma conta?',
                style: TextStyle(color: ElevaColors.textMuted),
              ),
              TextButton(
                onPressed: _toggleMode,
                child: const Text(
                  'Entrar',
                  style: TextStyle(
                    color: ElevaColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
