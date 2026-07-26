import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../../home/providers/faith_history_provider.dart';
import '../../home/providers/faith_history_recorder.dart';
import '../models/spiritual_reading.dart';

class ReadingDetailScreen extends ConsumerStatefulWidget {
  final SpiritualReading reading;
  final bool isAdmin;

  const ReadingDetailScreen({super.key, required this.reading, this.isAdmin = false});

  @override
  ConsumerState<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends ConsumerState<ReadingDetailScreen> {
  bool _completed = false;

  Future<void> _markCompleted() async {
    if (_completed) return;
    setState(() => _completed = true);

    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;

    final points = widget.reading.faithPoints;
    final newPending = profile.pendingFaith + points;
    final projectedFaith = (profile.faithLevel + newPending).clamp(0, 70);

    await Supabase.instance.client
        .from('profiles')
        .update({'pending_faith': newPending})
        .eq('id', profile.id);

    await recordFaithSnapshot(profile.id, projectedFaith);
    ref.invalidate(faithHistoryProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leitura concluída!'),
          backgroundColor: ElevaColors.gold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = widget.reading;

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: ElevaColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          reading.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ElevaColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reading.reference != null) ...[
                      Text(
                        reading.reference!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ElevaColors.gold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (reading.author != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: ElevaColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: ElevaColors.gold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            reading.author!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: ElevaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: ElevaColors.offWhite, height: 1),
                      const SizedBox(height: 20),
                    ],
                    SelectableText(
                      reading.content,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.8,
                        color: ElevaColors.textDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.isAdmin)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completed ? null : _markCompleted,
                  icon: Icon(_completed ? Icons.check_circle_rounded : Icons.check_rounded),
                  label: Text(_completed ? 'Concluída!' : 'Marcar como concluída'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _completed ? ElevaColors.gold.withValues(alpha: 0.3) : ElevaColors.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
