class ExerciseModel {
  final String id;
  final String? userId;
  final String name;
  final String? muscleGroup;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  ExerciseModel({
    required this.id,
    this.userId,
    required this.name,
    this.muscleGroup,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: (json['name'] as String?) ?? '',
      muscleGroup: json['muscle_group'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'muscle_group': muscleGroup,
      'description': description,
      'image_url': imageUrl,
    };
  }

  ExerciseModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? muscleGroup,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
