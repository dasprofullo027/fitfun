import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_model.dart';

class ExerciseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ExerciseModel>> getExercises({String? muscleGroup, String? searchQuery}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('exercises')
        .select()
        .eq('user_id', user.id);

    final res = await query.order('created_at', ascending: false);

    List<ExerciseModel> exercises = (res as List)
        .map((e) => ExerciseModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Client-side filtering if needed
    if (muscleGroup != null && muscleGroup.isNotEmpty && muscleGroup != 'All') {
      exercises = exercises
          .where((e) => e.muscleGroup?.toLowerCase() == muscleGroup.toLowerCase())
          .toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = searchQuery.toLowerCase().trim();
      exercises = exercises
          .where((e) =>
              e.name.toLowerCase().contains(term) ||
              (e.description?.toLowerCase().contains(term) ?? false) ||
              (e.muscleGroup?.toLowerCase().contains(term) ?? false))
          .toList();
    }

    return exercises;
  }

  Future<ExerciseModel> createExercise({
    required String name,
    required String muscleGroup,
    String? description,
    String? imageUrl,
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
      'name': name.trim(),
      'muscle_group': muscleGroup.trim(),
      'description': description?.trim(),
      'image_url': imageUrl?.trim(),
    };

    final res = await _client.from('exercises').insert(data).select().single();
    return ExerciseModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<ExerciseModel> updateExercise({
    required String id,
    required String name,
    required String muscleGroup,
    String? description,
    String? imageUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final data = {
      'name': name.trim(),
      'muscle_group': muscleGroup.trim(),
      'description': description?.trim(),
      'image_url': imageUrl?.trim(),
    };

    final res = await _client
        .from('exercises')
        .update(data)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();

    return ExerciseModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> deleteExercise(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('exercises')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  /// Seeds default beginner exercises if user's exercise list is empty
  Future<void> seedDefaultExercisesIfEmpty() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final existing = await _client
        .from('exercises')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if ((existing as List).isEmpty) {
      final defaults = [
        {
          'user_id': user.id,
          'name': 'Standard Push Up',
          'muscle_group': 'Chest',
          'description': 'Classic bodyweight push up targeting chest, shoulders, and triceps.',
        },
        {
          'user_id': user.id,
          'name': 'Barbell Bench Press',
          'muscle_group': 'Chest',
          'description': 'Compound pressing movement on flat bench for pectorals.',
        },
        {
          'user_id': user.id,
          'name': 'Pull-Up',
          'muscle_group': 'Back',
          'description': 'Vertical pull targeting lats, upper back, and biceps.',
        },
        {
          'user_id': user.id,
          'name': 'Barbell Deadlift',
          'muscle_group': 'Back',
          'description': 'Posterior chain powerhouse targeting back, glutes, and hamstrings.',
        },
        {
          'user_id': user.id,
          'name': 'Barbell Squat',
          'muscle_group': 'Legs',
          'description': 'Fundamental lower body strength builder for quads and glutes.',
        },
        {
          'user_id': user.id,
          'name': 'Overhead Shoulder Press',
          'muscle_group': 'Shoulders',
          'description': 'Standing or seated overhead dumbbell/barbell press for deltoids.',
        },
        {
          'user_id': user.id,
          'name': 'Bicep Dumbbell Curl',
          'muscle_group': 'Arms',
          'description': 'Isolation exercise for bicep peaks.',
        },
        {
          'user_id': user.id,
          'name': 'Tricep Rope Pushdown',
          'muscle_group': 'Arms',
          'description': 'Cable isolation movement targeting lateral and medial triceps.',
        },
        {
          'user_id': user.id,
          'name': 'Plank',
          'muscle_group': 'Core',
          'description': 'Isometric core stability exercise maintaining straight body line.',
        },
      ];

      await _client.from('exercises').insert(defaults);
    }
  }
}
