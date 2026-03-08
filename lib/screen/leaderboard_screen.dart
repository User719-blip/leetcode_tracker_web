import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/screen/admin_login_screen.dart';
import 'package:leetcode_tracker_web/screen/analytics_dashboard_screen.dart';
import 'package:leetcode_tracker_web/screen/user_detail_screen.dart';
import 'package:leetcode_tracker_web/services/analitical_service.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';
import 'package:leetcode_tracker_web/widgets/leaderboard/leaderboard_components.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final service = AnalyticsService();
  List<Map<String, dynamic>> leaderboard = [];
  List<Map<String, dynamic>> filteredLeaderboard = [];
  bool loading = true;
  bool refreshing = false;
  Map<String, dynamic> awards = {};
  Map<String, dynamic> globalStats = {};
  String searchQuery = '';
  String sortBy = 'score'; // score, total, hard, ranking
  String? errorMessage;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      if (!refreshing) loading = true;
      errorMessage = null;
    });

    try {
      final data = await service.fetchLeaderboardData();
      final fetchedGlobalStats = await service.fetchGlobalStats();

      for (var user in data) {
        user['score'] = service.computeScore(user);
      }

      await service.enrichLeaderboardVisuals(data);

      _sortLeaderboard(data);

      final weeklyData = await service.fetchWeeklyStats();
      if (weeklyData.isNotEmpty) {
        awards = service.computeAwards(weeklyData);
      }

      setState(() {
        leaderboard = data;
        filteredLeaderboard = data;
        globalStats = fetchedGlobalStats;
        loading = false;
        refreshing = false;
      });

      _applySearchFilter();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load leaderboard: $e';
        loading = false;
        refreshing = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() => refreshing = true);
    await loadData();
  }

  void _sortLeaderboard(List<Map<String, dynamic>> data) {
    switch (sortBy) {
      case 'total':
        data.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
        break;
      case 'hard':
        data.sort((a, b) => (b['hard'] as int).compareTo(a['hard'] as int));
        break;
      case 'ranking':
        data.sort(
          (a, b) => (a['ranking'] as int).compareTo(b['ranking'] as int),
        );
        break;
      case 'score':
      default:
        data.sort((a, b) => b['score'].compareTo(a['score']));
    }
  }

  void _applySearchFilter() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredLeaderboard = List.from(leaderboard);
      } else {
        filteredLeaderboard = leaderboard.where((user) {
          return user['username'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
        }).toList();
      }
    });
  }

  void _onSearchChanged(String query) {
    searchQuery = query;
    _applySearchFilter();
  }

  void _onSortChanged(String newSortBy) {
    setState(() {
      sortBy = newSortBy;
      _sortLeaderboard(leaderboard);
      filteredLeaderboard = List.from(leaderboard);
      _applySearchFilter();
    });
  }

  Color _rankColor(int rank) {
    if (rank == 0) return AppTheme.gold;
    if (rank == 1) return AppTheme.silver;
    if (rank == 2) return AppTheme.bronze;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(context),
      body: loading
          ? LeaderboardLoadingSkeleton(shimmerAnimation: _shimmerController)
          : errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: refreshData,
              color: AppTheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: LeaderboardSearchSortBar(
                      searchQuery: searchQuery,
                      sortBy: sortBy,
                      onSearchChanged: _onSearchChanged,
                      onSortChanged: _onSortChanged,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          GlobalStatsCard(
                            title: 'Users',
                            value: '${globalStats['users'] ?? 0}',
                          ),
                          GlobalStatsCard(
                            title: 'Total Solved',
                            value: '${globalStats['totalSolved'] ?? 0}',
                          ),
                          GlobalStatsCard(
                            title: 'Hard Problems',
                            value: '${globalStats['totalHard'] ?? 0}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (leaderboard.length >= 3)
                    SliverToBoxAdapter(
                      child: TopThreePodium(
                        leaderboard: leaderboard,
                        rankColor: _rankColor,
                      ),
                    ),
                  if (awards.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            AwardCard(title: 'MVP', user: awards['mvp']),
                            AwardCard(
                              title: 'Rank Climber',
                              user: awards['rankClimber'],
                            ),
                            AwardCard(
                              title: 'Slowest',
                              user: awards['slowest'],
                            ),
                            AwardCard(
                              title: 'Hard Pusher',
                              user: awards['hardPusher'],
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (filteredLeaderboard.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: leaderboard.isEmpty
                          ? LeaderboardEmptyState(
                              title: 'No leaderboard users yet',
                              subtitle:
                                  'Add users to start tracking progress and rankings.',
                              isSearchEmpty: false,
                              onRefresh: refreshData,
                            )
                          : const LeaderboardEmptyState(
                              title: 'No users found',
                              subtitle:
                                  'Try adjusting your search to find a match.',
                              isSearchEmpty: true,
                            ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList.builder(
                        itemCount: filteredLeaderboard.length,
                        itemBuilder: (context, index) {
                          final user = filteredLeaderboard[index];
                          return LeaderboardUserCard(
                            user: user,
                            index: index,
                            rankColor: _rankColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                buildSlideFadeRoute(
                                  page: UserDetailScreen(
                                    userId: user['user_id'].toString(),
                                    username: user['username'].toString(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.code, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('LeetCode War Room', style: AppTheme.heading3),
        ],
      ),
      backgroundColor: AppTheme.backgroundCard,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCardLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: AppTheme.accent),
            tooltip: 'Refresh',
            onPressed: refreshing ? null : refreshData,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCardLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.accent),
            tooltip: 'Export CSV',
            onPressed: () => service.exportLeaderboardCSV(leaderboard),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCardLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.analytics_rounded, color: AppTheme.accent),
            tooltip: 'Analytics Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                buildSlideFadeRoute(page: const AnalyticsDashboardScreen()),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Admin Panel',
            onPressed: () {
              Navigator.push(
                context,
                buildSlideFadeRoute(page: const AdminLoginScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.hard,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Leaderboard',
            style: AppTheme.heading3.copyWith(color: AppTheme.hard),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
