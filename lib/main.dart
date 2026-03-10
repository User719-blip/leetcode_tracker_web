import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/config/env_config.dart';
import 'package:leetcode_tracker_web/screen/leaderboard_screen.dart';
import 'package:leetcode_tracker_web/services/leetcode_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate required environment variables
  EnvConfig.validate();

  // Initialize Supabase with environment configuration
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeetCode War Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.backgroundDark,
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: AppTheme.backgroundCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundCard,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.backgroundCardLight,
          border: OutlineInputBorder(
            borderRadius: AppTheme.buttonRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppTheme.buttonRadius,
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: AppTheme.heading1,
          displayMedium: AppTheme.heading2,
          displaySmall: AppTheme.heading3,
          bodyLarge: AppTheme.bodyLarge,
          bodyMedium: AppTheme.bodyMedium,
          bodySmall: AppTheme.bodySmall,
        ),
      ),
      home: const LeaderboardScreen(),
    );
  }
}

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController controller = TextEditingController();

  Future<void> addUser() async {
    final username = controller.text.trim();
    if (username.isEmpty) return;

    await supabase.from('users').insert({'username': username});

    controller.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("User added")));
  }

  Future<void> updateAllUsers() async {
    try {
      print("Update started");

      final users = await supabase.from('users').select();
      print("Users fetched: ${users.length}");

      final service = LeetCodeService();

      for (var user in users) {
        print("Fetching: ${user['username']}");

        final stats = await service.fetchStats(user['username']);
        print("Stats: $stats");

        await supabase.from('snapshots').upsert({
          "user_id": user['id'],
          "date": DateTime.now().toIso8601String().split("T").first,
          "easy": stats['easy'],
          "medium": stats['medium'],
          "hard": stats['hard'],
          "total": stats['total'],
          "ranking": stats['ranking'],
        });

        print("Inserted snapshot");
      }

      print("All done");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Stats updated")));
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add LeetCode User",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Enter username",
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: addUser, child: const Text("Add")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateAllUsers,
                child: const Text("Update All Stats"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
