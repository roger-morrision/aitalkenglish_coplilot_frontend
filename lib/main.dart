import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/chatbot/chatbot_screen.dart';
import 'features/grammar/grammar_screen.dart';
import 'features/vocab/vocab_screen.dart';
import 'features/lesson/lesson_screen.dart';
import 'features/progress/progress_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import platform-specific Google sign-in helper
import 'google_sign_in_helper.dart'
    if (dart.library.html) 'google_sign_in_helper_web.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'features/chatbot/chatbot_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppState extends ChangeNotifier {
  // Example shared state: current streak
  int streak = 0;
  void incrementStreak() {
    streak++;
    notifyListeners();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _screens = [
    ChatbotScreen(),
    GrammarScreen(),
    VocabScreen(),
    LessonScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.spellcheck), label: 'Grammar'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Vocab'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Lesson'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: MainScreen(),
      ),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return const WelcomeScreen();
              } else {
                return const SignInScreen();
              }
            },
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  Future<void> _signInWithGoogle() async {
    await signInWithGoogleHelper((err) => setState(() => error = err));
  }
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (error.isNotEmpty) ...[
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                } catch (e) {
                  setState(() => error = e.toString());
                }
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                );
              },
              child: const Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                );
              },
              child: const Text('Forgot Password?'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: () async {
                await _signInWithGoogle();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.facebook),
              label: const Text('Sign in with Facebook'),
              onPressed: () async {
                try {
                  if (kIsWeb) {
                    final auth = FirebaseAuth.instance;
                    final provider = FacebookAuthProvider();
                    await auth.signInWithPopup(provider);
                  } else {
                    final result = await FacebookAuth.instance.login();
                    final accessToken = result.accessToken;
                    if (accessToken != null) {
                    final credential = FacebookAuthProvider.credential(accessToken.tokenString);
                      await FirebaseAuth.instance.signInWithCredential(credential);
                    } else {
                      setState(() => error = 'Facebook sign-in failed.');
                    }
                  }
                } catch (e) {
                  setState(() => error = 'Facebook sign-in error: \\n${e.toString()}');
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.apple),
              label: const Text('Sign in with Apple'),
              onPressed: () async {
                // ...existing code for Apple sign-in...
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- Sign Up Screen ---
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (error.isNotEmpty) ...[
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Go back to sign in
                  }
                } catch (e) {
                  setState(() => error = e.toString());
                }
              },
              child: const Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final emailController = TextEditingController();
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: emailController,
              builder: (context, value, child) {
                final isEnabled = value.text.trim().isNotEmpty;
                return ElevatedButton(
                  onPressed: isEnabled
                      ? () async {
                          final email = value.text.trim();
                          if (email.isEmpty) {
                            setState(() => message = 'Please enter your email.');
                            return;
                          }
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            setState(() => message = 'Password reset email sent!');
                          } catch (e) {
                            setState(() => message = 'Failed to send reset email: ${e.toString()}');
                          }
                        }
                      : null,
                  child: const Text('Send Reset Email'),
                );
              },
            ),
            if (message.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(message, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hello, ${user?.email ?? 'User'}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              color: Colors.deepPurple[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Your Progress', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Example progress summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.bar_chart, color: Colors.deepPurple),
                            Text('Streak: 5 days'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.book, color: Colors.deepPurple),
                            Text('Vocab: 120'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.school, color: Colors.deepPurple),
                            Text('Lessons: 8'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.emoji_events, color: Colors.amber),
                            Text('Badges: 3'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text('Chatbot'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.spellcheck),
                  label: const Text('Grammar'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarScreen())),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.book),
                  label: const Text('Vocabulary'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabScreen())),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.school),
                  label: const Text('Lesson'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonScreen())),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Progress'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
