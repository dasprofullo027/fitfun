import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../models/workout_log_model.dart';
import '../services/workout_service.dart';
import '../services/log_service.dart';

class WorkoutProvider with ChangeNotifier {
  final WorkoutService _workoutService = WorkoutService();
  final LogService _logService = LogService();

  List<WorkoutModel> _workouts = [];
  List<WorkoutLogModel> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Active workout state
  WorkoutModel? _activeWorkout;
  int _workoutElapsedSeconds = 0;
  Timer? _workoutTimer;

  // Rest timer state
  int _restRemainingSeconds = 0;
  int _restInitialSeconds = 60;
  bool _isRestTimerRunning = false;
  Timer? _restTimer;

  // Completed sets tracker: exerciseId -> Set of completed set indices (0-indexed)
  final Map<String, Set<int>> _completedSets = {};

  List<WorkoutModel> get workouts => _workouts;
  List<WorkoutLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WorkoutModel? get activeWorkout => _activeWorkout;
  int get workoutElapsedSeconds => _workoutElapsedSeconds;
  int get restRemainingSeconds => _restRemainingSeconds;
  int get restInitialSeconds => _restInitialSeconds;
  bool get isRestTimerRunning => _isRestTimerRunning;

  // Today's scheduled or active workout
  WorkoutModel? get todayWorkout {
    final now = DateTime.now();
    try {
      return _workouts.firstWhere((w) {
        if (w.scheduledDate == null) return false;
        return w.scheduledDate!.year == now.year &&
            w.scheduledDate!.month == now.month &&
            w.scheduledDate!.day == now.day;
      });
    } catch (_) {
      return _workouts.isNotEmpty ? _workouts.first : null;
    }
  }

  int get totalCompletedWorkouts => _workouts.where((w) => w.isCompleted).length;

  Future<void> loadAll() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final results = await Future.wait([
        _workoutService.getWorkouts(),
        _logService.getLogs(ascending: true),
      ]);

      _workouts = results[0] as List<WorkoutModel>;
      _logs = results[1] as List<WorkoutLogModel>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkouts() async {
    try {
      _workouts = await _workoutService.getWorkouts();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadLogs() async {
    try {
      _logs = await _logService.getLogs(ascending: true);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createWorkout({
    required String title,
    DateTime? scheduledDate,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final newWorkout = await _workoutService.createWorkout(
        title: title,
        scheduledDate: scheduledDate,
        exercises: exercises,
      );

      _workouts.insert(0, newWorkout);
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

  Future<bool> updateWorkout({
    required String id,
    required String title,
    DateTime? scheduledDate,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updated = await _workoutService.updateWorkout(
        id: id,
        title: title,
        scheduledDate: scheduledDate,
        exercises: exercises,
      );

      final index = _workouts.indexWhere((w) => w.id == id);
      if (index != -1) {
        _workouts[index] = updated;
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

  Future<void> toggleWorkoutCompletion(String id, bool isCompleted) async {
    try {
      await _workoutService.updateWorkoutCompletion(id, isCompleted);
      final index = _workouts.indexWhere((w) => w.id == id);
      if (index != -1) {
        _workouts[index] = _workouts[index].copyWith(isCompleted: isCompleted);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteWorkout(String id) async {
    try {
      await _workoutService.deleteWorkout(id);
      _workouts.removeWhere((w) => w.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> finishAndLogWorkout({
    String? workoutId,
    required int durationMinutes,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final log = await _logService.createLog(
        workoutId: workoutId,
        durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
        notes: notes,
      );

      _logs.add(log);

      if (workoutId != null) {
        await _workoutService.updateWorkoutCompletion(workoutId, true);
        final index = _workouts.indexWhere((w) => w.id == workoutId);
        if (index != -1) {
          _workouts[index] = _workouts[index].copyWith(isCompleted: true);
        }
      }

      stopActiveWorkout();
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

  Future<bool> deleteLog(String logId) async {
    try {
      await _logService.deleteLog(logId);
      _logs.removeWhere((l) => l.id == logId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Active workout routines
  void startActiveWorkout(WorkoutModel workout) {
    _activeWorkout = workout;
    _workoutElapsedSeconds = 0;
    _completedSets.clear();
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _isRestTimerRunning = false;
    _restRemainingSeconds = 0;

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _workoutElapsedSeconds++;
      notifyListeners();
    });

    notifyListeners();
  }

  void stopActiveWorkout() {
    _workoutTimer?.cancel();
    _workoutTimer = null;
    _restTimer?.cancel();
    _restTimer = null;
    _activeWorkout = null;
    _workoutElapsedSeconds = 0;
    _completedSets.clear();
    _isRestTimerRunning = false;
    _restRemainingSeconds = 0;
  }

  bool isSetCompleted(String exerciseId, int setIndex) {
    return _completedSets[exerciseId]?.contains(setIndex) ?? false;
  }

  void toggleSetCompleted(String exerciseId, int setIndex, {bool triggerRest = true}) {
    if (!_completedSets.containsKey(exerciseId)) {
      _completedSets[exerciseId] = <int>{};
    }

    final sets = _completedSets[exerciseId]!;
    if (sets.contains(setIndex)) {
      sets.remove(setIndex);
    } else {
      sets.add(setIndex);
      if (triggerRest) {
        startRestTimer(_restInitialSeconds);
      }
    }
    notifyListeners();
  }

  void startRestTimer([int? seconds]) {
    if (seconds != null) {
      _restInitialSeconds = seconds;
      _restRemainingSeconds = seconds;
    } else if (_restRemainingSeconds == 0) {
      _restRemainingSeconds = _restInitialSeconds;
    }

    _restTimer?.cancel();
    _isRestTimerRunning = true;
    notifyListeners();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemainingSeconds > 0) {
        _restRemainingSeconds--;
        notifyListeners();
      } else {
        pauseRestTimer();
      }
    });
  }

  void pauseRestTimer() {
    _restTimer?.cancel();
    _isRestTimerRunning = false;
    notifyListeners();
  }

  void resetRestTimer([int? seconds]) {
    _restTimer?.cancel();
    _isRestTimerRunning = false;
    if (seconds != null) {
      _restInitialSeconds = seconds;
    }
    _restRemainingSeconds = _restInitialSeconds;
    notifyListeners();
  }

  void addRestSeconds(int seconds) {
    _restRemainingSeconds += seconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}
