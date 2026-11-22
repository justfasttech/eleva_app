import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth_error_translator.dart';
import '../../../core/eleva_design.dart';
import '../../auth/providers/user_profile_provider.dart';
import 'widgets/profile_avatar.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final String _email;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    _email = user?.email ?? '';
    final name = meta?['name'] as String? ?? '';
    final surname = meta?['surname'] as String? ?? '';

    _nameController = TextEditingController(text: name);
    _surnameController = TextEditingController(text: surname);

    _nameController.addListener(_onChanged);
    _surnameController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final surname = _surnameController.text.trim();

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'surname': surname,
            'full_name': '$name $surname',
          },
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil salvo com sucesso!'),
            backgroundColor: EDColors.blue,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isChanging = false;
    String? errorMessage;

    Widget passwordField({
      required String label,
      required TextEditingController controller,
      required bool obscure,
      required VoidCallback onToggle,
      Iterable<String>? autofill,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: EDText.body(size: 13, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure,
            autofillHints: autofill,
            style: EDText.body(size: 15),
            decoration: EDDecor.input(
              suffixIcon: IconButton(
                tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: EDColors.inkMuted,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ],
      );
    }

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
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alterar senha', style: EDText.display(size: 24)),
                  const SizedBox(height: 6),
                  Text(
                    'Confirme a senha atual e escolha uma nova com pelo menos 6 caracteres.',
                    style: EDText.body(color: EDColors.inkMuted, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage != null) ...[
                    EDErrorBanner(errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  passwordField(
                    label: 'Senha atual',
                    controller: currentPasswordController,
                    obscure: obscureCurrent,
                    autofill: const [AutofillHints.password],
                    onToggle: () => setSheetState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 16),
                  passwordField(
                    label: 'Nova senha',
                    controller: newPasswordController,
                    obscure: obscureNew,
                    autofill: const [AutofillHints.newPassword],
                    onToggle: () => setSheetState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 16),
                  passwordField(
                    label: 'Confirmar nova senha',
                    controller: confirmPasswordController,
                    obscure: obscureConfirm,
                    onToggle: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: EDDecor.primaryButton(),
                      onPressed: isChanging
                          ? null
                          : () async {
                              final currentPass =
                                  currentPasswordController.text;
                              final newPass = newPasswordController.text;
                              final confirmPass =
                                  confirmPasswordController.text;

                              if (currentPass.isEmpty) {
                                setSheetState(() => errorMessage =
                                    'Informe sua senha atual');
                                return;
                              }

                              if (newPass.length < 6) {
                                setSheetState(() => errorMessage =
                                    'A nova senha deve ter no mínimo 6 caracteres');
                                return;
                              }

                              if (newPass != confirmPass) {
                                setSheetState(() => errorMessage =
                                    'As senhas não coincidem');
                                return;
                              }

                              setSheetState(() {
                                isChanging = true;
                                errorMessage = null;
                              });

                              try {
                                final supabase =
                                    Supabase.instance.client;
                                final email =
                                    supabase.auth.currentUser?.email ?? '';

                                await supabase.auth
                                    .signInWithPassword(
                                  email: email,
                                  password: currentPass,
                                );

                                await supabase.auth.updateUser(
                                  UserAttributes(password: newPass),
                                );

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Senha alterada com sucesso!'),
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
                              } catch (e) {
                                if (sheetContext.mounted) {
                                  setSheetState(() {
                                    errorMessage =
                                        translateAuthError(e.toString());
                                  });
                                }
                              } finally {
                                if (sheetContext.mounted) {
                                  setSheetState(
                                      () => isChanging = false);
                                }
                              }
                            },
                      child: isChanging
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Alterar senha'),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: EDText.body(size: 13, weight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _email.split('@').first;

    return Scaffold(
      backgroundColor: EDColors.surface,
      appBar: EDDecor.appBar(context, 'Editar perfil'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ProfileAvatar(
                        initial: displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        avatarUrl: profile?.avatarUrl,
                        size: 112,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Toque na foto para alterar',
                      textAlign: TextAlign.center,
                      style: EDText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: EDColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: EDDecor.card(radius: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Nome'),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.givenName],
                            style: EDText.body(size: 15),
                            decoration: EDDecor.input(hint: 'Seu nome'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Informe seu nome'
                                    : null,
                          ),
                          const SizedBox(height: 18),
                          _label('Sobrenome'),
                          TextFormField(
                            controller: _surnameController,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.familyName],
                            style: EDText.body(size: 15),
                            decoration: EDDecor.input(hint: 'Seu sobrenome'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Informe seu sobrenome'
                                    : null,
                          ),
                          const SizedBox(height: 18),
                          _label('E-mail'),
                          TextFormField(
                            initialValue: _email,
                            enabled: false,
                            style: EDText.body(size: 15, color: EDColors.inkMuted),
                            decoration: EDDecor.input().copyWith(
                              fillColor: EDColors.divider,
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: EDColors.hint,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'O e-mail não pode ser alterado.',
                            style: EDText.body(size: 12, color: EDColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: EDColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: EDColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _showChangePasswordSheet,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, color: EDColors.blue),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Alterar senha',
                                    style: EDText.body(weight: FontWeight.w700),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: EDColors.hint),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: EDDecor.primaryButton(),
                      onPressed: _isLoading || !_hasChanges ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
