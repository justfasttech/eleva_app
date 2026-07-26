import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth_error_translator.dart';
import '../../../core/theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
            backgroundColor: ElevaColors.gold,
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
                    'Alterar senha',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ElevaColors.textDark,
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
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      hintText: 'Senha atual',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: ElevaColors.gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: ElevaColors.textMuted,
                        ),
                        onPressed: () => setSheetState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      hintText: 'Nova senha',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: ElevaColors.gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: ElevaColors.textMuted,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Confirmar nova senha',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: ElevaColors.gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: ElevaColors.textMuted,
                        ),
                        onPressed: () => setSheetState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                                color: ElevaColors.white,
                              ),
                            )
                          : const Text('Alterar senha'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nome',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElevaColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Seu nome',
                  prefixIcon:
                      Icon(Icons.person_outline, color: ElevaColors.gold),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe seu nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Sobrenome',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElevaColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _surnameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Seu sobrenome',
                  prefixIcon:
                      Icon(Icons.person_outline, color: ElevaColors.gold),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe seu sobrenome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'E-mail',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElevaColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _email,
                readOnly: true,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: ElevaColors.gold),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading || !_hasChanges ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ElevaColors.white,
                        ),
                      )
                    : const Text('Salvar'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showChangePasswordSheet,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Alterar senha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
