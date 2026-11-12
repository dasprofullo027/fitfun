import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/routes.dart';
import 'core/supabase_config.dart';
import 'models/exercise_model.dart';
import 'models/workout_model.dart';
import 'providers/auth_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/exercises/exercise_form_screen.dart';
import 'screens/exercises/exercise_list_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/workouts/active_workout_screen.dart';
import 'screens/workouts/workout_detail_screen.dart';
import 'screens/workouts/workout_form_screen.dart';
import 'screens/workouts/workout_list_screen.dart';

// Global client — use anywhere in the app (PRD Section 2)
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const FitForgeApp());
}

class FitForgeApp extends StatelessWidget {
  const FitForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: MaterialApp(
        title: 'FitForge',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          cardColor: AppColors.surface,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            primaryContainer: AppColors.primaryContainer,
            secondary: AppColors.secondary,
            onSecondary: AppColors.onPrimary,
            surface: AppColors.surface,
            onSurface: AppColors.onSurface,
            surfaceVariant: AppColors.surfaceVariant,
            onSurfaceVariant: AppColors.onSurfaceVariant,
            error: AppColors.error,
            onError: AppColors.onPrimary,
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.light().textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
            ),
          ),
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case AppRoutes.login:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case AppRoutes.register:
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case AppRoutes.home:
              return MaterialPageRoute(
                  builder: (_) => const MainNavigationScreen());
            case AppRoutes.exercises:
              return MaterialPageRoute(
                  builder: (_) => const ExerciseListScreen());
            case AppRoutes.exerciseForm:
              final exercise = settings.arguments as ExerciseModel?;
              return MaterialPageRoute(
                builder: (_) => ExerciseFormScreen(exercise: exercise),
              );
            case AppRoutes.workouts:
              return MaterialPageRoute(
                  builder: (_) => const WorkoutListScreen());
            case AppRoutes.workoutDetail:
              final workout = settings.arguments as WorkoutModel?;
              return MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(workout: workout),
              );
            case AppRoutes.workoutForm:
              final workout = settings.arguments as WorkoutModel?;
              return MaterialPageRoute(
                builder: (_) => WorkoutFormScreen(workout: workout),
              );
            case AppRoutes.activeWorkout:
              final workout = settings.arguments as WorkoutModel?;
              return MaterialPageRoute(
                builder: (_) => ActiveWorkoutScreen(workout: workout),
              );
            case AppRoutes.progress:
              return MaterialPageRoute(builder: (_) => const ProgressScreen());
            case AppRoutes.profile:
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Page not found')),
                ),
              );
          }
        },
      ),
    );
  }
}
