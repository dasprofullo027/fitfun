import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';

class ExerciseProvider with ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();

  List<ExerciseModel> _exercises = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedMuscleGroup = 'All';
  String _searchQuery = '';

  List<ExerciseModel> get exercises => _exercises;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedMuscleGroup => _selectedMuscleGroup;
  String get searchQuery => _searchQuery;

  List<ExerciseModel> get filteredExercises {
    return _exercises.where((e) {
      final matchesGroup = _selectedMuscleGroup == 'All' ||
          (e.muscleGroup?.toLowerCase() == _selectedMuscleGroup.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (e.muscleGroup?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesGroup && matchesSearch;
    }).toList();
  }

  Future<void> loadExercises() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _exerciseService.seedDefaultExercisesIfEmpty();
      _exercises = await _exerciseService.getExercises();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMuscleGroup(String group) {
    _selectedMuscleGroup = group;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addExercise({
    required String name,
    required String muscleGroup,
    String? description,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final newExercise = await _exerciseService.createExercise(
        name: name,
        muscleGroup: muscleGroup,
        description: description,
        imageUrl: imageUrl,
      );
      _exercises.insert(0, newExercise);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editExercise({
    required String id,
    required String name,
    required String muscleGroup,
    String? description,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updated = await _exerciseService.updateExercise(
        id: id,
        name: name,
        muscleGroup: muscleGroup,
        description: description,
        imageUrl: imageUrl,
      );

      final index = _exercises.indexWhere((e) => e.id == id);
      if (index != -1) {
        _exercises[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeExercise(String id) async {
    try {
      await _exerciseService.deleteExercise(id);
      _exercises.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
