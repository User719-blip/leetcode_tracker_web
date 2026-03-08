import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class GlobalStatsCard extends StatelessWidget {
  const GlobalStatsCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color accentColor;

    switch (title) {
      case 'Users':
        icon = Icons.people_rounded;
        accentColor = AppTheme.primary;
        break;
      case 'Total Solved':
        icon = Icons.check_circle_rounded;
        accentColor = AppTheme.accent;
        break;
      case 'Hard Problems':
        icon = Icons.emoji_events_rounded;
        accentColor = AppTheme.hard;
        break;
      default:
        icon = Icons.bar_chart_rounded;
        accentColor = AppTheme.secondary;
    }

    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accentColor, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTheme.heading1.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
