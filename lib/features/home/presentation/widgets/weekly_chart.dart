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
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8EC5FC),
                Color(0xFFD6EEFF),
                Color(0xFFE8F4FD),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CloudPainter()),
                ),
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ElevaColors.gold.withValues(alpha: 0.18),
                          ElevaColors.gold.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
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
            ),
          ),
        ),
      ],
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white.withValues(alpha: 0.45);
    _drawCloud(canvas, paint, Offset(size.width * 0.12, size.height * 0.18), 1.0);

    paint.color = Colors.white.withValues(alpha: 0.35);
    _drawCloud(canvas, paint, Offset(size.width * 0.65, size.height * 0.10), 1.2);

    paint.color = Colors.white.withValues(alpha: 0.2);
    _drawCloud(canvas, paint, Offset(size.width * 0.38, size.height * 0.42), 0.6);

    paint.color = Colors.white.withValues(alpha: 0.25);
    _drawCloud(canvas, paint, Offset(size.width * 0.85, size.height * 0.55), 0.7);
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset center, double scale) {
    final r = 12.0 * scale;
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center + Offset(r * 0.9, -r * 0.25), r * 0.85, paint);
    canvas.drawCircle(center + Offset(r * 1.6, 0), r * 0.7, paint);
    canvas.drawCircle(center + Offset(-r * 0.5, r * 0.1), r * 0.6, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(r * 0.5, r * 0.35),
        width: r * 2.8,
        height: r * 0.7,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    final values = entries.map((e) => e.faithLevel).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final range = dataMax - dataMin;
    final padding = range < 2 ? 5.0 : range * 0.3;
    final chartMin = (dataMin - padding).clamp(0.0, 70.0);
    final chartMax = (dataMax + padding).clamp(1.0, 70.0);
    final interval = ((chartMax - chartMin) / 4).ceilToDouble().clamp(1.0, 14.0);
    final barData = _buildBarData(spots);

    return LineChart(
      LineChartData(
        minY: chartMin,
        maxY: chartMax,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
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
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value <= chartMin || value >= chartMax) {
                  return const SizedBox.shrink();
                }
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
          enabled: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1565C0),
            tooltipRoundedRadius: 6,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final v = spot.y;
                final label = v == v.roundToDouble()
                    ? '${v.toInt()}'
                    : v.toStringAsFixed(1);
                return LineTooltipItem(
                  label,
                  const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: List.generate(
          spots.length,
          (i) => ShowingTooltipIndicators([
            LineBarSpot(barData, 0, spots[i]),
          ]),
        ),
        lineBarsData: [barData],
      ),
    );
  }

  LineChartBarData _buildBarData(List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: const Color(0xFF1565C0),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: const Color(0xFF1565C0),
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1565C0).withValues(alpha: 0.25),
            const Color(0xFF1565C0).withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }
}
