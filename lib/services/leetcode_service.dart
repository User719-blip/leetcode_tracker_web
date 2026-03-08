// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class LeetCodeService {
//   final String functionUrl =
//       'https://sukxolpjeagqybohmjdk.supabase.co/functions/v1/leetcode-fetch';

//   Future<Map<String, dynamic>> fetchStats(String username) async {
//     final response = await http.post(
//       Uri.parse(functionUrl),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"username": username}),
//     );

//     if (response.statusCode != 200) {
//       throw Exception("Failed to fetch stats");
//     }

//     final data = jsonDecode(response.body);

//     final stats = data['data']['matchedUser']['submitStats']['acSubmissionNum'];

//     final ranking = data['data']['matchedUser']['profile']['ranking'];

//     int easy = 0, medium = 0, hard = 0, total = 0;

//     for (var item in stats) {
//       if (item['difficulty'] == 'Easy') easy = item['count'];
//       if (item['difficulty'] == 'Medium') medium = item['count'];
//       if (item['difficulty'] == 'Hard') hard = item['count'];
//       if (item['difficulty'] == 'All') total = item['count'];
//     }

//     return {
//       "easy": easy,
//       "medium": medium,
//       "hard": hard,
//       "total": total,
//       "ranking": ranking,
//     };
//   }
// }

import 'package:supabase_flutter/supabase_flutter.dart';

class LeetCodeService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchStats(String username) async {
    final response = await supabase.functions.invoke(
      'leetcode-fetch',
      body: {'username': username},
    );

    if (response.status != 200) {
      throw Exception("Failed to fetch stats");
    }

    final data = response.data;

    final stats = data['data']['matchedUser']['submitStats']['acSubmissionNum'];

    final ranking = data['data']['matchedUser']['profile']['ranking'];

    int easy = 0, medium = 0, hard = 0, total = 0;

    for (var item in stats) {
      if (item['difficulty'] == 'Easy') easy = item['count'];
      if (item['difficulty'] == 'Medium') medium = item['count'];
      if (item['difficulty'] == 'Hard') hard = item['count'];
      if (item['difficulty'] == 'All') total = item['count'];
    }

    return {
      "easy": easy,
      "medium": medium,
      "hard": hard,
      "total": total,
      "ranking": ranking,
    };
  }
}
