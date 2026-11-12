class WorkoutLogModel {
  final String id;
  final String userId;
  final String? workoutId;
  final DateTime loggedAt;
  final int durationMinutes;
  final String? notes;
  final String? workoutTitle;

  WorkoutLogModel({
    required this.id,
    required this.userId,
    this.workoutId,
    required this.loggedAt,
    this.durationMinutes = 0,
    this.notes,
    this.workoutTitle,
  });

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    String? title;
    if (json['workouts'] != null && json['workouts'] is Map) {
      title = json['workouts']['title'] as String?;
    }

    return WorkoutLogModel(
      id: json['id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      workoutId: json['workout_id'] as String?,
      loggedAt: json['logged_at'] != null
          ? DateTime.tryParse(json['logged_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      workoutTitle: title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (workoutId != null) 'workout_id': workoutId,
      'logged_at': loggedAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
    };
  }

  WorkoutLogModel copyWith({
    String? id,
    String? userId,
    String? workoutId,
    DateTime? loggedAt,
    int? durationMinutes,
    String? notes,
    String? workoutTitle,
  }) {
    return WorkoutLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      loggedAt: loggedAt ?? this.loggedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      workoutTitle: workoutTitle ?? this.workoutTitle,
    );
  }
}
