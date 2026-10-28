import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';
import '../models/task.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<TaskProvider>(context, listen: false).fetchTasks(user.id);
      }
    });
  }

  Map<String, dynamic> _getConsistencyData(List<Task> tasks) {
    final dailyCounts = <String, int>{};
    
    for (var task in tasks) {
      if (!task.isRegular && task.completed && task.completedAt != null) {
        final dateStr = task.completedAt!.split('T')[0];
        dailyCounts[dateStr] = (dailyCounts[dateStr] ?? 0) + 1;
      }
      
      if (task.isRegular && task.history != null && task.history!.isNotEmpty) {
        for (var dateStr in task.history!) {
          dailyCounts[dateStr] = (dailyCounts[dateStr] ?? 0) + 1;
        }
      }
    }

    if (dailyCounts.isEmpty) return {'spots': <FlSpot>[], 'dates': <String>[]};

    final sortedDates = dailyCounts.keys.toList()..sort();
    final minDate = DateTime.parse(sortedDates.first);
    final maxDate = DateTime.parse(sortedDates.last);

    final List<FlSpot> spots = [];
    final List<String> dates = [];
    int index = 0;
    
    for (var d = minDate; d.isBefore(maxDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      final dateStr = d.toIso8601String().split('T')[0];
      final count = dailyCounts[dateStr] ?? 0;
      spots.add(FlSpot(index.toDouble(), count.toDouble()));
      dates.add(DateFormat('MMM d').format(d));
      index++;
    }
    
    return {'spots': spots, 'dates': dates};
  }

  Map<String, dynamic> _getPointsData(List<Task> tasks) {
    int health = 0;
    int wealth = 0;
    int knowledge = 0;
    
    for (var task in tasks) {
      if (task.isRegular && task.history != null && task.history!.isNotEmpty) {
        if (task.category.toLowerCase() == 'health') {
          health += task.history!.length;
        } else if (task.category.toLowerCase() == 'wealth') {
          wealth += task.history!.length;
        } else if (task.category.toLowerCase() == 'knowledge') {
          knowledge += task.history!.length;
        }
      }
    }

    double maxPoints = [health.toDouble(), wealth.toDouble(), knowledge.toDouble()].reduce((a, b) => a > b ? a : b);
    if (maxPoints < 5) maxPoints = 5;

    return {
      'max': maxPoints,
      'health': health.toDouble(),
      'wealth': wealth.toDouble(),
      'knowledge': knowledge.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    final bg = themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF));
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textSecondary = themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : Colors.grey);
    
    if (taskProvider.isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final consistencyMap = _getConsistencyData(taskProvider.tasks);
    final List<FlSpot> consistencySpots = consistencyMap['spots'];
    final List<String> consistencyDates = consistencyMap['dates'];
    
    final pointsMap = _getPointsData(taskProvider.tasks);
    
    final double health = pointsMap['health'];
    final double wealth = pointsMap['wealth'];
    final double knowledge = pointsMap['knowledge'];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HawkHeader
            const HawkHeader(
              title: 'Analytics',
              subtitle: 'Consistency & Points Progress',
            ),

            // 2. Charts Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consistency Chart Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text('Consistency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Number of tasks completed per day', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 32),
                    
                    if (consistencySpots.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(child: Text('No completion data available yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                      )
                    else
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: 1,
                              verticalInterval: 1,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1, dashArray: [3, 3]),
                              getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1, dashArray: [3, 3]),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < consistencyDates.length) {
                                      // Show fewer labels if there are many days
                                      if (consistencyDates.length > 7 && value.toInt() % (consistencyDates.length ~/ 5) != 0) {
                                        return const Text('');
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(consistencyDates[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (value == value.toInt()) {
                                      return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (consistencySpots.length - 1).toDouble(),
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: consistencySpots,
                                isCurved: true,
                                color: const Color(0xFF8AB4F8),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: const Color(0xFF8AB4F8), strokeWidth: 0),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFF8AB4F8).withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (spot) => Colors.white,
                                tooltipBorder: const BorderSide(color: Colors.grey, width: 1),
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((LineBarSpot touchedSpot) {
                                    final textStyle = const TextStyle(color: Color(0xFF8AB4F8), fontWeight: FontWeight.bold, fontSize: 14);
                                    return LineTooltipItem("${consistencyDates[touchedSpot.x.toInt()]}\n${touchedSpot.y.toInt()} Tasks", textStyle);
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Habit Points Chart Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeProvider?.cardBorder ?? (isDark ? Colors.white10 : Colors.black12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.radar, color: Color(0xFF8083FF)),
                        const SizedBox(width: 8),
                        Text(
                          'Habit Points',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: themeProvider?.primary ?? const Color(0xFF8083FF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Points gained from followed daily habits', style: TextStyle(fontSize: 14, color: textSecondary)),
                    const SizedBox(height: 24),
                    
                    if (health == 0 && wealth == 0 && knowledge == 0)
                      SizedBox(
                        height: 200,
                        child: Center(child: Text('No habit data available yet.', style: TextStyle(color: textSecondary, fontStyle: FontStyle.italic))),
                      )
                    else
                      SizedBox(
                        height: 250,
                        child: RadarChart(
                          RadarChartData(
                            dataSets: [
                              RadarDataSet(
                                dataEntries: [
                                  RadarEntry(value: health),
                                  RadarEntry(value: wealth),
                                  RadarEntry(value: knowledge),
                                ],
                                fillColor: const Color(0xFF8083FF).withValues(alpha: 0.5),
                                borderColor: const Color(0xFF8083FF),
                                entryRadius: 3,
                              ),
                            ],
                            radarBackgroundColor: Colors.transparent,
                            borderData: FlBorderData(show: false),
                            radarBorderData: const BorderSide(color: Colors.transparent),
                            tickBorderData: BorderSide(color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
                            gridBorderData: BorderSide(color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
                            radarShape: RadarShape.polygon,
                            tickCount: 5,
                            ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
                            titlePositionPercentageOffset: 0.2,
                            getTitle: (index, angle) {
                              
                              switch (index) {
                                case 0: return RadarChartTitle(text: 'Health', angle: 0, positionPercentageOffset: 0.1);
                                case 1: return RadarChartTitle(text: 'Wealth', angle: 0, positionPercentageOffset: 0.1);
                                case 2: return RadarChartTitle(text: 'Knowledge', angle: 0, positionPercentageOffset: 0.1);
                                default: return const RadarChartTitle(text: '');
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ],
  ),
),
);
  }
}

