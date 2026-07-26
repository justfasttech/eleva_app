import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../../home/providers/faith_history_provider.dart';
import '../../home/providers/faith_history_recorder.dart';
import '../models/meditation.dart';

class MeditationPlayerScreen extends ConsumerStatefulWidget {
  final Meditation meditation;

  const MeditationPlayerScreen({super.key, required this.meditation});

  @override
  ConsumerState<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends ConsumerState<MeditationPlayerScreen> {
  late final AudioPlayer _player;
  bool _isLoading = true;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    if (!widget.meditation.hasAudio) {
      setState(() {
        _isLoading = false;
        _error = 'Nenhum áudio disponível';
      });
      return;
    }
    try {
      await _player.setUrl(widget.meditation.audioUrl!);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar áudio';
        });
      }
    }
  }

  Future<void> _markCompleted() async {
    if (_completed) return;
    setState(() => _completed = true);

    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;

    final points = widget.meditation.faithPoints;
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
          content: Text('Meditação concluída!'),
          backgroundColor: ElevaColors.gold,
        ),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meditation;

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ElevaColors.textDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ElevaColors.gold, ElevaColors.goldLight],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: ElevaColors.gold.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  m.type == 'guiada'
                      ? Icons.self_improvement_rounded
                      : Icons.waves_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                m.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ElevaColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${m.typeLabel} · ${m.durationLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElevaColors.gold,
                  ),
                ),
              ),
              if (m.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  m.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ElevaColors.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(flex: 1),
              if (_isLoading)
                const CircularProgressIndicator(color: ElevaColors.gold)
              else if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: ElevaColors.textMuted, fontSize: 14),
                )
              else ...[
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final total = _player.duration ?? Duration.zero;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            activeTrackColor: ElevaColors.gold,
                            inactiveTrackColor: ElevaColors.gold.withValues(alpha: 0.15),
                            thumbColor: ElevaColors.gold,
                            overlayColor: ElevaColors.gold.withValues(alpha: 0.1),
                          ),
                          child: Slider(
                            min: 0,
                            max: total.inMilliseconds.toDouble().clamp(1, double.infinity),
                            value: position.inMilliseconds
                                .toDouble()
                                .clamp(0, total.inMilliseconds.toDouble().clamp(1, double.infinity)),
                            onChanged: (v) {
                              _player.seek(Duration(milliseconds: v.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                              ),
                              Text(
                                _formatDuration(total),
                                style: const TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final playing = state?.playing ?? false;
                    final completed =
                        state?.processingState == ProcessingState.completed;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            final pos = _player.position - const Duration(seconds: 15);
                            _player.seek(pos < Duration.zero ? Duration.zero : pos);
                          },
                          icon: const Icon(Icons.replay_10_rounded),
                          iconSize: 32,
                          color: ElevaColors.textDark,
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            if (completed) {
                              _player.seek(Duration.zero);
                              _player.play();
                            } else if (playing) {
                              _player.pause();
                            } else {
                              _player.play();
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ElevaColors.gold, ElevaColors.goldLight],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ElevaColors.gold.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              completed
                                  ? Icons.replay_rounded
                                  : playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            final pos = _player.position + const Duration(seconds: 15);
                            final max = _player.duration ?? Duration.zero;
                            _player.seek(pos > max ? max : pos);
                          },
                          icon: const Icon(Icons.forward_10_rounded),
                          iconSize: 32,
                          color: ElevaColors.textDark,
                        ),
                      ],
                    );
                  },
                ),
              ],
              const Spacer(flex: 1),
              SizedBox(
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
