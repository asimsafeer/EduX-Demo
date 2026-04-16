/// NovaByte Hub — Firebase Authentication Service
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Handles admin authentication via Firebase Auth
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user (null if not signed in)
  User? get currentUser => _auth.currentUser;

  /// Whether the user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Sign in with email and password
  ///
  /// Returns the [UserCredential] on success.
  /// Throws [AuthException] with a user-friendly message on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Verify the user exists in the admins collection
      final adminDoc = await _firestore
          .collection(FirestoreCollections.admins)
          .doc(credential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        // User authenticated but not an admin — create admin profile
        await _firestore
            .collection(FirestoreCollections.admins)
            .doc(credential.user!.uid)
            .set({
              'name': credential.user!.displayName ?? 'Admin',
              'email': credential.user!.email,
              'role': 'super_admin',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get the admin's display name
  Future<String> getAdminName() async {
    final user = _auth.currentUser;
    if (user == null) return 'Admin';

    final doc = await _firestore
        .collection(FirestoreCollections.admins)
        .doc(user.uid)
        .get();

    if (doc.exists) {
      return doc.data()?['name'] as String? ?? 'Admin';
    }

    return user.displayName ?? 'Admin';
  }

  /// Get the admin's email
  String? getAdminEmail() => _auth.currentUser?.email;

  /// Get the admin's UID (used as grantedBy in licenses)
  String? getAdminUid() => _auth.currentUser?.uid;

  /// Update admin display name
  Future<void> updateAdminName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(name);
    await _firestore
        .collection(FirestoreCollections.admins)
        .doc(user.uid)
        .update({'name': name});
  }

  /// Map Firebase Auth error codes to user-friendly messages
  String _mapFirebaseAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No admin account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Custom exception for auth errors
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
