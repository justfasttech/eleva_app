import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../community/models/post_theme.dart';
import '../../../community/providers/themes_provider.dart';
import '../../../diary/models/scoring_word.dart';
import '../../../diary/providers/scoring_words_provider.dart';
import '../widgets/admin_content_themes_tab.dart';
import '../widgets/admin_tree_messages_tab.dart';

class AdminConfigPage extends StatefulWidget {
  const AdminConfigPage({super.key});

  @override
  State<AdminConfigPage> createState() => _AdminConfigPageState();
}

class _AdminConfigPageState extends State<AdminConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'Configuracoes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                indicator: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Temas Posts'),
                  Tab(text: 'Temas Conteudo'),
                  Tab(text: 'Cotacao'),
                  Tab(text: 'Msg Arvore'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ThemesTab(),
                AdminContentThemesTab(),
                _ScoringWordsTab(),
                AdminTreeMessagesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemesTab extends ConsumerWidget {
  const _ThemesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themesAsync = ref.watch(postThemesProvider);

    return Column(
      children: [
        _AddButton(
          label: 'Novo tema',
          onTap: () => _showThemeForm(context),
        ),
        Expanded(
          child: themesAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: cs.primary)),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (themes) {
              if (themes.isEmpty) {
                return const Center(
                  child: Text('Nenhum tema cadastrado',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: themes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = themes[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.label_rounded,
                              size: 18, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showThemeForm(context, existing: t),
                          icon: Icon(Icons.edit_rounded,
                              size: 18, color: cs.onSurfaceVariant),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          onPressed: () =>
                              _confirmDeleteTheme(context, t),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
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

  void _confirmDeleteTheme(BuildContext context, PostTheme theme) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir tema?', style: TextStyle(color: cs.onSurface)),
        content: Text(
            '"${theme.name}" sera removido. Posts com este tema ficarao sem tema.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client
                  .from('post_themes')
                  .delete()
                  .eq('id', theme.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ScoringWordsTab extends ConsumerStatefulWidget {
  const _ScoringWordsTab();

  @override
  ConsumerState<_ScoringWordsTab> createState() => _ScoringWordsTabState();
}

class _ScoringWordsTabState extends ConsumerState<_ScoringWordsTab> {
  final _diaryPenaltyCtrl = TextEditingController();
  final _inactivityPenaltyCtrl = TextEditingController();
  bool _configLoaded = false;
  bool _penaltiesExpanded = false;

  @override
  void dispose() {
    _diaryPenaltyCtrl.dispose();
    _inactivityPenaltyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (_configLoaded) return;
    try {
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value')
          .inFilter('key', ['diary_penalty', 'inactivity_penalty']);
      for (final row in rows) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        if (key == 'diary_penalty') _diaryPenaltyCtrl.text = value;
        if (key == 'inactivity_penalty') _inactivityPenaltyCtrl.text = value;
      }
    } catch (_) {}
    _configLoaded = true;
  }

  Future<void> _saveConfigValue(String key, String value) async {
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    await Supabase.instance.client.from('app_config').upsert(
      {'key': key, 'value': value},
      onConflict: 'key',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salvo'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wordsAsync = ref.watch(scoringWordsProvider);

    return FutureBuilder(
      future: _loadConfig(),
      builder: (context, _) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                initiallyExpanded: _penaltiesExpanded,
                onExpansionChanged: (v) => _penaltiesExpanded = v,
                title: Text(
                  'Penalidades',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _diaryPenaltyCtrl,
                          decoration: InputDecoration(
                            labelText: 'Diário ausente',
                            helperStyle: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 11),
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          onSubmitted: (v) =>
                              _saveConfigValue('diary_penalty', v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _saveConfigValue(
                            'diary_penalty', _diaryPenaltyCtrl.text),
                        icon: Icon(Icons.save_rounded,
                            size: 20, color: cs.primary),
                        tooltip: 'Salvar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inactivityPenaltyCtrl,
                          decoration: InputDecoration(
                            labelText: 'Inatividade (3+ dias)',
                            helperStyle: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 11),
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          onSubmitted: (v) =>
                              _saveConfigValue('inactivity_penalty', v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _saveConfigValue(
                            'inactivity_penalty',
                            _inactivityPenaltyCtrl.text),
                        icon: Icon(Icons.save_rounded,
                            size: 20, color: cs.primary),
                        tooltip: 'Salvar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _AddButton(
          label: 'Nova palavra',
          onTap: () => _showScoringWordForm(context),
        ),
        Expanded(
          child: wordsAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: cs.primary)),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (words) {
              if (words.isEmpty) {
                return const Center(
                  child: Text('Nenhuma palavra cadastrada',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }

              final sorted = List<ScoringWord>.from(words)
                ..sort((a, b) => b.points.compareTo(a.points));

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final w = sorted[i];
                  final isPositive = w.points > 0;
                  final color = isPositive ? Colors.green : Colors.red;
                  final ptsStr = w.points == w.points.truncateToDouble()
                      ? w.points.toInt().toString()
                      : w.points.toStringAsFixed(2);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${isPositive ? "+" : ""}$ptsStr',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            w.word,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showScoringWordForm(
                              context,
                              existing: w),
                          icon: Icon(Icons.edit_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          onPressed: () =>
                              _confirmDeleteScoringWord(context, w),
                          icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  void _confirmDeleteScoringWord(BuildContext context, ScoringWord word) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title:
            Text('Excluir palavra?', style: TextStyle(color: cs.onSurface)),
        content: Text(
            '"${word.word}" (${word.points > 0 ? "+${word.points == word.points.truncateToDouble() ? word.points.toInt() : word.points}" : "${word.points == word.points.truncateToDouble() ? word.points.toInt() : word.points}"}) sera removida.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client
                  .from('scoring_words')
                  .delete()
                  .eq('id', word.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showThemeForm(BuildContext context, {PostTheme? existing}) {
  final cs = Theme.of(context).colorScheme;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
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
              existing != null ? 'Editar tema' : 'Novo tema',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(
                hintText: 'Nome do tema (ex: Oracao, Testemunho)',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      setSheetState(() => isSaving = true);

                      final client = Supabase.instance.client;
                      if (existing != null) {
                        await client
                            .from('post_themes')
                            .update({'name': name})
                            .eq('id', existing.id);
                      } else {
                        await client
                            .from('post_themes')
                            .insert({'name': name});
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
                      ? 'Salvar alteracoes'
                      : 'Salvar tema'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showScoringWordForm(BuildContext context, {ScoringWord? existing}) {
  final cs = Theme.of(context).colorScheme;
  final wordCtrl = TextEditingController(text: existing?.word ?? '');
  final pointsCtrl =
      TextEditingController(text: (existing?.points ?? 1).toString());
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
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing != null ? 'Editar palavra' : 'Nova palavra',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: wordCtrl,
              decoration: InputDecoration(
                labelText: 'Palavra',
                prefixIcon: Icon(Icons.text_fields_rounded, color: cs.primary),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: pointsCtrl,
              decoration: InputDecoration(
                labelText: 'Pontos (positivo ou negativo)',
                prefixIcon: Icon(Icons.exposure_rounded, color: cs.primary),
                helperText: 'Ex: 3 para bonus, -3 para penalidade',
                helperStyle: TextStyle(color: cs.onSurfaceVariant),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final word = wordCtrl.text.trim();
                        final points =
                            double.tryParse(pointsCtrl.text.trim()) ?? 0.0;
                        if (word.isEmpty || points == 0) return;

                        setSheetState(() => isSaving = true);
                        try {
                          if (existing != null) {
                            await Supabase.instance.client
                                .from('scoring_words')
                                .update({'word': word, 'points': points})
                                .eq('id', existing.id);
                          } else {
                            await Supabase.instance.client
                                .from('scoring_words')
                                .insert({'word': word, 'points': points});
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text('Erro: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setSheetState(() => isSaving = false);
                          }
                        }
                      },
                child: Text(existing != null ? 'Salvar' : 'Adicionar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Material(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20, color: primary),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
