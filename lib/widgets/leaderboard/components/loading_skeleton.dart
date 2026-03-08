import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class LeaderboardLoadingSkeleton extends StatelessWidget {
  const LeaderboardLoadingSkeleton({super.key, required this.shimmerAnimation});

  final Animation<double> shimmerAnimation;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ShimmerBox(
                        height: 50,
                        radius: 12,
                        shimmerAnimation: shimmerAnimation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ShimmerBox(
                      width: 130,
                      height: 50,
                      radius: 12,
                      shimmerAnimation: shimmerAnimation,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ShimmerBox(
                      width: 220,
                      height: 120,
                      radius: 16,
                      shimmerAnimation: shimmerAnimation,
                    ),
                    _ShimmerBox(
                      width: 220,
                      height: 120,
                      radius: 16,
                      shimmerAnimation: shimmerAnimation,
                    ),
                    _ShimmerBox(
                      width: 220,
                      height: 120,
                      radius: 16,
                      shimmerAnimation: shimmerAnimation,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: AppTheme.cardRadius,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _ShimmerBox(
                          width: 50,
                          height: 50,
                          radius: 12,
                          shimmerAnimation: shimmerAnimation,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ShimmerBox(
                                width: 180,
                                height: 18,
                                radius: 8,
                                shimmerAnimation: shimmerAnimation,
                              ),
                              const SizedBox(height: 10),
                              _ShimmerBox(
                                width: 140,
                                height: 14,
                                radius: 8,
                                shimmerAnimation: shimmerAnimation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        _ShimmerBox(
                          width: 72,
                          height: 38,
                          radius: 10,
                          shimmerAnimation: shimmerAnimation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ShimmerBox(
                      height: 10,
                      radius: 8,
                      shimmerAnimation: shimmerAnimation,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ShimmerBox(
                          width: 84,
                          height: 28,
                          radius: 8,
                          shimmerAnimation: shimmerAnimation,
                        ),
                        _ShimmerBox(
                          width: 84,
                          height: 28,
                          radius: 8,
                          shimmerAnimation: shimmerAnimation,
                        ),
                        _ShimmerBox(
                          width: 84,
                          height: 28,
                          radius: 8,
                          shimmerAnimation: shimmerAnimation,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = 10,
    required this.shimmerAnimation,
  });

  final double? width;
  final double height;
  final double radius;
  final Animation<double> shimmerAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnimation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.backgroundCardLight,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      builder: (context, child) {
        final slide = shimmerAnimation.value * 2 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.6 + slide, -0.2),
              end: Alignment(1.6 + slide, 0.2),
              colors: [
                AppTheme.backgroundCardLight.withOpacity(0.35),
                Colors.white.withOpacity(0.28),
                AppTheme.backgroundCardLight.withOpacity(0.35),
              ],
              stops: const [0.1, 0.45, 0.8],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
