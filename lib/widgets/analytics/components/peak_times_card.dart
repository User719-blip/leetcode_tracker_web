import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class PeakTimesCard extends StatelessWidget {
  final Map<int, int> peakTimes;

  const PeakTimesCard({super.key, required this.peakTimes});

  @override
  Widget build(BuildContext context) {
    final maxActivity = peakTimes.values.isEmpty
        ? 1
        : peakTimes.values.reduce((a, b) => a > b ? a : b);

    // Find peak hour
    int peakHour = 0;
    int peakCount = 0;
    peakTimes.forEach((hour, count) {
      if (count > peakCount) {
        peakHour = hour;
        peakCount = count;
      }
    });

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
              Icon(Icons.schedule, color: AppTheme.accent, size: 28),
              SizedBox(width: 12),
              Text(
                'Peak Activity Times',
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
            'Most active hour: ${_formatHour(peakHour)} with $peakCount activities',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Hourly heatmap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(24, (hour) {
              final count = peakTimes[hour] ?? 0;
              final intensity = count / maxActivity;
              return _HourBlock(hour: hour, count: count, intensity: intensity);
            }),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class _HourBlock extends StatelessWidget {
  final int hour;
  final int count;
  final double intensity;

  const _HourBlock({
    required this.hour,
    required this.count,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getIntensityColor(intensity);

    return Tooltip(
      message: '${_formatHour(hour)}\n$count activities',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hour.toString().padLeft(2, '0'),
              style: TextStyle(
                color: intensity > 0.5 ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count > 0)
              Text(
                count.toString(),
                style: TextStyle(
                  color: intensity > 0.5 ? Colors.black54 : Colors.white54,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity == 0) return AppTheme.backgroundDark;
    if (intensity < 0.2) return AppTheme.accent.withOpacity(0.2);
    if (intensity < 0.4) return AppTheme.accent.withOpacity(0.4);
    if (intensity < 0.6) return AppTheme.accent.withOpacity(0.6);
    if (intensity < 0.8) return AppTheme.accent.withOpacity(0.8);
    return AppTheme.accent;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}
