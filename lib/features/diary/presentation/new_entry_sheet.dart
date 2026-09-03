import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../content_themes/presentation/theme_selection_screen.dart';
import '../models/diary_entry.dart';
import '../providers/scoring_words_provider.dart';
import '../utils/faith_penalty.dart';

void showNewEntrySheet(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NewEntryPage()),
  );
}

class NewEntryPage extends ConsumerStatefulWidget {
  const NewEntryPage({super.key});

  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = 'neutral';
  bool _isSaving = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateCharCount);
  }

  void _updateCharCount() {
    final count = _contentController.text.length;
    if (count != _charCount) setState(() => _charCount = count);
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateCharCount);
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

    if (_charCount > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limite de 50 caracteres excedido ($_charCount/50)'),
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

      final words = ref.read(scoringWordsProvider).value ?? [];
      final score = calculateContentScore(content, words);
      if (score != 0) {
        await Supabase.instance.client.rpc('apply_faith_penalty', params: {
          'p_user_id': userId,
          'p_amount': score,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reflexão salva!'),
            backgroundColor: ElevaColors.gold,
          ),
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ThemeSelectionScreen(contentType: 'quiz'),
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
                    minLines: 3,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      hintText: 'Escreva sua reflexão...',
                      alignLabelWithHint: true,
                      counterText: '',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_charCount/50 caracteres',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _charCount <= 50 ? Colors.green : Colors.red.shade400,
                      ),
                    ),
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
