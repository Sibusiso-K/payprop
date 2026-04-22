import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseMessaging _messaging;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseMessaging? messaging,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchUserModel(user.uid);
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUserModel(cred.user!.uid);
  }

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final fcmToken = await _messaging.getToken();

    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      profileComplete: false,
      fcmToken: fcmToken,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<void> sendOtp(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {},
      verificationFailed: (e) => throw e,
      codeSent: (_, __) {},
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateFcmToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _db.collection('users').doc(uid).update({'fcmToken': token});
    }
  }

  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return UserModel.fromMap(doc.data()!, uid);
  }
}
