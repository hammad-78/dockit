import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthLoginResult {
  const AuthLoginResult({required this.user, this.role});

  final User user;
  final String? role;
}

class AuthService {
  // Get the instance of Firebase Auth
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registers a new user with an email and password.
  /// Returns the authenticated [User] object on success, or null if an error occurs.
  Future<User?> signUpWithEmailAndPassword(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      // Trigger the Firebase signup method
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      await saveUserInfo(user: user, name: name, role: role);
      return user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('An account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        print('The provided email format is invalid.');
      } else {
        print('Firebase Auth Error: ${e.message}');
      }
    } catch (e) {
      // Handle generic errors (e.g., network issues)
      print('An unexpected error occurred: $e');
    }
    return null;
  }

  /// Saves the authenticated user's profile in Firestore.
  Future<void> saveUserInfo({
    required User user,
    required String name,
    required String role,
  }) async {
    await _firestore.collection('users').doc(user.uid).set({
      'id': user.uid,
      'email': user.email,
      'name': name.trim(),
      'role': role,
    });
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final document = await _firestore.collection('users').doc(user.uid).get();
    final data = document.data() ?? <String, dynamic>{};
    data['id'] = user.uid;
    data['email'] ??= user.email;
    return data;
  }

  Future<void> updateUserName(String name) async {
    final user = _auth.currentUser;
    final trimmedName = name.trim();
    if (user == null) throw StateError('No authenticated user found.');
    if (trimmedName.isEmpty) throw ArgumentError('Name cannot be empty.');

    await user.updateDisplayName(trimmedName);
    await _firestore.collection('users').doc(user.uid).update({
      'name': trimmedName,
    });
  }

  Future<void> changePassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }

    await user.updatePassword(password);
  }

  /// Signs in an existing user with an email and password.
  /// Returns the authenticated user and Firestore role on success.
  static Future<AuthLoginResult?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Trigger the Firebase signin method
      UserCredential credential = await AuthService._auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      final user = credential.user;
      if (user == null) return null;

      final userDocument = await AuthService._firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDocument.data();
      final role = userData == null ? null : userData['role'] as String?;

      return AuthLoginResult(user: user, role: role);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        print('Invalid email or password combination.');
      } else if (e.code == 'invalid-email') {
        print('The provided email format is invalid.');
      } else if (e.code == 'user-disabled') {
        print('This user account has been disabled.');
      } else {
        print('Firebase Auth Error: ${e.message}');
      }
    } catch (e) {
      // Handle generic errors
      print('An unexpected error occurred: $e');
    }
    return null;
  }

  Future<void> signOutUser() async {
    try {
      // Clear the active authentication session from Firebase
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Catch any unexpected system or network errors
      print('An unexpected error occurred during logout: $e');
    }
  }
}
