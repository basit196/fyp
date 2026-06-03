import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up with Email & Password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role, // 'worker' or 'user'
  }) async {
    try {
      // Create user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Email & Password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle({required String role}) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user document exists
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // First time login - create user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email ?? '',
          'phone': userCredential.user!.phoneNumber ?? '',
          'photoURL': userCredential.user!.photoURL ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Existing user - always update role to what they chose at login (User vs Worker)
        // so restart shows the correct side
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      throw 'Google Sign-In failed: ${e.toString()}';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email,
        // Optional: You can customize the action code settings here
        // actionCodeSettings: ActionCodeSettings(
        //   url: 'https://skilllink.com/reset-password',
        //   handleCodeInApp: true,
        // ),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email: ${e.toString()}';
    }
  }

  // Get User Role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Watch user data so role changes made during login are reflected immediately
  Stream<DocumentSnapshot> getUserDocumentStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Get User Data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile (name, phone) for client users
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    String? phone,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.updateDisplayName(name);
      }
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        if (phone != null) 'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update User Role
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If document doesn't exist, create it
      if (currentUser != null) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': currentUser!.displayName ?? 'User',
          'email': currentUser!.email ?? '',
          'phone': currentUser!.phoneNumber ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Create the worker profile shell needed by the worker dashboard.
  Future<void> ensureWorkerProfile(String uid) async {
    final workerRef = _firestore.collection('workers').doc(uid);
    final workerDoc = await workerRef.get();

    if (workerDoc.exists) {
      return;
    }

    final user = currentUser;
    final userData = await getUserData(uid);
    final name = userData?['name'] ??
        user?.displayName ??
        user?.email?.split('@').first ??
        'Worker';

    await workerRef.set({
      'id': uid,
      'name': name,
      'email': userData?['email'] ?? user?.email ?? '',
      'phone': userData?['phone'] ?? user?.phoneNumber ?? '',
      'profileImage': user?.photoURL ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=2563EB&color=fff',
      'description': '',
      'rating': 0.0,
      'totalJobs': 0,
      'skills': <String>[],
      'location': '',
      'latitude': null,
      'longitude': null,
      'isAvailable': true,
      'level': 'newbie',
      'yearsOfExperience': 0,
      'completedProjects': 0,
      'successRate': 100.0,
      'portfolio': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

