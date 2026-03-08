import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class MostActiveUsersCard extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const MostActiveUsersCard({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.whatshot, color: AppTheme.accent, size: 28),
              SizedBox(width: 12),
              Text(
                'Most Active Users',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Top performers by activity frequency (last 30 days)',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ...List.generate(users.length, (index) {
            final user = users[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < users.length - 1 ? 12 : 0,
              ),
              child: _UserActivityRow(rank: index + 1, user: user),
            );
          }),
        ],
      ),
    );
  }
}

class _UserActivityRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;

  const _UserActivityRow({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    final username = user['username']?.toString() ?? 'Unknown';
    final activeDays = user['active_days'] as int? ?? 0;
    final totalSolved = user['total_solved'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: _getRankColor(rank), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: [
                        _getRankColor(rank),
                        _getRankColor(rank).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: rank > 3 ? AppTheme.borderColor : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Username
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Active days badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accent, Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  '$activeDays days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Total solved
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$totalSolved solved',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.borderColor;
    }
  }
}
