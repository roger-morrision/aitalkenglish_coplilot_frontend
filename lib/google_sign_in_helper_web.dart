// This file is only imported on web platforms
import 'package:firebase_auth/firebase_auth.dart';
Future<void> signInWithGoogleHelper(Function(String) onError) async {
  try {
    // Use signInWithPopup for Google sign-in on web
    final auth = FirebaseAuth.instance;
    final provider = GoogleAuthProvider();
    await auth.signInWithPopup(provider);
    onError('');
  } catch (e) {
    onError(e.toString());
  }
}
