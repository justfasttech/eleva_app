import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../providers/faith_history_provider.dart';

class FaithLineChart extends ConsumerWidget {
  const FaithLineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(faithHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gráfico de fé',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ElevaColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
          decoration: BoxDecoration(
            color: ElevaColors.offWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: historyAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(
                  color: ElevaColors.gold,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, __) => const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Erro ao carregar dados',
                  style: TextStyle(fontSize: 13, color: ElevaColors.textMuted),
                ),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart_rounded,
                            size: 36, color: ElevaColors.goldLight),
                        SizedBox(height: 8),
                        Text(
                          'Sem dados ainda',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ElevaColors.textMuted,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete tarefas para ver seu progresso',
                          style: TextStyle(
                              fontSize: 12, color: ElevaColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 160,
                child: _Chart(entries: entries),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  final List<FaithHistoryEntry> entries;
  const _Chart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].faithLevel.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 70,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 14,
          getDrawingHorizontalLine: (value) => FlLine(
            color: ElevaColors.textMuted.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 14,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == 70) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ElevaColors.textMuted,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                if (entries.length > 5 && idx % 2 != 0) {
                  return const SizedBox.shrink();
                }
                final d = entries[idx].date;
                return Text(
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ElevaColors.textMuted,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => ElevaColors.gold,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()}%',
                  const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: ElevaColors.gold,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: ElevaColors.gold,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ElevaColors.gold.withValues(alpha: 0.25),
                  ElevaColors.gold.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
