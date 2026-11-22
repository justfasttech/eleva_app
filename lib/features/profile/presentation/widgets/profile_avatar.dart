import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/eleva_design.dart';
import '../../services/avatar_service.dart';

/// Avatar com anel dourado e botão de câmera para trocar a foto.
class ProfileAvatar extends StatefulWidget {
  final String initial;
  final String? avatarUrl;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.initial,
    this.avatarUrl,
    this.size = 76,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _busy = false;

  bool get _hasPhoto => widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

  Future<void> _openOptions() async {
    if (_busy) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: EDColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EDColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text('Foto de perfil', style: EDText.display(size: 22)),
              ),
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Escolher da galeria',
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              if (!kIsWeb)
                _SheetOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Tirar foto',
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
              if (_hasPhoto)
                _SheetOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remover foto',
                  color: EDColors.danger,
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    setState(() => _busy = true);
    try {
      if (action == 'remove') {
        await AvatarService.remove();
      } else {
        final url = await AvatarService.pickAndUpload(
          action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (url == null) return; // usuário cancelou
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'remove' ? 'Foto removida.' : 'Foto de perfil atualizada.',
            ),
            backgroundColor: EDColors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao atualizar avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Não foi possível atualizar a foto. Tente novamente.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final initialText = Text(
      widget.initial,
      style: EDText.display(size: size * 0.37, color: EDColors.gold),
    );

    return Semantics(
      button: true,
      label: 'Foto de perfil. Toque para alterar',
      child: GestureDetector(
        onTap: _openOptions,
        child: SizedBox(
          width: size + 4,
          height: size + 4,
          child: Stack(
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EDColors.gold,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EDColors.navy,
                    border: Border.all(color: EDColors.surface, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_hasPhoto)
                        Image.network(
                          widget.avatarUrl!,
                          fit: BoxFit.cover,
                          // Decodifica no tamanho exibido, não no original.
                          cacheWidth: (size * 3).round(),
                          errorBuilder: (_, __, ___) => Center(child: initialText),
                          loadingBuilder: (context, child, progress) =>
                              progress == null ? child : Center(child: initialText),
                        )
                      else
                        Center(child: initialText),
                      if (_busy)
                        const ColoredBox(
                          color: Color(0x880E3A73),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EDColors.gold,
                    border: Border.all(color: EDColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 14,
                    color: EDColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = EDColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color == EDColors.ink ? EDColors.blue : color),
      title: Text(label, style: EDText.body(size: 15, weight: FontWeight.w700, color: color)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}
