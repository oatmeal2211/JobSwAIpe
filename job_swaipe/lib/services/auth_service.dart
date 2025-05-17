import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Device ID for tracking anonymous reviews
  static const String _deviceIdKey = 'device_id_for_anon_reviews';
  
  // Temporary device ID to use if SharedPreferences fails
  static String? _tempDeviceId;
  
  // Get current user's device ID (creates one if doesn't exist)
  Future<String> getDeviceId() async {
    try {
      // First try SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);
      
      if (deviceId == null) {
        // Generate a new device ID
        deviceId = const Uuid().v4();
        await prefs.setString(_deviceIdKey, deviceId);
      }
      
      return deviceId;
    } catch (e) {
      // If SharedPreferences fails (not installed yet), use a temporary ID
      _tempDeviceId ??= const Uuid().v4();
      print('Using fallback device ID method: $e');
      return _tempDeviceId!;
    }
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      return _auth.currentUser != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during sign in';
    } catch (e) {
      throw 'Failed to sign in: ${e.toString()}';
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during registration';
    } catch (e) {
      throw 'Failed to register: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw 'Failed to sign out: ${e.toString()}';
    }
  }

  // Get current user
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Check if user owns a review
  bool isUserOwnerOfReview(String? reviewUserId) {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || reviewUserId == null) {
        return false;
      }
      return currentUser.uid == reviewUserId;
    } catch (e) {
      print('Error checking review ownership: $e');
      return false;
    }
  }
} 