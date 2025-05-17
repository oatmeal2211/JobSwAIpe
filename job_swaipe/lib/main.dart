import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:job_swaipe/screens/auth/login_screen.dart';
import 'package:job_swaipe/screens/auth/register_screen.dart';
import 'package:job_swaipe/screens/home_screen.dart';
import 'package:job_swaipe/screens/onboarding/onboarding_screen.dart';
import 'package:job_swaipe/services/auth_service.dart';
import 'package:job_swaipe/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file first
  try {
    await dotenv.load();
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
    // If .env fails to load, we should handle defaults in the app
  }
  
  // Initialize Firebase after loading env variables
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobSwAIpe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: Colors.lightBlue,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/onboarding') {
          final String userId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => OnboardingScreen(userId: userId),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    
    return FutureBuilder<bool>(
      future: authService.isUserLoggedIn(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        // If user is logged in
        if (authSnapshot.data == true) {
          // Check if onboarding is completed
          return FutureBuilder<bool>(
            future: authService.isOnboardingCompleted(),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              
              // If onboarding is completed, go to home screen
              if (onboardingSnapshot.data == true) {
                return const HomeScreen();
              } 
              // If onboarding is not completed, go to onboarding screen
              else {
                final user = authService.getCurrentUser();
                if (user != null) {
                  return OnboardingScreen(userId: user.uid);
                }
                return const LoginScreen();
              }
            },
          );
        } 
        // If user is not logged in, go to login screen
        else {
          return const LoginScreen();
        }
      },
    );
  }
  
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/jobswaipe_logo.png',
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.work,
                  size: 80,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Loading JobSwAIpe...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
