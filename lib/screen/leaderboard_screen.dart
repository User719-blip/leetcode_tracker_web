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
  bool loadingMore = false;
  Map<String, dynamic> awards = {};
  Map<String, dynamic> globalStats = {};
  String searchQuery = '';
  String sortBy = 'overall_solved';
  String? errorMessage;
  late final AnimationController _shimmerController;
  late final ScrollController _scrollController;

  // Pagination
  static const int pageSize = 20;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        loadingMore ||
        filteredLeaderboard.isEmpty) {
      return;
    }

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Load more when user scrolls to 80% of the list
    if (currentScroll >= maxScroll * 0.8) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    if (loadingMore) return;

    // Check if there are more users to load
    final totalDisplayed = currentPage * pageSize;
    if (totalDisplayed >= filteredLeaderboard.length) {
      return;
    }

    setState(() => loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      currentPage++;
      loadingMore = false;
    });
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
    setState(() {
      refreshing = true;
      currentPage = 1;
    });
    await loadData();
  }

  void _sortLeaderboard(List<Map<String, dynamic>> data) {
    switch (sortBy) {
      case 'overall_solved':
        data.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
        break;
      case 'weekly_solved':
        data.sort(
          (a, b) => ((b['weekly_delta'] as num?)?.toInt() ?? 0).compareTo(
            (a['weekly_delta'] as num?)?.toInt() ?? 0,
          ),
        );
        break;
      case 'monthly_solved':
        data.sort(
          (a, b) => ((b['monthly_delta'] as num?)?.toInt() ?? 0).compareTo(
            (a['monthly_delta'] as num?)?.toInt() ?? 0,
          ),
        );
        break;
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
      currentPage = 1;
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
      currentPage = 1;
      _sortLeaderboard(leaderboard);
      filteredLeaderboard = List.from(leaderboard);
      _applySearchFilter();
    });
  }

  /// Get paginated users based on current page
  List<Map<String, dynamic>> _getPaginatedUsers() {
    final startIndex = 0;
    final endIndex = (currentPage * pageSize).clamp(
      0,
      filteredLeaderboard.length,
    );
    return filteredLeaderboard.sublist(startIndex, endIndex);
  }

  /// Check if there are more users to load
  bool _hasMoreUsers() {
    final totalDisplayed = currentPage * pageSize;
    return totalDisplayed < filteredLeaderboard.length;
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
                controller: _scrollController,
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
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
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
                        child: Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
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
                        itemCount:
                            _getPaginatedUsers().length +
                            (_hasMoreUsers() ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator at the end
                          if (index == _getPaginatedUsers().length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: loadingMore
                                    ? const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.accent,
                                            ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }

                          final user = _getPaginatedUsers()[index];
                          return LeaderboardUserCard(
                            user: user,
                            index: index,
                            rankColor: _rankColor,
                            rankingMode: sortBy,
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
    final isCompact = MediaQuery.sizeOf(context).width < 430;

    return AppBar(
      titleSpacing: isCompact ? 8 : null,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.code, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'LeetCode War Room',
              style: AppTheme.heading3,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
        if (isCompact)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.backgroundCardLight,
            onSelected: (value) {
              if (value == 'export') {
                service.exportLeaderboardCSV(leaderboard);
              } else if (value == 'analytics') {
                Navigator.push(
                  context,
                  buildSlideFadeRoute(page: const AnalyticsDashboardScreen()),
                );
              } else if (value == 'admin') {
                Navigator.push(
                  context,
                  buildSlideFadeRoute(page: const AdminLoginScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export CSV')),
              PopupMenuItem(
                value: 'analytics',
                child: Text('Analytics Dashboard'),
              ),
              PopupMenuItem(value: 'admin', child: Text('Admin Panel')),
            ],
          )
        else ...[
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
