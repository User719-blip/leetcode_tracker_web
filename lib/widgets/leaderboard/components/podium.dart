import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class TopThreePodium extends StatefulWidget {
  const TopThreePodium({
    super.key,
    required this.leaderboard,
    required this.rankColor,
  });

  final List<Map<String, dynamic>> leaderboard;
  final Color Function(int rank) rankColor;

  @override
  State<TopThreePodium> createState() => _TopThreePodiumState();
}

class _TopThreePodiumState extends State<TopThreePodium>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.leaderboard.length < 3) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StaggeredPodiumEntry(
            delayMs: 120,
            child: _PodiumCard(
              user: widget.leaderboard[1],
              rank: 2,
              rankColor: widget.rankColor,
            ),
          ),
          _StaggeredPodiumEntry(
            delayMs: 260,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _PodiumCard(
                  user: widget.leaderboard[0],
                  rank: 1,
                  rankColor: widget.rankColor,
                ),
                Positioned.fill(
                  top: -60,
                  child: IgnorePointer(
                    child: _ConfettiBurst(animation: _controller),
                  ),
                ),
              ],
            ),
          ),
          _StaggeredPodiumEntry(
            delayMs: 400,
            child: _PodiumCard(
              user: widget.leaderboard[2],
              rank: 3,
              rankColor: widget.rankColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredPodiumEntry extends StatelessWidget {
  const _StaggeredPodiumEntry({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 620 + delayMs),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        final delayed = ((value * (620 + delayMs) - delayMs) / 620).clamp(
          0.0,
          1.0,
        );
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, (1 - delayed) * 40),
            child: child,
          ),
        );
      },
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.user,
    required this.rank,
    required this.rankColor,
  });

  final Map<String, dynamic> user;
  final int rank;
  final Color Function(int rank) rankColor;

  @override
  Widget build(BuildContext context) {
    final height = rank == 1 ? 160.0 : 136.0;
    final score = (user['score'] as num).toDouble();
    final color = rankColor(rank - 1);

    return Container(
      width: 130,
      height: height,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color, width: 3),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      rank == 1
                          ? Icons.emoji_events_rounded
                          : Icons.military_tech_rounded,
                      color: Colors.white,
                      size: rank == 1 ? 32 : 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#$rank',
                    style: AppTheme.heading2.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      user['username'],
                      style: AppTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      score.toStringAsFixed(1),
                      style: AppTheme.bodyLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOut.transform(animation.value);
        return CustomPaint(
          painter: _ConfettiPainter(progress: t),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppTheme.gold,
      AppTheme.secondary,
      AppTheme.accent,
      AppTheme.hard,
      Colors.white,
    ];
    final center = Offset(size.width / 2, size.height * 0.75);

    for (int i = 0; i < 26; i++) {
      final angle = (i / 26) * math.pi * 1.3 + math.pi * 0.85;
      final spread = 18 + (i % 5) * 7;
      final radius = (22 + (i % 8) * 14) * progress;
      final wobble = math.sin((progress * 10) + i) * 4;
      final dx = center.dx + math.cos(angle) * radius + wobble;
      final dy = center.dy - math.sin(angle) * radius + spread * progress;

      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(
          (1 - progress).clamp(0.0, 1.0),
        );
      final rect = Rect.fromCenter(
        center: Offset(dx, dy),
        width: 6,
        height: 10,
      );

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate((i * 0.3) + progress * 6);
      canvas.translate(-dx, -dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
