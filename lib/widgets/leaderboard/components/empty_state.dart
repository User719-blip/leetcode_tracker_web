import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class LeaderboardEmptyState extends StatelessWidget {
  const LeaderboardEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSearchEmpty,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final bool isSearchEmpty;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final icon = isSearchEmpty
        ? Icons.search_off_rounded
        : Icons.leaderboard_rounded;
    final accent = isSearchEmpty ? AppTheme.secondary : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.28),
                  AppTheme.backgroundCard.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 26,
                  right: 30,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundCardLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Icon(icon, size: 66, color: accent),
                if (!isSearchEmpty)
                  const Positioned(
                    bottom: 28,
                    child: Icon(
                      Icons.hourglass_empty_rounded,
                      size: 22,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          if (!isSearchEmpty)
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
