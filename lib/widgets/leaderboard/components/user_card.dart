import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';
import 'package:leetcode_tracker_web/widgets/leaderboard/components/metrics.dart';
import 'package:leetcode_tracker_web/widgets/difficulty_bar_widget.dart';

class LeaderboardUserCard extends StatelessWidget {
  const LeaderboardUserCard({
    super.key,
    required this.user,
    required this.index,
    required this.rankColor,
    required this.rankingMode,
    required this.onTap,
  });

  final Map<String, dynamic> user;
  final int index;
  final Color Function(int rank) rankColor;
  final String rankingMode;
  final VoidCallback onTap;

  static String heroTagForUser(String userId) => 'leaderboard-user-$userId';

  @override
  Widget build(BuildContext context) {
    final currentScore = (user['score'] as num).toDouble();
    final weeklyDelta = (user['weekly_delta'] as num?)?.toInt() ?? 0;
    final monthlyDelta = (user['monthly_delta'] as num?)?.toInt() ?? 0;
    final isTopThree = index < 3;
    final userId = user['user_id'].toString();
    final weeklyPct = (user['weekly_change_pct'] as num?)?.toDouble() ?? 0.0;
    final monthlyPct = (user['monthly_change_pct'] as num?)?.toDouble() ?? 0.0;
    final completionPct = (user['completion_pct'] as num?)?.toDouble() ?? 0.0;
    final trend7d = ((user['trend7d'] as List?) ?? const <dynamic>[])
        .map((e) => (e as num).toDouble())
        .toList();
    final weeklyBadge = user['weekly_badge']?.toString() ?? 'Weekly Starter';
    final monthlyBadge = user['monthly_badge']?.toString() ?? 'Monthly Starter';
    final currentStreak = (user['current_streak'] as int?) ?? 0;

    final displayValue = switch (rankingMode) {
      'overall_solved' => (user['total'] as num?)?.toInt() ?? 0,
      'weekly_solved' => weeklyDelta,
      'monthly_solved' => monthlyDelta,
      _ => currentScore,
    };

    final displayLabel = switch (rankingMode) {
      'overall_solved' => 'Overall',
      'weekly_solved' => '7D Solved',
      'monthly_solved' => '30D Solved',
      _ => 'Score',
    };

    final displayText = displayValue is double
        ? displayValue.toStringAsFixed(1)
        : displayValue.toString();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 45).clamp(0, 540)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.softShadow,
          border: isTopThree
              ? Border.all(color: rankColor(index).withOpacity(0.5), width: 2)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppTheme.cardRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: heroTagForUser(userId),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: isTopThree
                                  ? LinearGradient(
                                      colors: [
                                        rankColor(index),
                                        rankColor(index).withOpacity(0.6),
                                      ],
                                    )
                                  : AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '#${index + 1}',
                                style: AppTheme.labelLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user['username'],
                                    style: AppTheme.heading3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isTopThree) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    color: rankColor(index),
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _MiniInfoChip(
                                  icon: Icons.check_circle_outline_rounded,
                                  iconColor: AppTheme.accent,
                                  value: '${user['total']}',
                                ),
                                const SizedBox(width: 8),
                                _MiniInfoChip(
                                  icon: Icons.leaderboard_rounded,
                                  iconColor: AppTheme.secondary,
                                  value: '#${user['ranking']}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              displayText,
                              style: AppTheme.heading3.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(displayLabel, style: AppTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedDifficultyBar(
                    easy: user['easy'],
                    medium: user['medium'],
                    hard: user['hard'],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DifficultyChip(
                        label: 'Easy',
                        count: user['easy'],
                        color: AppTheme.easy,
                      ),
                      _DifficultyChip(
                        label: 'Medium',
                        count: user['medium'],
                        color: AppTheme.medium,
                      ),
                      _DifficultyChip(
                        label: 'Hard',
                        count: user['hard'],
                        color: AppTheme.hard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SparklineCard(
                          points: trend7d,
                          changePercent: weeklyPct,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          CompletionRing(percent: completionPct),
                          const SizedBox(height: 6),
                          Text('Complete', style: AppTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      PercentageChangeIndicator(value: monthlyPct),
                      const SizedBox(width: 8),
                      Text('30D', style: AppTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AchievementBadgesRow(
                    weeklyBadge: weeklyBadge,
                    monthlyBadge: monthlyBadge,
                  ),
                  const SizedBox(height: 10),
                  _StreakBadge(streak: currentStreak),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: AppTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final isOnFire = streak >= 7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: isOnFire
            ? LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withOpacity(0.9),
                  const Color(0xFFFF4500).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  AppTheme.accent.withOpacity(0.8),
                  AppTheme.secondary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnFire ? Icons.local_fire_department : Icons.check_circle,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isOnFire ? '$streak 🔥' : '$streak day${streak == 1 ? '' : 's'}',
            style: AppTheme.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
