import 'package:flutter/material.dart';

class MostImprovedCard extends StatelessWidget {
  final Map<String, dynamic> player;

  const MostImprovedCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final username = player['username']?.toString() ?? 'Unknown';
    final improvement = player['improvement'] as int? ?? 0;
    final startTotal = player['start_total'] as int? ?? 0;
    final endTotal = player['end_total'] as int? ?? 0;
    final percentage = player['percentage']?.toString() ?? '0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: isCompact ? 26 : 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Most Improved Player',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                username,
                maxLines: isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 26 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: isCompact ? 0.4 : 1.2,
                ),
              ),
              const SizedBox(height: 12),
              isCompact
                  ? Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _StatBox(label: 'Start', value: startTotal.toString()),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white70,
                          size: 20,
                        ),
                        _StatBox(label: 'Current', value: endTotal.toString()),
                      ],
                    )
                  : Row(
                      children: [
                        _StatBox(label: 'Start', value: startTotal.toString()),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        _StatBox(label: 'Current', value: endTotal.toString()),
                      ],
                    ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: isCompact ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: isCompact ? 20 : 24,
                    ),
                    Text(
                      '+$improvement problems',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 17 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '($percentage% growth)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isCompact ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
