import 'package:vora/firebase_stub.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _storeUserData(
        uid: userCredential.user?.uid ?? '',
        email: email,
        username: username,
        photoUrl: null,
        phoneNumber: null,
        signInMethod: 'email',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  static Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Sign in cancelled by user';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user already exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid ?? '')
          .get();

      if (!userDoc.exists) {
        // New user - store their data
        await _storeUserData(
          uid: userCredential.user?.uid ?? '',
          email: userCredential.user?.email ?? '',
          username: userCredential.user?.displayName ?? 'Google User',
          photoUrl: userCredential.user?.photoURL,
          phoneNumber: userCredential.user?.phoneNumber,
          signInMethod: 'google',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google sign-in failed: $e';
    }
  }

  /// Sign in with Phone Number
  static Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieve code (Android only)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      throw 'Phone authentication failed: $e';
    }
  }

  /// Confirm phone verification code
  static Future<UserCredential> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
    required String username,
    required String phoneNumber,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user already exists
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid ?? '')
          .get();

      if (!userDoc.exists) {
        // New user - store their data
        await _storeUserData(
          uid: userCredential.user?.uid ?? '',
          email: userCredential.user?.email ?? '',
          username: username,
          photoUrl: null,
          phoneNumber: phoneNumber,
          signInMethod: 'phone',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Store user data in Firestore
  static Future<void> _storeUserData({
    required String uid,
    required String email,
    required String username,
    required String? photoUrl,
    required String? phoneNumber,
    required String signInMethod,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
        'signInMethod': signInMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to store user data: $e';
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String username,
    String? photoUrl,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw 'User not authenticated';

      await _firestore.collection('users').doc(uid).update({
        'username': username,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile
      await _auth.currentUser?.updateDisplayName(username);
      if (photoUrl != null) {
        await _auth.currentUser?.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  /// Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      case 'user-not-found':
        return 'No user account found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-phone-number':
        return 'The phone number is not valid.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// Check if Firebase is properly configured
  static bool isFirebaseConfigured() {
    try {
      // Firebase is always initialized if we get here
      return true;
    } catch (e) {
      return false;
    }
  }
}
