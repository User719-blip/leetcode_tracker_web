import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;

class AnalyticsService {
  final supabase = Supabase.instance.client;

  static const int _estimatedLeetCodeProblemCount = 3500;

  Future<List<Map<String, dynamic>>> fetchLeaderboardData() async {
    final response = await supabase.rpc('get_latest_snapshots');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> enrichLeaderboardVisuals(
    List<Map<String, dynamic>> users,
  ) async {
    if (users.isEmpty) return;

    final userIds = users
        .map((u) => u['user_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    if (userIds.isEmpty) return;

    final fromDate = DateTime.now()
        .subtract(const Duration(days: 45))
        .toIso8601String()
        .split('T')
        .first;

    final snapshots = await supabase
        .from('snapshots')
        .select('user_id,date,total')
        .inFilter('user_id', userIds)
        .gte('date', fromDate)
        .order('date');

    final byUser = <String, List<Map<String, dynamic>>>{};
    for (final row in snapshots) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['user_id'].toString();
      byUser.putIfAbsent(id, () => []).add(map);
    }

    for (final user in users) {
      final userId = user['user_id']?.toString() ?? '';
      final history = byUser[userId] ?? const [];
      final currentTotal = (user['total'] as num?)?.toInt() ?? 0;

      final trend = _build7DayTrend(history, currentTotal);
      final weekly = _computeDelta(history, currentTotal, 7);
      final monthly = _computeDelta(history, currentTotal, 30);
      final streak = _computeCurrentStreak(history);

      final completion = currentTotal / _estimatedLeetCodeProblemCount;

      user['trend7d'] = trend;
      user['weekly_delta'] = weekly.delta;
      user['weekly_change_pct'] = weekly.percent;
      user['monthly_delta'] = monthly.delta;
      user['monthly_change_pct'] = monthly.percent;
      user['completion_pct'] = completion.clamp(0.0, 1.0);
      user['weekly_badge'] = _weeklyBadge(weekly.delta);
      user['monthly_badge'] = _monthlyBadge(monthly.delta);
      user['current_streak'] = streak;
    }
  }

  List<double> _build7DayTrend(
    List<Map<String, dynamic>> history,
    int fallback,
  ) {
    if (history.isEmpty) return List.filled(7, fallback.toDouble());

    final totals = history
        .map((s) => (s['total'] as num?)?.toDouble() ?? 0)
        .toList();

    final lastSeven = totals.length <= 7
        ? List<double>.from(totals)
        : totals.sublist(totals.length - 7);

    while (lastSeven.length < 7) {
      lastSeven.insert(
        0,
        lastSeven.isEmpty ? fallback.toDouble() : lastSeven.first,
      );
    }

    return lastSeven;
  }

  ({int delta, double percent}) _computeDelta(
    List<Map<String, dynamic>> history,
    int currentTotal,
    int days,
  ) {
    if (history.isEmpty) return (delta: 0, percent: 0);

    final latest = history.last;
    final latestDate = DateTime.tryParse(latest['date'].toString());
    if (latestDate == null) return (delta: 0, percent: 0);

    final target = latestDate.subtract(Duration(days: days));

    Map<String, dynamic> baseline = history.first;
    for (final snap in history) {
      final date = DateTime.tryParse(snap['date'].toString());
      if (date == null) continue;
      if (!date.isAfter(target)) {
        baseline = snap;
      }
    }

    final baselineTotal = (baseline['total'] as num?)?.toInt() ?? currentTotal;
    final delta = currentTotal - baselineTotal;
    final percent = baselineTotal > 0
        ? (delta / baselineTotal) * 100
        : (delta > 0 ? 100.0 : 0.0);

    return (delta: delta, percent: percent);
  }

  String _weeklyBadge(int delta) {
    if (delta >= 20) return 'Weekly Streak';
    if (delta >= 10) return 'Weekly Climber';
    if (delta > 0) return 'Weekly Active';
    return 'Weekly Starter';
  }

  String _monthlyBadge(int delta) {
    if (delta >= 80) return 'Monthly Beast';
    if (delta >= 40) return 'Monthly Warrior';
    if (delta >= 15) return 'Monthly Builder';
    return 'Monthly Starter';
  }

  /// Compute current daily solving streak from snapshots
  /// A streak is consecutive days with at least 1 problem solved
  int _computeCurrentStreak(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0;

    // Sort history by date
    final sorted = List<Map<String, dynamic>>.from(history);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'].toString());
      final dateB = DateTime.tryParse(b['date'].toString());
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    // Track previous total to detect solves
    int streakCount = 0;
    DateTime? lastStreakDate;

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];

      final prevTotal = (prev['total'] as num?)?.toInt() ?? 0;
      final currTotal = (curr['total'] as num?)?.toInt() ?? 0;
      final delta = currTotal - prevTotal;

      final currDate = DateTime.tryParse(curr['date'].toString());
      if (currDate == null) continue;

      if (delta > 0) {
        // User solved at least 1 problem on this day
        if (lastStreakDate == null) {
          // Start of streak
          streakCount = 1;
        } else {
          final daysDiff = currDate.difference(lastStreakDate).inDays;
          if (daysDiff == 1) {
            // Consecutive day, continue streak
            streakCount++;
          } else {
            // Gap in streak, reset
            streakCount = 1;
          }
        }
        lastStreakDate = currDate;
      }
    }

    return streakCount;
  }

  Future<List<Map<String, dynamic>>> fetchUserSnapshots(String userId) async {
    final response = await supabase
        .from('snapshots')
        .select()
        .eq('user_id', userId)
        .order('date');

    return List<Map<String, dynamic>>.from(response);
  }

  void exportLeaderboardCSV(List<Map<String, dynamic>> leaderboard) {
    List<List<dynamic>> rows = [];

    rows.add([
      "Rank",
      "Username",
      "Total",
      "Easy",
      "Medium",
      "Hard",
      "Ranking",
      "Score",
    ]);

    for (int i = 0; i < leaderboard.length; i++) {
      final user = leaderboard[i];

      rows.add([
        i + 1,
        user['username'],
        user['total'],
        user['easy'],
        user['medium'],
        user['hard'],
        user['ranking'],
        user['score'],
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final bytes = csv.codeUnits;
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "leetcode_leaderboard.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Future<Map<String, dynamic>> fetchGlobalStats() async {
    final users = await supabase.from('users').select();

    // Use only latest snapshot per user to avoid inflated totals.
    final latestSnapshots = await fetchLeaderboardData();

    int totalSolved = 0;
    int totalHard = 0;

    for (final s in latestSnapshots) {
      totalSolved += (s['total'] as num?)?.toInt() ?? 0;
      totalHard += (s['hard'] as num?)?.toInt() ?? 0;
    }

    return {
      "users": users.length,
      "totalSolved": totalSolved,
      "totalHard": totalHard,
    };
  }

  Future<void> updateAllUsers() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      throw Exception('No active session. Please login again.');
    }

    final response = await supabase.functions.invoke(
      'daily-update',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Failed to run daily update');
    }
  }

  Map<DateTime, int> computeDailySolves(List<Map<String, dynamic>> snapshots) {
    Map<DateTime, int> data = {};

    for (int i = 1; i < snapshots.length; i++) {
      final prev = snapshots[i - 1];
      final curr = snapshots[i];

      int delta = curr['total'] - prev['total'];

      DateTime date = DateTime.parse(curr['date']);

      if (delta > 0) {
        data[date] = delta;
      }
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyStats() async {
    final response = await supabase.rpc('get_weekly_comparison');
    return List<Map<String, dynamic>>.from(response);
  }

  Map<String, dynamic> computeAwards(List<Map<String, dynamic>> data) {
    data.sort((a, b) => b['delta_total'].compareTo(a['delta_total']));
    final mvp = data.first;

    data.sort((a, b) => b['rank_improvement'].compareTo(a['rank_improvement']));
    final rankClimber = data.first;

    data.sort((a, b) => a['delta_total'].compareTo(b['delta_total']));
    final slowest = data.first;

    data.sort((a, b) => b['hard_delta'].compareTo(a['hard_delta']));
    final hardPusher = data.first;

    return {
      "mvp": mvp,
      "rankClimber": rankClimber,
      "slowest": slowest,
      "hardPusher": hardPusher,
    };
  }

  double computeScore(Map<String, dynamic> s) {
    return s['easy'] * 1 +
        s['medium'] * 3 +
        s['hard'] * 6 +
        (600000 - s['ranking']) / 2000;
  }

  // Analytics Dashboard Methods

  /// Fetch most active users based on activity frequency over last 30 days
  Future<List<Map<String, dynamic>>> fetchMostActiveUsers({
    int limit = 10,
  }) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final dateStr = thirtyDaysAgo.toIso8601String().split('T').first;

    // Get all snapshots from last 30 days with user info
    final snapshots = await supabase
        .from('snapshots')
        .select('user_id, date, total')
        .gte('date', dateStr)
        .order('date');

    final users = await supabase.from('users').select('id, username');

    // Count unique active days per user
    final userActivity = <String, Set<String>>{};
    final userTotalSolved = <String, int>{};

    for (final snap in snapshots) {
      final userId = snap['user_id'].toString();
      final date = snap['date'].toString();
      final total = (snap['total'] as num?)?.toInt() ?? 0;

      userActivity.putIfAbsent(userId, () => {}).add(date);
      userTotalSolved[userId] = total;
    }

    // Build result list
    final userMap = {for (var u in users) u['id'].toString(): u['username']};
    final result = <Map<String, dynamic>>[];

    for (final entry in userActivity.entries) {
      result.add({
        'user_id': entry.key,
        'username': userMap[entry.key] ?? 'Unknown',
        'active_days': entry.value.length,
        'total_solved': userTotalSolved[entry.key] ?? 0,
      });
    }

    // Sort by active days, then by total solved
    result.sort((a, b) {
      final dayComp = (b['active_days'] as int).compareTo(
        a['active_days'] as int,
      );
      if (dayComp != 0) return dayComp;
      return (b['total_solved'] as int).compareTo(a['total_solved'] as int);
    });

    return result.take(limit).toList();
  }

  /// Fetch global statistics trends over time (last 90 days)
  /// Returns daily aggregates of total problems solved across all users
  Future<List<Map<String, dynamic>>> fetchGlobalTrends({int days = 90}) async {
    final startDate = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .split('T')
        .first;

    final snapshots = await supabase
        .from('snapshots')
        .select('date, easy, medium, hard, total')
        .gte('date', startDate)
        .order('date');

    // Group by date and compute aggregates
    final dateGroups = <String, List<Map<String, dynamic>>>{};

    for (final snap in snapshots) {
      final date = snap['date'].toString();
      dateGroups.putIfAbsent(date, () => []).add(snap);
    }

    final result = <Map<String, dynamic>>[];

    for (final entry in dateGroups.entries) {
      final snaps = entry.value;
      final totalEasy = snaps.fold<int>(
        0,
        (sum, s) => sum + ((s['easy'] as num?)?.toInt() ?? 0),
      );
      final totalMedium = snaps.fold<int>(
        0,
        (sum, s) => sum + ((s['medium'] as num?)?.toInt() ?? 0),
      );
      final totalHard = snaps.fold<int>(
        0,
        (sum, s) => sum + ((s['hard'] as num?)?.toInt() ?? 0),
      );
      final totalSolved = snaps.fold<int>(
        0,
        (sum, s) => sum + ((s['total'] as num?)?.toInt() ?? 0),
      );

      result.add({
        'date': entry.key,
        'easy': totalEasy,
        'medium': totalMedium,
        'hard': totalHard,
        'total': totalSolved,
        'user_count': snaps.length,
      });
    }

    result.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));

    return result;
  }

  /// Get difficulty distribution across all users (current state)
  Future<Map<String, dynamic>> fetchDifficultyDistribution() async {
    final latest = await supabase.rpc('get_latest_snapshots');
    final snapshots = List<Map<String, dynamic>>.from(latest);

    int totalEasy = 0;
    int totalMedium = 0;
    int totalHard = 0;

    for (final snap in snapshots) {
      totalEasy += (snap['easy'] as num?)?.toInt() ?? 0;
      totalMedium += (snap['medium'] as num?)?.toInt() ?? 0;
      totalHard += (snap['hard'] as num?)?.toInt() ?? 0;
    }

    final total = totalEasy + totalMedium + totalHard;

    return {
      'easy': totalEasy,
      'medium': totalMedium,
      'hard': totalHard,
      'total': total,
      'easy_pct': total > 0 ? (totalEasy / total) * 100 : 0,
      'medium_pct': total > 0 ? (totalMedium / total) * 100 : 0,
      'hard_pct': total > 0 ? (totalHard / total) * 100 : 0,
    };
  }

  /// Find the most improved player in the last 30 days
  Future<Map<String, dynamic>?> fetchMostImprovedPlayer() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final dateStr = thirtyDaysAgo.toIso8601String().split('T').first;

    final snapshots = await supabase
        .from('snapshots')
        .select('user_id, date, total')
        .gte('date', dateStr)
        .order('date');

    final users = await supabase.from('users').select('id, username');
    final userMap = {for (var u in users) u['id'].toString(): u['username']};

    // Group by user
    final userSnapshots = <String, List<Map<String, dynamic>>>{};
    for (final snap in snapshots) {
      final userId = snap['user_id'].toString();
      userSnapshots.putIfAbsent(userId, () => []).add(snap);
    }

    // Calculate improvement for each user
    String? bestUserId;
    int maxImprovement = 0;
    int? bestStartTotal;
    int? bestEndTotal;

    for (final entry in userSnapshots.entries) {
      final snaps = entry.value;
      if (snaps.length < 2) continue;

      snaps.sort(
        (a, b) => a['date'].toString().compareTo(b['date'].toString()),
      );

      final startTotal = (snaps.first['total'] as num?)?.toInt() ?? 0;
      final endTotal = (snaps.last['total'] as num?)?.toInt() ?? 0;
      final improvement = endTotal - startTotal;

      if (improvement > maxImprovement) {
        maxImprovement = improvement;
        bestUserId = entry.key;
        bestStartTotal = startTotal;
        bestEndTotal = endTotal;
      }
    }

    if (bestUserId == null) return null;

    return {
      'user_id': bestUserId,
      'username': userMap[bestUserId] ?? 'Unknown',
      'improvement': maxImprovement,
      'start_total': bestStartTotal ?? 0,
      'end_total': bestEndTotal ?? 0,
      'percentage': bestStartTotal != null && bestStartTotal > 0
          ? ((maxImprovement / bestStartTotal) * 100).toStringAsFixed(1)
          : '0',
    };
  }
}
