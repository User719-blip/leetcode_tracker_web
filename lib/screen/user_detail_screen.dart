import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:leetcode_tracker_web/services/analitical_service.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';
import 'package:leetcode_tracker_web/widgets/leaderboard/leaderboard_components.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String username;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final service = AnalyticsService();
  List<Map<String, dynamic>> snapshots = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSnapshots();
  }

  Widget buildHeatmap() {
    final data = service.computeDailySolves(snapshots);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text("Daily Solves Heatmap", style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 20),
          HeatMap(
            datasets: data,
            colorMode: ColorMode.opacity,
            showColorTip: false,
            colorsets: const {
              1: AppTheme.easy,
              3: Color(0xFF4ADE80),
              5: AppTheme.medium,
              8: AppTheme.secondary,
              10: AppTheme.hard,
            },
            textColor: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Future<void> loadSnapshots() async {
    final data = await service.fetchUserSnapshots(widget.userId);

    setState(() {
      snapshots = data;
      loading = false;
    });
  }

  List<FlSpot> totalSpots() {
    return snapshots
        .asMap()
        .entries
        .map(
          (e) => FlSpot(e.key.toDouble(), (e.value['total'] as int).toDouble()),
        )
        .toList();
  }

  List<FlSpot> rankingSpots() {
    return snapshots
        .asMap()
        .entries
        .map(
          (e) =>
              FlSpot(e.key.toDouble(), (e.value['ranking'] as int).toDouble()),
        )
        .toList();
  }

  Widget buildChart(List<FlSpot> spots, String title) {
    IconData icon;
    if (title.contains("Total")) {
      icon = Icons.trending_up_rounded;
    } else {
      icon = Icons.leaderboard_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.backgroundCardLight,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.accent,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    gradient: AppTheme.accentGradient,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accent.withOpacity(0.3),
                          AppTheme.accent.withOpacity(0.0),
                        ],
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

  Widget difficultyChart() {
    if (snapshots.isEmpty) return const SizedBox();

    final latest = snapshots.last;

    final easy = latest['easy'];
    final medium = latest['medium'];
    final hard = latest['hard'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.easy, AppTheme.hard],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text("Difficulty Distribution", style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String label;
                        Color color;
                        switch (value.toInt()) {
                          case 0:
                            label = "Easy";
                            color = AppTheme.easy;
                            break;
                          case 1:
                            label = "Medium";
                            color = AppTheme.medium;
                            break;
                          case 2:
                            label = "Hard";
                            color = AppTheme.hard;
                            break;
                          default:
                            return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: AppTheme.bodyMedium.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: easy.toDouble(),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.easy,
                            AppTheme.easy.withOpacity(0.7),
                          ],
                        ),
                        width: 50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: medium.toDouble(),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.medium,
                            AppTheme.medium.withOpacity(0.7),
                          ],
                        ),
                        width: 50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: hard.toDouble(),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.hard,
                            AppTheme.hard.withOpacity(0.7),
                          ],
                        ),
                        width: 50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Hero(
                tag: LeaderboardUserCard.heroTagForUser(widget.userId),
                child: Material(
                  color: Colors.transparent,
                  child: const Icon(Icons.person_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.username, style: AppTheme.heading3),
          ],
        ),
        backgroundColor: AppTheme.backgroundCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  buildChart(totalSpots(), "Total Problems Solved"),
                  const SizedBox(height: 20),
                  buildChart(rankingSpots(), "Ranking Progress"),
                  const SizedBox(height: 20),
                  difficultyChart(),
                  const SizedBox(height: 20),
                  buildHeatmap(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
