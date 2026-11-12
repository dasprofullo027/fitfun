import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_model.dart';

class WorkoutService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<WorkoutModel>> getWorkouts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('workouts')
        .select('*, workout_exercises(*, exercises(*))')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (res as List)
        .map((w) => WorkoutModel.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();
  }

  Future<WorkoutModel> getWorkoutById(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final res = await _client
        .from('workouts')
        .select('*, workout_exercises(*, exercises(*))')
        .eq('id', id)
        .eq('user_id', user.id)
        .single();

    return WorkoutModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<WorkoutModel> createWorkout({
    required String title,
    DateTime? scheduledDate,
    required List<Map<String, dynamic>> exercises, // list of {exercise_id, sets, reps, weight_kg}
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

    final workoutData = {
      'user_id': user.id,
      'title': title.trim(),
      if (scheduledDate != null)
        'scheduled_date':
            "${scheduledDate.year.toString().padLeft(4, '0')}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}",
      'is_completed': false,
    };

    final workoutRes =
        await _client.from('workouts').insert(workoutData).select().single();
    final workoutId = workoutRes['id'] as String;

    if (exercises.isNotEmpty) {
      final exercisesToInsert = exercises.map((e) {
        return {
          'workout_id': workoutId,
          'exercise_id': e['exercise_id'],
          'sets': e['sets'] ?? 3,
          'reps': e['reps'] ?? 10,
          'weight_kg': (e['weight_kg'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();

      await _client.from('workout_exercises').insert(exercisesToInsert);
    }

    return await getWorkoutById(workoutId);
  }

  Future<WorkoutModel> updateWorkout({
    required String id,
    required String title,
    DateTime? scheduledDate,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = {
      'title': title.trim(),
      'scheduled_date': scheduledDate != null
          ? "${scheduledDate.year.toString().padLeft(4, '0')}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}"
          : null,
    };

    await _client
        .from('workouts')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', user.id);

    // Replace linked exercises
    await _client.from('workout_exercises').delete().eq('workout_id', id);

    if (exercises.isNotEmpty) {
      final exercisesToInsert = exercises.map((e) {
        return {
          'workout_id': id,
          'exercise_id': e['exercise_id'],
          'sets': e['sets'] ?? 3,
          'reps': e['reps'] ?? 10,
          'weight_kg': (e['weight_kg'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();

      await _client.from('workout_exercises').insert(exercisesToInsert);
    }

    return await getWorkoutById(id);
  }

  Future<void> updateWorkoutCompletion(String id, bool isCompleted) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('workouts')
        .update({'is_completed': isCompleted})
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> deleteWorkout(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Due to ON DELETE CASCADE on foreign keys in schema,
    // deleting workouts also cleans up workout_exercises and workout_logs if referenced
    await _client
        .from('workouts')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
