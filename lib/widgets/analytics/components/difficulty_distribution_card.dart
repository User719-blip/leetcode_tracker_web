import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class DifficultyDistributionCard extends StatelessWidget {
  final Map<String, dynamic> distribution;

  const DifficultyDistributionCard({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final easy = distribution['easy'] as int? ?? 0;
    final medium = distribution['medium'] as int? ?? 0;
    final hard = distribution['hard'] as int? ?? 0;
    final total = distribution['total'] as int? ?? 0;

    final easyPct = distribution['easy_pct'] as num? ?? 0;
    final mediumPct = distribution['medium_pct'] as num? ?? 0;
    final hardPct = distribution['hard_pct'] as num? ?? 0;

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
              Icon(Icons.pie_chart, color: AppTheme.accent, size: 28),
              SizedBox(width: 12),
              Text(
                'Difficulty Distribution',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: $total problems solved across all users',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Bar chart representation
          _DifficultyBar(
            label: 'Easy',
            count: easy,
            percentage: easyPct.toDouble(),
            color: AppTheme.easy,
          ),
          const SizedBox(height: 16),
          _DifficultyBar(
            label: 'Medium',
            count: medium,
            percentage: mediumPct.toDouble(),
            color: AppTheme.medium,
          ),
          const SizedBox(height: 16),
          _DifficultyBar(
            label: 'Hard',
            count: hard,
            percentage: hardPct.toDouble(),
            color: AppTheme.hard,
          ),
        ],
      ),
    );
  }
}

class _DifficultyBar extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _DifficultyBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 4,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(color: AppTheme.borderColor),
                FractionallySizedBox(
                  widthFactor: (percentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
