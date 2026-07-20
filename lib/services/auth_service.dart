import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _webClientId =
    '279323547618-tpcotlb0ndrhoscv2a20dtu2pqtibqui.apps.googleusercontent.com';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<void> initialize() async {
    _googleSignIn = GoogleSignIn.instance;
    await _googleSignIn!.initialize(
      serverClientId: _webClientId,
    );
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount account =
        await _googleSignIn!.authenticate();
    final GoogleSignInAuthentication auth = account.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  String? get userId => _auth.currentUser?.uid;
}
