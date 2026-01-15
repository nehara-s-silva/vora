// Lightweight development stub for Firebase APIs used in the app.
// This is a fallback so the analyzer doesn't break when the real
// Firebase packages are not installed. Replace with real packages
// when configuring Firebase for the project.

class Firebase {
  static Future<void> initializeApp({options}) async {}
}

// Auth stubs
class User {
  String? uid;
  String? email;
  String? displayName;
  String? phoneNumber;
  String? photoURL;

  User({
    this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
  });

  Future<void> updateDisplayName(String name) async {}
  Future<void> updatePhotoURL(String url) async {}
}

class UserCredential {
  final User? user;
  UserCredential({this.user});
}

class FirebaseAuthException implements Exception {
  final String code;
  final String? message;
  FirebaseAuthException({required this.code, this.message});
}

class FirebaseAuth {
  static final FirebaseAuth instance = FirebaseAuth._();
  User? currentUser;
  FirebaseAuth._();

  Stream<User?> authStateChanges() async* {}

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: 'unavailable',
      message: 'Firebase not configured in this environment',
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: 'unavailable',
      message: 'Firebase not configured in this environment',
    );
  }

  Future<UserCredential> signInWithCredential(dynamic credential) async {
    throw FirebaseAuthException(
      code: 'unavailable',
      message: 'Firebase not configured in this environment',
    );
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    throw FirebaseAuthException(
      code: 'unavailable',
      message: 'Firebase not configured in this environment',
    );
  }

  Future<void> signOut() async {}
}

class PhoneAuthCredential {}

class PhoneAuthProvider {
  static PhoneAuthCredential credential({
    required String verificationId,
    required String smsCode,
  }) => PhoneAuthCredential();
}

// Firestore stubs
class DocumentSnapshotStub {
  final Map<String, dynamic>? _data;
  DocumentSnapshotStub([this._data]);
  bool get exists => _data != null;
  Map<String, dynamic>? data() => _data;
}

class DocumentReferenceStub {
  final String id;
  DocumentReferenceStub(this.id);
  Future<DocumentSnapshotStub> get() async => DocumentSnapshotStub(null);
  Future<void> set(Map<String, dynamic> data) async {}
  Future<void> update(Map<String, dynamic> data) async {}
}

class CollectionReferenceStub {
  final String name;
  CollectionReferenceStub(this.name);
  DocumentReferenceStub doc([String? id]) => DocumentReferenceStub(id ?? '');
}

class FirebaseFirestore {
  static final FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();
  CollectionReferenceStub collection(String name) =>
      CollectionReferenceStub(name);
}

class FieldValue {
  static DateTime serverTimestamp() => DateTime.now();
}

// Google sign-in stub
class GoogleSignInAccount {
  Future<GoogleSignInAuthentication> get authentication async =>
      GoogleSignInAuthentication();
  String? get id => null;
}

class GoogleSignInAuthentication {
  String? accessToken;
  String? idToken;
}

class GoogleSignIn {
  Future<GoogleSignInAccount?> signIn() async => null;
  Future<void> signOut() async {}
}

class GoogleAuthProvider {
  static dynamic credential({String? accessToken, String? idToken}) => null;
}
