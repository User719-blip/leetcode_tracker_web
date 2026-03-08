import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/services/analitical_service.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';
import 'package:leetcode_tracker_web/widgets/analytics/analytics_components.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final service = AnalyticsService();
  bool loading = true;

  // Data containers
  List<Map<String, dynamic>> mostActiveUsers = [];
  Map<int, int> peakTimes = {};
  List<Map<String, dynamic>> globalTrends = [];
  Map<String, dynamic>? difficultyDistribution;
  Map<String, dynamic>? mostImprovedPlayer;

  @override
  void initState() {
    super.initState();
    loadAnalyticsData();
  }

  Future<void> loadAnalyticsData() async {
    setState(() => loading = true);

    try {
      final results = await Future.wait([
        service.fetchMostActiveUsers(),
        service.fetchPeakTimes(),
        service.fetchGlobalTrends(days: 90),
        service.fetchDifficultyDistribution(),
        service.fetchMostImprovedPlayer(),
      ]);

      setState(() {
        mostActiveUsers = results[0] as List<Map<String, dynamic>>;
        peakTimes = results[1] as Map<int, int>;
        globalTrends = results[2] as List<Map<String, dynamic>>;
        difficultyDistribution = results[3] as Map<String, dynamic>;
        mostImprovedPlayer = results[4] as Map<String, dynamic>?;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppTheme.backgroundCard,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadAnalyticsData,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadAnalyticsData,
              color: AppTheme.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Most Improved Player Hero Card
                    if (mostImprovedPlayer != null)
                      MostImprovedCard(player: mostImprovedPlayer!),
                    const SizedBox(height: 24),

                    // Difficulty Distribution
                    if (difficultyDistribution != null)
                      DifficultyDistributionCard(
                        distribution: difficultyDistribution!,
                      ),
                    const SizedBox(height: 24),

                    // Global Trends Chart
                    if (globalTrends.isNotEmpty)
                      GlobalTrendsChart(trends: globalTrends),
                    const SizedBox(height: 24),

                    // Peak Times Heatmap
                    if (peakTimes.isNotEmpty)
                      PeakTimesCard(peakTimes: peakTimes),
                    const SizedBox(height: 24),

                    // Most Active Users
                    if (mostActiveUsers.isNotEmpty)
                      MostActiveUsersCard(users: mostActiveUsers),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
