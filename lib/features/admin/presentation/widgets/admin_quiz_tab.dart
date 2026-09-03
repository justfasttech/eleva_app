import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../content_themes/providers/content_themes_provider.dart';
import '../../../quiz/models/quiz.dart';
import '../../../quiz/providers/quiz_provider.dart';

class AdminQuizTab extends ConsumerStatefulWidget {
  const AdminQuizTab({super.key});

  @override
  ConsumerState<AdminQuizTab> createState() => _AdminQuizTabState();
}

class _AdminQuizTabState extends ConsumerState<AdminQuizTab> {
  String? _selectedThemeId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final quizzesAsync = ref.watch(quizzesProvider);
    final themesAsync = ref.watch(contentThemesProvider);
    final themes = themesAsync.value ?? [];

    String themeName(String themeId) {
      final t = themes.where((t) => t.id == themeId);
      return t.isNotEmpty ? t.first.name : '---';
    }

    return Column(
      children: [
        _AddButton(
          label: 'Novo quiz',
          onTap: () => _showQuizForm(context, ref),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DropdownButtonFormField<String>(
            value: _selectedThemeId,
            dropdownColor: cs.surface,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Filtrar por tema',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _selectedThemeId != null
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      onPressed: () =>
                          setState(() => _selectedThemeId = null),
                    )
                  : null,
            ),
            items: themes
                .map((t) =>
                    DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedThemeId = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: quizzesAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: cs.primary)),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (quizzes) {
              final filtered = _selectedThemeId != null
                  ? quizzes
                      .where((q) => q.themeId == _selectedThemeId)
                      .toList()
                  : quizzes;
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                      _selectedThemeId != null
                          ? 'Nenhum quiz neste tema'
                          : 'Nenhum quiz cadastrado',
                      style: TextStyle(
                          fontSize: 14, color: cs.onSurfaceVariant)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final q = filtered[i];
                  return _QuizAdminCard(
                    quiz: q,
                    themeName: themeName(q.themeId),
                    onEdit: () => _showQuizForm(context, ref, existing: q),
                    onManageQuestions: () =>
                        _openQuestionsManager(context, q),
                    onDelete: () => _confirmDelete(context, q),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Quiz quiz) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir quiz?', style: TextStyle(color: cs.onSurface)),
        content: Text(
            '"${quiz.title}" e todas as perguntas serão removidos.',
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
              try {
                await Supabase.instance.client
                    .from('quizzes')
                    .delete()
                    .eq('id', quiz.id);
                ref.invalidate(quizzesProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir quiz: $e')),
                  );
                }
              }
            },
            child:
                const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showQuizForm(BuildContext context, WidgetRef ref,
      {Quiz? existing}) {
    final cs = Theme.of(context).colorScheme;
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    String? selectedThemeId =
        existing?.themeId.isEmpty == true ? null : existing?.themeId;
    bool isPublished = existing?.isPublished ?? true;
    bool isSaving = false;
    final themes = ref.read(contentThemesProvider).value ?? [];

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
          child: SingleChildScrollView(
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
                  existing != null ? 'Editar quiz' : 'Novo quiz',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration:
                      const InputDecoration(hintText: 'Título do quiz'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedThemeId,
                  dropdownColor: cs.surface,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                  decoration:
                      const InputDecoration(hintText: 'Tema do quiz'),
                  items: themes
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedThemeId = v);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isPublished,
                  onChanged: (v) =>
                      setSheetState(() => isPublished = v),
                  title: Text('Publicado',
                      style:
                          TextStyle(color: cs.onSurface, fontSize: 14)),
                  activeTrackColor: cs.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty || selectedThemeId == null) {
                              return;
                            }

                            setSheetState(() => isSaving = true);

                            final data = {
                              'title': title,
                              'theme_id': selectedThemeId,
                              'is_published': isPublished,
                            };

                            final client = Supabase.instance.client;
                            if (existing != null) {
                              await client
                                  .from('quizzes')
                                  .update(data)
                                  .eq('id', existing.id);
                              ref.invalidate(quizzesProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } else {
                              final res = await client
                                  .from('quizzes')
                                  .insert(data)
                                  .select()
                                  .single();
                              ref.invalidate(quizzesProvider);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                final newQuiz = Quiz.fromMap(res);
                                _openQuestionsManager(ctx, newQuiz);
                              }
                            }
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
                            : 'Criar quiz'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuestionsManager(BuildContext context, Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizQuestionsManagerScreen(
            quizId: quiz.id, quizTitle: quiz.title),
      ),
    );
  }
}

class _QuizQuestionsManagerScreen extends ConsumerWidget {
  final String quizId;
  final String quizTitle;
  const _QuizQuestionsManagerScreen(
      {required this.quizId, required this.quizTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final quizAsync = ref.watch(quizWithQuestionsProvider(quizId));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'Perguntas: $quizTitle',
          style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showQuestionForm(context, ref, quizId),
        child: const Icon(Icons.add),
      ),
      body: quizAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: cs.primary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (quiz) {
          final questions = quiz.questions;
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_rounded,
                      size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Nenhuma pergunta cadastrada',
                      style: TextStyle(
                          fontSize: 14, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(
                      'Cada quiz deve ter 5 perguntas com 4 opções cada',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: questions.length == 5
                      ? Colors.green.withValues(alpha: 0.12)
                      : cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${questions.length}/5 perguntas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        questions.length == 5 ? Colors.green : cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(questions.length, (i) {
                final q = questions[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color:
                                  cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              q.questionText,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showQuestionForm(
                                context, ref, quizId,
                                existing: q),
                            icon: Icon(Icons.edit_rounded,
                                size: 18,
                                color: cs.onSurfaceVariant),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            onPressed: () => _confirmDeleteQuestion(
                                context, ref, q),
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Acerto: +${q.faithPointsCorrect} · Erro: ${q.faithPointsWrong}',
                        style:
                            TextStyle(fontSize: 11, color: cs.primary),
                      ),
                      const SizedBox(height: 8),
                      ..._buildOptionsList(cs, q),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOptionsList(ColorScheme cs, QuizQuestion q) {
    final keys = ['a', 'b', 'c', 'd'];
    return keys
        .map((key) {
          final isCorrect = key == q.correctOption;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: isCorrect ? Colors.green : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${key.toUpperCase()}) ',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
                Expanded(
                  child: Text(
                    q.optionText(key),
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface,
                      fontWeight: isCorrect
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        })
        .toList();
  }

  void _confirmDeleteQuestion(
      BuildContext context, WidgetRef ref, QuizQuestion question) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir pergunta?',
            style: TextStyle(color: cs.onSurface)),
        content: Text('A pergunta será removida permanentemente.',
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
                  .from('quiz_questions')
                  .delete()
                  .eq('id', question.id);
              ref.invalidate(quizWithQuestionsProvider(quizId));
              ref.invalidate(quizzesProvider);
            },
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showQuestionForm(BuildContext context, WidgetRef ref, String quizId,
    {QuizQuestion? existing}) {
  final cs = Theme.of(context).colorScheme;
  final questionCtrl =
      TextEditingController(text: existing?.questionText ?? '');
  final optACtrl = TextEditingController(text: existing?.optionA ?? '');
  final optBCtrl = TextEditingController(text: existing?.optionB ?? '');
  final optCCtrl = TextEditingController(text: existing?.optionC ?? '');
  final optDCtrl = TextEditingController(text: existing?.optionD ?? '');
  final pointsCorrectCtrl = TextEditingController(
      text: (existing?.faithPointsCorrect ?? 1.0).toString());
  final pointsWrongCtrl = TextEditingController(
      text: (existing?.faithPointsWrong ?? 0.0).toString());
  String correctOption = existing?.correctOption ?? 'a';
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
        child: SingleChildScrollView(
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
                existing != null ? 'Editar pergunta' : 'Nova pergunta',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration:
                    const InputDecoration(hintText: 'Texto da pergunta'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Text(
                'Opções (selecione a correta):',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 10),
              ...[
                ('a', 'A', optACtrl),
                ('b', 'B', optBCtrl),
                ('c', 'C', optCCtrl),
                ('d', 'D', optDCtrl),
              ].map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: entry.$1,
                          groupValue: correctOption,
                          onChanged: (v) =>
                              setSheetState(() => correctOption = v!),
                          activeColor: Colors.green,
                        ),
                        Text('${entry.$2})',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: entry.$3,
                            style: TextStyle(
                                color: cs.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Opção ${entry.$2}',
                              isDense: true,
                            ),
                            textCapitalization:
                                TextCapitalization.sentences,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pontos de Fé',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pointsCorrectCtrl,
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Ao acertar',
                              helperText: 'Ex: 1.5',
                              helperStyle: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11),
                              isDense: true,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    signed: true, decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pointsWrongCtrl,
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Ao errar',
                              helperText: 'Valor será negativo',
                              helperStyle: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11),
                              isDense: true,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    signed: true, decimal: true),
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                final neg = '-$val';
                                pointsWrongCtrl.value = TextEditingValue(
                                  text: neg,
                                  selection: TextSelection.collapsed(
                                      offset: neg.length),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final qText = questionCtrl.text.trim();
                          final oA = optACtrl.text.trim();
                          final oB = optBCtrl.text.trim();
                          final oC = optCCtrl.text.trim();
                          final oD = optDCtrl.text.trim();
                          if (qText.isEmpty ||
                              oA.isEmpty ||
                              oB.isEmpty ||
                              oC.isEmpty ||
                              oD.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Preencha a pergunta e todas as opções'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setSheetState(() => isSaving = true);

                          try {
                            final client = Supabase.instance.client;
                            final data = {
                              'quiz_id': quizId,
                              'question_text': qText,
                              'option_a': oA,
                              'option_b': oB,
                              'option_c': oC,
                              'option_d': oD,
                              'correct_option': correctOption,
                              'order_index':
                                  existing?.orderIndex ?? 0,
                              'faith_points_correct':
                                  double.tryParse(
                                          pointsCorrectCtrl.text
                                              .trim()) ??
                                      1.0,
                              'faith_points_wrong':
                                  -((double.tryParse(
                                              pointsWrongCtrl.text
                                                  .trim()) ??
                                          0.0)
                                      .abs()),
                            };

                            if (existing != null) {
                              await client
                                  .from('quiz_questions')
                                  .update(data)
                                  .eq('id', existing.id);
                            } else {
                              await client
                                  .from('quiz_questions')
                                  .insert(data);
                            }

                            ref.invalidate(
                                quizWithQuestionsProvider(quizId));
                            ref.invalidate(quizzesProvider);
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
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(existing != null
                          ? 'Salvar alterações'
                          : 'Adicionar pergunta'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QuizAdminCard extends StatelessWidget {
  final Quiz quiz;
  final String themeName;
  final VoidCallback onEdit;
  final VoidCallback onManageQuestions;
  final VoidCallback onDelete;

  const _QuizAdminCard({
    required this.quiz,
    required this.themeName,
    required this.onEdit,
    required this.onManageQuestions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onManageQuestions,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.quiz_rounded, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      '$themeName · ${quiz.questions.length} pergunta${quiz.questions.length != 1 ? "s" : ""} · ${quiz.isPublished ? "Publicado" : "Rascunho"}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
