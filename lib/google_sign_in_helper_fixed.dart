// This file is only imported on non-web platforms
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> signInWithGoogleHelper(Function(String) setError) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // User cancelled the sign-in
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    await FirebaseAuth.instance.signInWithCredential(credential);
    setError(''); // Clear any previous errors
  } catch (e) {
    setError(e.toString());
  }
}
