import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class AwardCard extends StatelessWidget {
  const AwardCard({super.key, required this.title, required this.user});

  final String title;
  final Map<String, dynamic>? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    IconData icon;
    LinearGradient gradient;

    if (title.contains('MVP')) {
      icon = Icons.emoji_events_rounded;
      gradient = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      );
    } else if (title.contains('Climber')) {
      icon = Icons.trending_up_rounded;
      gradient = AppTheme.accentGradient;
    } else if (title.contains('Slowest')) {
      icon = Icons.snooze_rounded;
      gradient = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      );
    } else {
      icon = Icons.local_fire_department_rounded;
      gradient = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
      );
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.heading3.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user!['username'] ?? '-',
            style: AppTheme.heading2.copyWith(fontSize: 22),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCardLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppTheme.accent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "${user!['delta_total'] ?? 0} solved",
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.whatshot_rounded,
                  color: AppTheme.hard,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "${user!['hard_delta'] ?? 0} hard",
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
