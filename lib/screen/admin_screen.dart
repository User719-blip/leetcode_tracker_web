import 'package:flutter/material.dart';
import 'package:leetcode_tracker_web/services/analitical_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:leetcode_tracker_web/theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;
  final service = AnalyticsService();

  List<Map<String, dynamic>> users = [];
  final TextEditingController controller = TextEditingController();
  bool loading = true;
  bool updating = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<Map<String, dynamic>> _callAdminUsersFunction(
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    final response = await supabase.functions.invoke(
      'admin-users',
      body: {'action': action, if (payload != null) 'payload': payload},
    );

    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Request failed');
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> loadUsers() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await _callAdminUsersFunction('listUsers');
      final data = List<Map<String, dynamic>>.from(result['users'] ?? []);
      setState(() {
        users = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load users: $e';
        loading = false;
      });
    }
  }

  Future<void> addUser() async {
    final username = controller.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a username'),
          backgroundColor: AppTheme.hard,
        ),
      );
      return;
    }

    setState(() => updating = true);

    try {
      await _callAdminUsersFunction('addUser', payload: {'username': username});
      controller.clear();
      await loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "$username" added successfully'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add user: $e'),
            backgroundColor: AppTheme.hard,
          ),
        );
      }
    } finally {
      setState(() => updating = false);
    }
  }

  Future<void> deleteUser(String id, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        title: const Text('Delete User', style: AppTheme.heading3),
        content: Text(
          'Are you sure you want to delete "$username"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hard),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => updating = true);

    try {
      await _callAdminUsersFunction('deleteUser', payload: {'id': id});
      await loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "$username" deleted'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: AppTheme.hard,
          ),
        );
      }
    } finally {
      setState(() => updating = false);
    }
  }

  Future<void> fetchStats() async {
    setState(() => updating = true);

    try {
      await service.updateAllUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stats updated successfully!'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stats: $e'),
            backgroundColor: AppTheme.hard,
          ),
        );
      }
    } finally {
      setState(() => updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 24),
            ),
            const SizedBox(width: 12),
            const Text("Admin Panel", style: AppTheme.heading3),
          ],
        ),
        backgroundColor: AppTheme.backgroundCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.hard,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Users',
                    style: AppTheme.heading3.copyWith(color: AppTheme.hard),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMessage!,
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: loadUsers,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Users',
                                    style: AppTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${users.length}',
                                    style: AppTheme.heading1.copyWith(
                                      fontSize: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundCardLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: AppTheme.accent,
                                ),
                                tooltip: 'Refresh users',
                                onPressed: updating ? null : loadUsers,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Add user section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_add_rounded,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add New User',
                                  style: AppTheme.heading3.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    style: AppTheme.bodyLarge,
                                    enabled: !updating,
                                    decoration: InputDecoration(
                                      hintText: "Enter LeetCode username",
                                      hintStyle: AppTheme.bodyMedium,
                                      prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                        color: AppTheme.primary,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.backgroundCardLight,
                                    ),
                                    onSubmitted: (_) =>
                                        updating ? null : addUser(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: updating ? null : addUser,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text("Add User"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fetch stats button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: updating ? null : fetchStats,
                          icon: updating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded),
                          label: Text(
                            updating
                                ? "Updating Stats..."
                                : "Fetch Latest Stats for All Users",
                          ),
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ).copyWith(
                                backgroundColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Users list header
                      Row(
                        children: [
                          Icon(Icons.list_rounded, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Registered Users',
                            style: AppTheme.heading3.copyWith(fontSize: 18),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Users list
                      Expanded(
                        child: users.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_off_rounded,
                                      size: 64,
                                      color: AppTheme.textTertiary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No users yet',
                                      style: AppTheme.heading3.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add your first LeetCode user above',
                                      style: AppTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.cardGradient,
                                      borderRadius: AppTheme.cardRadius,
                                      boxShadow: AppTheme.softShadow,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        user['username'],
                                        style: AppTheme.heading3.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'ID: ${user['id']}',
                                        style: AppTheme.bodySmall,
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_rounded,
                                          color: AppTheme.hard,
                                        ),
                                        tooltip: 'Delete user',
                                        onPressed: updating
                                            ? null
                                            : () {
                                                deleteUser(
                                                  user['id'].toString(),
                                                  user['username'],
                                                );
                                              },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (updating)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
    );
  }
}
