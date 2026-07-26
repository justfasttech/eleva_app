import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../utils/faith_penalty.dart';

const _months = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

class EntryDetailPage extends ConsumerStatefulWidget {
  final DiaryEntry entry;

  const EntryDetailPage({super.key, required this.entry});

  @override
  ConsumerState<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends ConsumerState<EntryDetailPage> {
  late DiaryEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir reflexão'),
        content: const Text('Tem certeza que deseja excluir esta reflexão? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await Supabase.instance.client
          .from('diary_entries')
          .delete()
          .eq('id', _entry.id);

      ref.invalidate(diaryEntriesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reflexão excluída'),
            backgroundColor: ElevaColors.gold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editEntry() {
    final titleCtrl = TextEditingController(text: _entry.title);
    final contentCtrl = TextEditingController(text: _entry.content);
    String selectedMood = _entry.mood;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Scaffold(
              backgroundColor: ElevaColors.white,
              appBar: AppBar(
                backgroundColor: ElevaColors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: ElevaColors.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Editar reflexão',
                  style: TextStyle(
                    color: ElevaColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Como você está se sentindo?',
                            style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 84,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: DiaryEntry.moods.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final entry = DiaryEntry.moods.entries.elementAt(index);
                                final isSelected = selectedMood == entry.key;
                                return GestureDetector(
                                  onTap: () => setSheetState(() => selectedMood = entry.key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? ElevaColors.gold.withValues(alpha: 0.15)
                                          : ElevaColors.offWhite,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? ElevaColors.gold : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(entry.value.emoji, style: const TextStyle(fontSize: 24)),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.value.label,
                                          style: const TextStyle(fontSize: 11, color: ElevaColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: titleCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Título (opcional)',
                              prefixIcon: Icon(Icons.title_rounded, color: ElevaColors.gold),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: contentCtrl,
                            maxLines: null,
                            minLines: 10,
                            decoration: const InputDecoration(
                              hintText: 'Escreva sua reflexão...',
                              alignLabelWithHint: true,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final content = contentCtrl.text.trim();
                          if (content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Escreva algo antes de salvar'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            await Supabase.instance.client
                                .from('diary_entries')
                                .update({
                                  'title': titleCtrl.text.trim(),
                                  'content': content,
                                  'mood': selectedMood,
                                })
                                .eq('id', _entry.id);

                            final penalty = calculateContentPenalty(content);
                            if (penalty < 0) {
                              final userId = Supabase.instance.client.auth.currentUser!.id;
                              await Supabase.instance.client.rpc('apply_faith_penalty', params: {
                                'p_user_id': userId,
                                'p_amount': penalty,
                              });
                            }

                            ref.invalidate(diaryEntriesProvider);

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            setState(() {
                              _entry = DiaryEntry(
                                id: _entry.id,
                                userId: _entry.userId,
                                title: titleCtrl.text.trim(),
                                content: content,
                                mood: selectedMood,
                                createdAt: _entry.createdAt,
                                updatedAt: DateTime.now(),
                              );
                            });
                            if (mounted) {
                              if (penalty < 0) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Reflexão atualizada. Você perdeu ${penalty.abs()} pontos de fé por conteúdo negativo.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reflexão atualizada!'),
                                    backgroundColor: ElevaColors.gold,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Salvar alterações'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElevaColors.white,
      appBar: AppBar(
        backgroundColor: ElevaColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ElevaColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reflexão',
          style: TextStyle(
            color: ElevaColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: ElevaColors.gold),
            onPressed: _editEntry,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ElevaColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _entry.moodEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _entry.moodLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_entry.createdAt.day} de ${_months[_entry.createdAt.month - 1]} de ${_entry.createdAt.year}, '
                      '${_entry.createdAt.hour.toString().padLeft(2, '0')}:${_entry.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: ElevaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_entry.title.isNotEmpty) ...[
              Text(
                _entry.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ElevaColors.textDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _entry.content,
              style: const TextStyle(
                fontSize: 16,
                color: ElevaColors.textDark,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
