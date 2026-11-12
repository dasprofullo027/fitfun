import 'exercise_model.dart';

class WorkoutExerciseModel {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int sets;
  final int reps;
  final double weightKg;
  final ExerciseModel? exercise;

  WorkoutExerciseModel({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 0.0,
    this.exercise,
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      id: json['id'] as String,
      workoutId: (json['workout_id'] as String?) ?? '',
      exerciseId: (json['exercise_id'] as String?) ?? '',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      exercise: json['exercises'] != null && json['exercises'] is Map
          ? ExerciseModel.fromJson(
              Map<String, dynamic>.from(json['exercises'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
    };
  }

  WorkoutExerciseModel copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? sets,
    int? reps,
    double? weightKg,
    ExerciseModel? exercise,
  }) {
    return WorkoutExerciseModel(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      exercise: exercise ?? this.exercise,
    );
  }
}
