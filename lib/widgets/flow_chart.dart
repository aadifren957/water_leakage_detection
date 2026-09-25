import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_reading_model.dart';
import '../core/constants/app_colors.dart';

class FlowChart extends StatelessWidget {
  final SensorReadingModel sensor;

  const FlowChart({
    super.key,
    required this.sensor,
  });

  @override
  Widget build(BuildContext context) {
    final readings = sensor.hourlyHistory;
    if (readings.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No historical telemetry available'),
        ),
      );
    }

    final spots = readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.flowRate);
    }).toList();

    final maxFlow = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = ((maxFlow + 3) / 2).ceil() * 2.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primaryNavy),
                  SizedBox(width: 6),
                  Text(
                    'Flow Rate Trend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Actual Flow (L/min)',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (readings.length - 1).toDouble(),
                minY: 0,
                maxY: maxY < 10 ? 10 : maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 12 ? 4 : 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxY > 12 ? 4 : 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < readings.length) {
                          // Show alternate titles on smaller widths
                          if (readings.length > 5 && index % 2 != 0 && index != readings.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              readings[index].timeLabel,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final time = index < readings.length ? readings[index].timeLabel : '';
                        return LineTooltipItem(
                          '$time\n${spot.y.toStringAsFixed(2)} L/min',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                    curveSmoothness: 0.35,
                    color: sensor.isLeakageDetected ? AppColors.priorityCritical : AppColors.primaryBlue,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: sensor.isLeakageDetected
                              ? AppColors.priorityCritical
                              : AppColors.primaryBlue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          (sensor.isLeakageDetected
                                  ? AppColors.priorityCritical
                                  : AppColors.primaryBlue)
                              .withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
