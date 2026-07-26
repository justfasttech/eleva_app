import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../models/diary_entry.dart';
import '../utils/faith_penalty.dart';

void showNewEntrySheet(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NewEntryPage()),
  );
}

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({super.key});

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = 'neutral';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva algo antes de salvar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('diary_entries').insert({
        'user_id': userId,
        'title': _titleController.text.trim(),
        'content': content,
        'mood': _selectedMood,
      });

      final penalty = calculateContentPenalty(content);
      if (penalty < 0) {
        await Supabase.instance.client.rpc('apply_faith_penalty', params: {
          'p_user_id': userId,
          'p_amount': penalty,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        if (penalty < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reflexão salva. Você perdeu ${penalty.abs()} pontos de fé por conteúdo negativo.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reflexão salva!'),
              backgroundColor: ElevaColors.gold,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          'Nova reflexão',
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
                        final isSelected = _selectedMood == entry.key;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = entry.key),
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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Título (opcional)',
                      prefixIcon: Icon(Icons.title_rounded, color: ElevaColors.gold),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Escreva sua reflexão, testemunho ou pensamento...',
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
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ElevaColors.white,
                        ),
                      )
                    : const Text('Salvar reflexão'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
