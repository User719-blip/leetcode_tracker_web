import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class LeaderboardSearchSortBar extends StatelessWidget {
  const LeaderboardSearchSortBar({
    super.key,
    required this.searchQuery,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final String searchQuery;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        boxShadow: AppTheme.softShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;
          return isNarrow
              ? Column(
                  children: [
                    _SearchField(
                      searchQuery: searchQuery,
                      onSearchChanged: onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                    _SortDropdown(
                      sortBy: sortBy,
                      isExpanded: true,
                      onSortChanged: onSortChanged,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _SearchField(
                        searchQuery: searchQuery,
                        onSearchChanged: onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SortDropdown(sortBy: sortBy, onSortChanged: onSortChanged),
                  ],
                );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: AppTheme.bodyLarge,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: AppTheme.bodyMedium,
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => onSearchChanged(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.sortBy,
    this.isExpanded = false,
    required this.onSortChanged,
  });

  final String sortBy;
  final bool isExpanded;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sortBy,
          isExpanded: isExpanded,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppTheme.primary,
          ),
          dropdownColor: AppTheme.backgroundCard,
          style: AppTheme.bodyLarge,
          items: const [
            DropdownMenuItem(
              value: 'overall_solved',
              child: Row(
                children: [
                  Icon(Icons.public_rounded, size: 18, color: AppTheme.accent),
                  SizedBox(width: 8),
                  Text('Overall Solved'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'weekly_solved',
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_view_week_rounded,
                    size: 18,
                    color: AppTheme.secondary,
                  ),
                  SizedBox(width: 8),
                  Text('Weekly Solved'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'monthly_solved',
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text('Monthly Solved'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'score',
              child: Row(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 18,
                    color: AppTheme.secondary,
                  ),
                  SizedBox(width: 8),
                  Text('Score'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'total',
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 8),
                  Text('Total'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'hard',
              child: Row(
                children: [
                  Icon(Icons.whatshot_rounded, size: 18, color: AppTheme.hard),
                  SizedBox(width: 8),
                  Text('Hard'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'ranking',
              child: Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text('Rank'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) onSortChanged(value);
          },
        ),
      ),
    );
  }
}
