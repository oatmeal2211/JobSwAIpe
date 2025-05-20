import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:job_swaipe/screens/auth/login_screen.dart';
import 'package:job_swaipe/screens/auth/register_screen.dart';
import 'package:job_swaipe/screens/home_screen.dart';
import 'package:job_swaipe/screens/onboarding/onboarding_screen.dart';
import 'package:job_swaipe/screens/profile/profile_screen.dart';
import 'package:job_swaipe/screens/review_resume_page.dart';
import 'package:job_swaipe/screens/resume_result_page.dart';
import 'package:job_swaipe/screens/job_description_page.dart';
import 'package:job_swaipe/screens/job_match_result_page.dart';
import 'package:job_swaipe/screens/explore/my_learning_screen.dart';
import 'package:job_swaipe/services/auth_service.dart';
import 'package:job_swaipe/services/user_service.dart';
import 'package:job_swaipe/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // For Android emulator debugging, use debug provider
    androidProvider: AndroidProvider.debug,
    // For iOS simulator debugging
    appleProvider: AppleProvider.debug,
  );
  
  runApp(const JobSwAIpeApp());
}

class JobSwAIpeApp extends StatelessWidget {
  const JobSwAIpeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a color scheme
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0077FF), // Primary blue color
      brightness: Brightness.light,
      primary: const Color(0xFF0077FF),
      secondary: const Color(0xFF00C471), // Green accent
      background: const Color(0xFFF5F7FA),
      surface: Colors.white,
      error: const Color(0xFFFF3B30),
    );

    // Create a theme based on the color scheme
    final ThemeData theme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      
      // Apply Google Fonts for a modern, clean look
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorScheme.onBackground,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: colorScheme.onBackground,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.onBackground,
          ),
        ),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        color: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: colorScheme.primary.withOpacity(0.2),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          color: colorScheme.onBackground.withOpacity(0.7),
        ),
      ),
    );

    return MaterialApp(
      title: 'JobSwAIpe',
      theme: theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/review_resume': (context) => const ReviewResumePage(),
        '/resume_result': (context) => const ResumeResultPage(jsonResult: ''),
        '/job_description': (context) => const JobDescriptionPage(resumeJson: ''),
        '/my-learning': (context) => const MyLearningScreen(),
        '/job_match_result': (context) => const JobMatchResultPage(jsonResult: '', originalResumeJson: '',),
        '/profile': (context) => const ProfileScreen(),

      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userService = UserService();
    
    return FutureBuilder(
      future: authService.isUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.data == true) {
          // User is logged in, check if onboarding is completed
          return FutureBuilder<bool>(
            future: userService.hasCompletedOnboarding(),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // If onboarding is not completed, redirect to onboarding
              if (onboardingSnapshot.data == false) {
                return const OnboardingScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
