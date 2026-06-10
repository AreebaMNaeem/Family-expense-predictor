// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user != null && fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
        await user.reload();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'user-not-found':
        return Exception('No account found with this email.');
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Incorrect email or password.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'weak-password':
        return Exception('Password is too weak. Use at least 6 characters.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Check your internet connection.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}