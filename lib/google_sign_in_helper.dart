// This file is only imported on non-web platforms

Future<void> signInWithGoogleHelper(Function(String) setError) async {
  try {
    // Temporarily disabled Google Sign-In due to API changes
    setError('Google Sign-In is temporarily disabled. Please use email/password.');
  } catch (e) {
    setError(e.toString());
  }
}
