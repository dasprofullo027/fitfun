import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/workout_provider.dart';

class WorkoutFormScreen extends StatefulWidget {
  final WorkoutModel? workout;

  const WorkoutFormScreen({super.key, this.workout});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  DateTime? _scheduledDate;
  bool _isEditing = false;
  bool _isSaving = false;

  // Selected exercises configuration:
  // Each item is: {
  //   'exercise': ExerciseModel,
  //   'sets': int,
  //   'reps': int,
  //   'weight_kg': double,
  // }
  final List<Map<String, dynamic>> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.workout != null;
    _titleController = TextEditingController(text: widget.workout?.title ?? '');
    _scheduledDate = widget.workout?.scheduledDate ?? DateTime.now();

    if (_isEditing && widget.workout != null) {
      for (final we in widget.workout!.exercises) {
        if (we.exercise != null) {
          _selectedExercises.add({
            'exercise': we.exercise!,
            'sets': we.sets,
            'reps': we.reps,
            'weight_kg': we.weightKg,
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  void _showAddExerciseBottomSheet() {
    final exerciseProvider =
        Provider.of<ExerciseProvider>(context, listen: false);
    final allExercises = exerciseProvider.exercises;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Exercise',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.surfaceAlt),
                Expanded(
                  child: allExercises.isEmpty
                      ? const Center(
                          child: Text(
                            'No exercises found. Add exercises in the Exercise Library.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: allExercises.length,
                          separatorBuilder: (context, index) =>
                              const Divider(color: AppColors.surfaceAlt, height: 1),
                          itemBuilder: (context, index) {
                            final ex = allExercises[index];
                            final isAlreadyAdded = _selectedExercises
                                .any((item) => item['exercise'].id == ex.id);

                            return ListTile(
                              title: Text(
                                ex.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                ex.muscleGroup ?? 'General',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isAlreadyAdded
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.primary)
                                  : const Icon(Icons.add_circle_outline,
                                      color: AppColors.textSecondary),
                              onTap: () {
                                if (!isAlreadyAdded) {
                                  setState(() {
                                    _selectedExercises.add({
                                      'exercise': ex,
                                      'sets': 3,
                                      'reps': 10,
                                      'weight_kg': 0.0,
                                    });
                                  });
                                }
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise to your workout routine'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    final exercisePayload = _selectedExercises.map((item) {
      final ExerciseModel ex = item['exercise'];
      return {
        'exercise_id': ex.id,
        'sets': item['sets'],
        'reps': item['reps'],
        'weight_kg': item['weight_kg'],
      };
    }).toList();

    bool success;
    if (_isEditing) {
      success = await workoutProvider.updateWorkout(
        id: widget.workout!.id,
        title: _titleController.text.trim(),
        scheduledDate: _scheduledDate,
        exercises: exercisePayload,
      );
    } else {
      success = await workoutProvider.createWorkout(
        title: _titleController.text.trim(),
        scheduledDate: _scheduledDate,
        exercises: exercisePayload,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Workout updated successfully'
              : 'Workout routine created!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              workoutProvider.errorMessage ?? 'Failed to save workout routine'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Workout Plan' : 'Build Workout Plan',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Workout Title
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (val) => Validators.required(val, 'Workout title'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Workout Title *',
                  hintText: 'e.g. Upper Body Hypertrophy',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.fitness_center_rounded,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.buttonRadius),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.buttonRadius),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scheduled Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius:
                        BorderRadius.circular(AppConstants.buttonRadius),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scheduled Date',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _scheduledDate != null
                                  ? DateFormat('EEEE, MMMM d, yyyy')
                                      .format(_scheduledDate!)
                                  : 'Pick a date',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Exercises List Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Routine Exercises',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddExerciseBottomSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Exercise'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_selectedExercises.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardRadius),
                    border: Border.all(
                      color: AppColors.surfaceAlt,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.playlist_add,
                          size: 40, color: AppColors.textSecondary),
                      SizedBox(height: 10),
                      Text(
                        'No exercises in routine yet',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap "Add Exercise" to select from your library and set sets, reps, and weights.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._selectedExercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final ExerciseModel ex = item['exercise'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    ex.muscleGroup ?? 'General',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedExercises.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Sets, Reps & Weight Configuration Row
                        Row(
                          children: [
                            // Sets Stepper
                            Expanded(
                              child: _buildStepper(
                                label: 'SETS',
                                value: item['sets'],
                                onDecremented: () {
                                  if (item['sets'] > 1) {
                                    setState(() => item['sets']--);
                                  }
                                },
                                onIncremented: () {
                                  setState(() => item['sets']++);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Reps Stepper
                            Expanded(
                              child: _buildStepper(
                                label: 'REPS',
                                value: item['reps'],
                                onDecremented: () {
                                  if (item['reps'] > 1) {
                                    setState(() => item['reps']--);
                                  }
                                },
                                onIncremented: () {
                                  setState(() => item['reps']++);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Weight (kg) Stepper
                            Expanded(
                              child: _buildStepper(
                                label: 'KG',
                                value: (item['weight_kg'] as double).round(),
                                onDecremented: () {
                                  if (item['weight_kg'] >= 2.5) {
                                    setState(() => item['weight_kg'] -= 2.5);
                                  }
                                },
                                onIncremented: () {
                                  setState(() => item['weight_kg'] += 2.5);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.buttonRadius),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEditing ? 'UPDATE WORKOUT' : 'SAVE WORKOUT PLAN',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required VoidCallback onDecremented,
    required VoidCallback onIncremented,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: onDecremented,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.remove, size: 14, color: AppColors.primary),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onIncremented,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.add, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
