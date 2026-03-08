import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class SparklineCard extends StatelessWidget {
  const SparklineCard({
    super.key,
    required this.points,
    required this.changePercent,
  });

  final List<double> points;
  final double changePercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '7D trend',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              PercentageChangeIndicator(value: changePercent),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: CustomPaint(
              painter: _SparklinePainter(points: points),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class PercentageChangeIndicator extends StatelessWidget {
  const PercentageChangeIndicator({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppTheme.easy : AppTheme.hard;
    final icon = positive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '${positive ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CompletionRing extends StatelessWidget {
  const CompletionRing({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0.0, 1.0);
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: p,
            strokeWidth: 7,
            backgroundColor: AppTheme.backgroundCardLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
          ),
          Text(
            '${(p * 100).round()}%',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementBadgesRow extends StatelessWidget {
  const AchievementBadgesRow({
    super.key,
    required this.weeklyBadge,
    required this.monthlyBadge,
  });

  final String weeklyBadge;
  final String monthlyBadge;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BadgeChip(
          label: weeklyBadge,
          icon: Icons.calendar_view_week_rounded,
          color: AppTheme.accent,
        ),
        _BadgeChip(
          label: monthlyBadge,
          icon: Icons.calendar_month_rounded,
          color: AppTheme.secondary,
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minVal = points.reduce((a, b) => math.min(a, b).toDouble());
    final maxVal = points.reduce((a, b) => math.max(a, b).toDouble());
    final range = (maxVal - minVal).abs() < 0.0001 ? 1.0 : (maxVal - minVal);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.accent, AppTheme.secondary],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.secondary.withOpacity(0.24),
          AppTheme.secondary.withOpacity(0.02),
        ],
      ).createShader(Offset.zero & size);

    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);

    final line = Path();
    final fill = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (stepX * i).toDouble();
      final norm = (points[i] - minVal) / range;
      final y = (size.height - (norm * (size.height - 4)) - 2).toDouble();

      if (i == 0) {
        line.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }

    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(line, linePaint);

    final lastNorm = (points.last - minVal) / range;
    final lastY = size.height - (lastNorm * (size.height - 4)) - 2;
    final lastDot = Paint()..color = AppTheme.secondary;
    canvas.drawCircle(Offset(size.width, lastY), 2.8, lastDot);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) return true;
    }
    return false;
  }
}
