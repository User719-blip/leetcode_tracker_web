import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class AnimatedDifficultyBar extends StatefulWidget {
  final int easy;
  final int medium;
  final int hard;

  const AnimatedDifficultyBar({
    super.key,
    required this.easy,
    required this.medium,
    required this.hard,
  });

  @override
  State<AnimatedDifficultyBar> createState() => _AnimatedDifficultyBarState();
}

class _AnimatedDifficultyBarState extends State<AnimatedDifficultyBar>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    animation = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int total = widget.easy + widget.medium + widget.hard;

    if (total == 0) return const SizedBox();

    double easyRatio = widget.easy / total;
    double mediumRatio = widget.medium / total;
    double hardRatio = widget.hard / total;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.backgroundCardLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (easyRatio > 0)
                  Expanded(
                    flex: (easyRatio * 100 * animation.value).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.easy,
                            AppTheme.easy.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (mediumRatio > 0)
                  Expanded(
                    flex: (mediumRatio * 100 * animation.value).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.medium,
                            AppTheme.medium.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (hardRatio > 0)
                  Expanded(
                    flex: (hardRatio * 100 * animation.value).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.hard,
                            AppTheme.hard.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
