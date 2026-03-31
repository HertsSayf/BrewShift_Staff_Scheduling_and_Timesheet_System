import 'package:brew_shift/models/app_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Cloud-backed auth/profile service.
///
/// This service is intentionally limited to registration, sign-in, sign-out,
/// and reading the signed-in user profile. Attendance and rota data remain
/// local in the prototype.
class FirestoreStoreService {
  FirestoreStoreService._();

  static final FirestoreStoreService instance = FirestoreStoreService._();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  fb.User? get firebaseUser => _auth.currentUser;

  Future<AppUser?> getCurrentUserProfile() async {
    final user = firebaseUser;
    if (user == null) {
      return null;
    }

    final doc = await _usersCollection.doc(user.uid).get();
    if (!doc.exists) {
      return null;
    }

    return _mapUserProfile(user.uid, doc.data() ?? <String, dynamic>{});
  }

  Future<void> registerUser({
    required String fullName,
    required String staffId,
    required String email,
    required String password,
    required String role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    await _usersCollection.doc(credential.user!.uid).set({
      'fullName': fullName.trim(),
      'staffId': staffId.trim(),
      'email': cleanEmail,
      'role': role.trim().toLowerCase(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: identifier.trim().toLowerCase(),
        password: password,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  AppUser _mapUserProfile(String userId, Map<String, dynamic> data) {
    return AppUser(
      id: userId,
      fullName: data['fullName'] as String? ?? '',
      staffId: data['staffId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      password: '',
      role: data['role'] as String? ?? 'employee',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
