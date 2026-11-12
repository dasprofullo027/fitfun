import 'workout_exercise_model.dart';

class WorkoutModel {
  final String id;
  final String userId;
  final String title;
  final DateTime? scheduledDate;
  final bool isCompleted;
  final DateTime? createdAt;
  final List<WorkoutExerciseModel> exercises;

  WorkoutModel({
    required this.id,
    required this.userId,
    required this.title,
    this.scheduledDate,
    this.isCompleted = false,
    this.createdAt,
    this.exercises = const [],
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    List<WorkoutExerciseModel> parsedExercises = [];
    if (json['workout_exercises'] != null &&
        json['workout_exercises'] is List) {
      parsedExercises = (json['workout_exercises'] as List)
          .map((e) =>
              WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    DateTime? parsedDate;
    if (json['scheduled_date'] != null) {
      parsedDate = DateTime.tryParse(json['scheduled_date'].toString());
    }

    return WorkoutModel(
      id: json['id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      scheduledDate: parsedDate,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      exercises: parsedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      if (scheduledDate != null)
        'scheduled_date':
            "${scheduledDate!.year.toString().padLeft(4, '0')}-${scheduledDate!.month.toString().padLeft(2, '0')}-${scheduledDate!.day.toString().padLeft(2, '0')}",
      'is_completed': isCompleted,
    };
  }

  WorkoutModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? scheduledDate,
    bool? isCompleted,
    DateTime? createdAt,
    List<WorkoutExerciseModel>? exercises,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      exercises: exercises ?? this.exercises,
    );
  }
}
