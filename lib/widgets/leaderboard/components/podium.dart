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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoints
          final isCompact = constraints.maxWidth < 420;
          final isLarge = constraints.maxWidth > 600;

          final rowGap = isLarge ? 16.0 : 8.0;
          final rowMaxWidth = isLarge ? 860.0 : constraints.maxWidth;

          return Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rowMaxWidth),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 10,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _StaggeredPodiumEntry(
                        delayMs: 120,
                        child: _PodiumCard(
                          user: widget.leaderboard[1],
                          rank: 2,
                          rankColor: widget.rankColor,
                          compact: isCompact,
                          large: isLarge,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: rowGap),
                  Expanded(
                    flex: 11,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _StaggeredPodiumEntry(
                        delayMs: 260,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _PodiumCard(
                              user: widget.leaderboard[0],
                              rank: 1,
                              rankColor: widget.rankColor,
                              compact: isCompact,
                              large: isLarge,
                            ),
                            Positioned.fill(
                              top: isCompact ? -44 : (isLarge ? -72 : -60),
                              child: IgnorePointer(
                                child: _ConfettiBurst(animation: _controller),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: rowGap),
                  Expanded(
                    flex: 10,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _StaggeredPodiumEntry(
                        delayMs: 400,
                        child: _PodiumCard(
                          user: widget.leaderboard[2],
                          rank: 3,
                          rankColor: widget.rankColor,
                          compact: isCompact,
                          large: isLarge,
                        ),
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
    required this.compact,
    required this.large,
  });

  final Map<String, dynamic> user;
  final int rank;
  final Color Function(int rank) rankColor;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    late double height;
    late double maxWidth;
    late double iconSize;
    late double rankFontSize;
    late double usernameFontSize;
    late double scoreFontSize;
    late double padding;
    late double spacingBetweenElements;

    if (compact) {
      // Small screens (iPhone SE, < 420px)
      height = rank == 1 ? 148.0 : 126.0;
      maxWidth = 120;
      iconSize = rank == 1 ? 26 : 22;
      rankFontSize = 34;
      usernameFontSize = 13;
      scoreFontSize = 14;
      padding = 9;
      spacingBetweenElements = 6;
    } else if (large) {
      // Large screens (desktop/tablet, > 600px)
      height = rank == 1 ? 200.0 : 170.0;
      maxWidth = 160;
      iconSize = rank == 1 ? 42 : 36;
      rankFontSize = 52;
      usernameFontSize = 16;
      scoreFontSize = 16;
      padding = 14;
      spacingBetweenElements = 10;
    } else {
      // Medium screens (regular phones, 420-600px)
      height = rank == 1 ? 160.0 : 136.0;
      maxWidth = 132;
      iconSize = rank == 1 ? 32 : 28;
      rankFontSize = 40;
      usernameFontSize = 14;
      scoreFontSize = 15;
      padding = 12;
      spacingBetweenElements = 8;
    }

    final score = (user['score'] as num).toDouble();
    final color = rankColor(rank - 1);

    return Container(
      width: double.infinity,
      height: height,
      constraints: BoxConstraints(maxWidth: maxWidth),
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
                    padding: EdgeInsets.all(padding),
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
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: spacingBetweenElements * 0.75),
                  Text(
                    '#$rank',
                    style: AppTheme.heading2.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: rankFontSize,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacingBetweenElements * 0.75,
                    ),
                    child: Text(
                      user['username'],
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: usernameFontSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacingBetweenElements,
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
                        fontSize: scoreFontSize,
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
