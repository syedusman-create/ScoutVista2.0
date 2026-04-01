import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/ai/heuristics/landmark_exercises.dart';

class RepVisualizationChart extends StatelessWidget {
  final List<RepDetectionEvent> repEvents;
  final double videoDuration;
  final String exerciseType;

  const RepVisualizationChart({
    Key? key,
    required this.repEvents,
    required this.videoDuration,
    required this.exerciseType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (repEvents.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline, color: Colors.grey[400], size: 48),
              const SizedBox(height: 8),
              Text(
                'No rep detection events recorded',
                style: GoogleFonts.urbanist(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Rep Detection Timeline',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 0.1,
                  verticalInterval: videoDuration / 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: videoDuration / 5,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}s',
                            style: GoogleFonts.urbanist(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.1,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: GoogleFonts.urbanist(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                minX: 0,
                maxX: videoDuration,
                minY: _getMinY(),
                maxY: _getMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpots(),
                    isCurved: false,
                    color: Colors.blue[600]!,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final event = repEvents[index];
                        Color dotColor = Colors.blue[600]!;
                        if (event.phase == 'rep_completed') {
                          dotColor = Colors.green[600]!;
                        } else if (event.phase == 'down' || event.phase == 'up') {
                          dotColor = Colors.orange[600]!;
                        }
                        return FlDotCirclePainter(
                          radius: 4,
                          color: dotColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final event = repEvents[barSpot.spotIndex];
                        return LineTooltipItem(
                          '${event.phase}\n${event.timestamp.toStringAsFixed(1)}s\nValue: ${event.value.toStringAsFixed(3)}',
                          GoogleFonts.urbanist(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots() {
    if (repEvents.isEmpty) {
      // Return dummy data points to prevent chart errors
      return [FlSpot(0, 0), FlSpot(videoDuration, 0)];
    }
    return repEvents.map((event) {
      return FlSpot(event.timestamp, event.value);
    }).toList();
  }

  double _getMinY() {
    if (repEvents.isEmpty) return -0.1;
    final values = repEvents.map((e) => e.value).toList();
    return values.reduce((a, b) => a < b ? a : b) - 0.05;
  }

  double _getMaxY() {
    if (repEvents.isEmpty) return 0.1;
    final values = repEvents.map((e) => e.value).toList();
    return values.reduce((a, b) => a > b ? a : b) + 0.05;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.orange[600]!, 'Phase Detection'),
        _buildLegendItem(Colors.green[600]!, 'Rep Completed'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
