import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_log_model.dart';

class LogService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<WorkoutLogModel>> getLogs({bool ascending = true}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('workout_logs')
        .select('*, workouts(title)')
        .eq('user_id', user.id)
        .order('logged_at', ascending: ascending);

    return (res as List)
        .map((l) => WorkoutLogModel.fromJson(Map<String, dynamic>.from(l as Map)))
        .toList();
  }

  Future<WorkoutLogModel> createLog({
    String? workoutId,
    required int durationMinutes,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Ensure profile exists for the user to satisfy foreign key constraint
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'FitForge Athlete',
        'email': user.email ?? '',
        'goal': 'Build Muscle',
        'streak': 0,
      });
    } catch (_) {}

    final data = {
      'user_id': user.id,
      if (workoutId != null) 'workout_id': workoutId,
      'duration_minutes': durationMinutes,
      'notes': notes?.trim(),
      'logged_at': DateTime.now().toIso8601String(),
    };

    final res = await _client
        .from('workout_logs')
        .insert(data)
        .select('*, workouts(title)')
        .single();

    final log = WorkoutLogModel.fromJson(Map<String, dynamic>.from(res));

    // Calculate and update user streak
    await recalculateAndUpdateStreak();

    return log;
  }

  Future<void> deleteLog(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('workout_logs')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);

    await recalculateAndUpdateStreak();
  }

  Future<int> recalculateAndUpdateStreak() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final logs = await getLogs(ascending: false);
    if (logs.isEmpty) {
      await _client.from('profiles').update({'streak': 0}).eq('id', user.id);
      return 0;
    }

    // Extract unique dates of completed workouts (normalized to yyyy-MM-dd)
    final Set<String> uniqueDates = {};
    for (final log in logs) {
      final d = log.loggedAt;
      uniqueDates.add("${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");
    }

    final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    int currentStreak = 0;
    // Check if the user logged today or yesterday
    if (sortedDates.contains(todayStr) || sortedDates.contains(yesterdayStr)) {
      DateTime checkDate = sortedDates.contains(todayStr) ? now : yesterday;
      while (true) {
        final dStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
        if (uniqueDates.contains(dStr)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    await _client.from('profiles').update({'streak': currentStreak}).eq('id', user.id);
    return currentStreak;
  }
}
