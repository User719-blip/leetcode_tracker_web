import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class GlobalTrendsChart extends StatefulWidget {
  final List<Map<String, dynamic>> trends;

  const GlobalTrendsChart({super.key, required this.trends});

  @override
  State<GlobalTrendsChart> createState() => _GlobalTrendsChartState();
}

class _GlobalTrendsChartState extends State<GlobalTrendsChart> {
  String selectedMetric = 'total'; // total, easy, medium, hard

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
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final title = const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, color: AppTheme.accent, size: 28),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Global Trends',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );

              final selector = _MetricSelector(
                selected: selectedMetric,
                onChanged: (value) => setState(() => selectedMetric = value),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), selector],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [title, selector],
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Aggregate problem-solving activity over time',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _TrendLinePainter(
                trends: widget.trends,
                metric: selectedMetric,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 16),
          _TrendSummary(trends: widget.trends, metric: selectedMetric),
        ],
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MetricSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MetricButton(
              label: 'Total',
              value: 'total',
              selected: selected,
              onTap: onChanged,
            ),
            _MetricButton(
              label: 'Easy',
              value: 'easy',
              selected: selected,
              onTap: onChanged,
            ),
            _MetricButton(
              label: 'Medium',
              value: 'medium',
              selected: selected,
              onTap: onChanged,
            ),
            _MetricButton(
              label: 'Hard',
              value: 'hard',
              selected: selected,
              onTap: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricButton extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _MetricButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> trends;
  final String metric;

  _TrendLinePainter({required this.trends, required this.metric});

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    final values = trends
        .map((t) => (t[metric] as num?)?.toDouble() ?? 0)
        .toList();

    if (values.isEmpty) return;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);

    if (maxValue == minValue) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw trend line
    final path = Path();
    final stepX = size.width / (values.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minValue) / (maxValue - minValue);
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw area fill
    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.accent.withOpacity(0.3),
        AppTheme.accent.withOpacity(0.05),
      ],
    );

    final areaPaint = Paint()
      ..shader = areaGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(areaPath, areaPaint);

    // Draw line
    final linePaint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw dots
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minValue) / (maxValue - minValue);
      final y = size.height - (normalized * size.height);

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppTheme.accent);

      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = AppTheme.backgroundCard,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TrendSummary extends StatelessWidget {
  final List<Map<String, dynamic>> trends;
  final String metric;

  const _TrendSummary({required this.trends, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = trends
        .map((t) => (t[metric] as num?)?.toInt() ?? 0)
        .toList();

    final first = values.first;
    final last = values.last;
    final delta = last - first;
    final change = first > 0 ? ((delta / first) * 100).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Period Start', value: first.toString()),
          _SummaryItem(label: 'Period End', value: last.toString()),
          _SummaryItem(
            label: 'Change',
            value: delta >= 0 ? '+$delta' : '$delta',
            valueColor: delta >= 0 ? Colors.greenAccent : Colors.redAccent,
          ),
          _SummaryItem(label: 'Growth', value: '$change%'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
