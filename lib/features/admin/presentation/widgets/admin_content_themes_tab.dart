import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../content_themes/models/content_theme.dart';
import '../../../content_themes/providers/content_themes_provider.dart';

class AdminContentThemesTab extends ConsumerWidget {
  const AdminContentThemesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themesAsync = ref.watch(contentThemesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showContentThemeForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo tema de conteúdo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: themesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (themes) {
              if (themes.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum tema cadastrado',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: themes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final theme = themes[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        theme.isActive
                            ? Icons.label_rounded
                            : Icons.label_off_rounded,
                        color: theme.isActive
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      title: Text(
                        theme.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      subtitle: theme.description != null &&
                              theme.description!.isNotEmpty
                          ? Text(
                              theme.description!,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!theme.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Inativo',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.orange),
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                size: 20, color: cs.primary),
                            onPressed: () =>
                                _showContentThemeForm(context, existing: theme),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                size: 20, color: Colors.red),
                            onPressed: () =>
                                _confirmDelete(context, theme),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, ContentTheme theme) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir tema?', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'O tema "${theme.name}" será removido. Conteúdos vinculados ficarão sem tema.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client
                  .from('content_themes')
                  .delete()
                  .eq('id', theme.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showContentThemeForm(BuildContext context, {ContentTheme? existing}) {
  final cs = Theme.of(context).colorScheme;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  bool isActive = existing?.isActive ?? true;
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              existing != null ? 'Editar tema' : 'Novo tema de conteúdo',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(hintText: 'Nome do tema'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration:
                  const InputDecoration(hintText: 'Descrição (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: isActive,
              onChanged: (v) => setSheetState(() => isActive = v),
              title: Text('Ativo',
                  style: TextStyle(color: cs.onSurface, fontSize: 14)),
              activeTrackColor: cs.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      setSheetState(() => isSaving = true);

                      final data = {
                        'name': name,
                        'description': descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        'is_active': isActive,
                      };

                      final client = Supabase.instance.client;
                      if (existing != null) {
                        await client
                            .from('content_themes')
                            .update(data)
                            .eq('id', existing.id);
                      } else {
                        await client.from('content_themes').insert(data);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(existing != null
                      ? 'Salvar alterações'
                      : 'Salvar tema'),
            ),
          ],
        ),
      ),
    ),
  );
}
