import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/chatbot/chatbot_screen.dart';
import 'features/grammar/grammar_screen.dart';
import 'features/vocab/vocab_screen.dart';
import 'features/lesson/lesson_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
// Import platform-specific Google sign-in helper
import 'google_sign_in_helper.dart'
    if (dart.library.html) 'google_sign_in_helper_web.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'widgets/environment_banner.dart';
import 'config/api_config.dart';
// Debug: Improved AI suggestions implemented

class AppState extends ChangeNotifier {
  // Example shared state: current streak
  int streak = 0;
  
  // Loading state management
  bool _isTransitioning = false;
  bool get isTransitioning => _isTransitioning;
  
  void startTransition() {
    _isTransitioning = true;
    notifyListeners();
  }
  
  void endTransition() {
    _isTransitioning = false;
    notifyListeners();
  }
  
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'AI Talk English',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.deepPurple.shade50,
        ),
        home: const AppInitializer(),
        // Disable the debug banner
        debugShowCheckedModeBanner: false,
        // Add a global builder to prevent blank screens
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                color: Colors.deepPurple.shade50, // Fallback background
                child: Column(
                  children: [
                    // Environment banner (only shown in dev/staging)
                    const EnvironmentBanner(),
                    // Main app content
                    Expanded(child: child ?? const SizedBox()),
                  ],
                ),
              ),
              // Global loading overlay
              Consumer<AppState>(
                builder: (context, appState, _) {
                  if (appState.isTransitioning) {
                    return const GlobalLoadingOverlay();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

class GlobalLoadingOverlay extends StatelessWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.deepPurple.shade300,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepPurple.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('AppInitializer: initState called');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('AppInitializer: Starting Firebase initialization');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('AppInitializer: Firebase initialization completed');
      
      // Add a small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('AppInitializer: Firebase initialization failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AppInitializer: build called, _isInitialized=$_isInitialized, _errorMessage=$_errorMessage');
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    if (_errorMessage != null) {
      return Scaffold(
        key: const ValueKey('error-screen'),
        backgroundColor: Colors.deepPurple.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isInitialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        key: const ValueKey('app-loading'),
        child: const AppLoadingScreen(),
      );
    }

    print('AppInitializer: Transitioning to AuthGate');
    return Container(
      key: const ValueKey('auth-gate'),
      child: const AuthGate(),
    );
  }
}

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print('AppLoadingScreen: initState called');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('AppLoadingScreen: build called');
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Name
              const Text(
                'AI Talk English',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Learn English with AI',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple.shade400,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Loading Text
              Text(
                'Initializing app...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Start with loading state to prevent blank page
  bool _isInitialLoading = true;
  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    print('AuthGate: initState called');
    // Start global transition loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).startTransition();
    });
    _initializeAuthStream();
  }

  void _initializeAuthStream() {
    // Get the current user immediately
    _currentUser = FirebaseAuth.instance.currentUser;
    print('AuthGate: Initial user state: ${_currentUser?.email ?? 'null'}');
    
    // Listen to auth changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        print('AuthGate: Auth state changed: ${user?.email ?? 'null'}');
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isInitialLoading = false;
          });
          // End global transition loading
          Provider.of<AppState>(context, listen: false).endTransition();
        }
      },
      onError: (error) {
        print('AuthGate: Auth stream error: $error');
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
          // End global transition loading even on error
          Provider.of<AppState>(context, listen: false).endTransition();
        }
      },
    );

    // Set a timeout to stop initial loading even if stream doesn't emit
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isInitialLoading) {
        print('AuthGate: Timeout reached, stopping initial loading');
        setState(() {
          _isInitialLoading = false;
        });
        // End global transition loading on timeout
        Provider.of<AppState>(context, listen: false).endTransition();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('AuthGate: build called, _isInitialLoading=$_isInitialLoading, _currentUser=${_currentUser?.email ?? 'null'}');
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    // Always show loading screen initially or when loading
    if (_isInitialLoading) {
      return Scaffold(
        key: const ValueKey('auth-loading'),
        backgroundColor: Colors.deepPurple.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon - consistent with loading screen
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Loading Text
              Text(
                'Checking authentication...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // User is authenticated
    if (_currentUser != null) {
      print('AuthGate: User is authenticated, navigating to WelcomeScreen');
      return Container(
        key: const ValueKey('welcome-screen'),
        child: const WelcomeScreen(),
      );
    } else {
      // User is not authenticated
      print('AuthGate: User not authenticated, navigating to SignInScreen');
      return Container(
        key: const ValueKey('signin-screen'),
        child: const SignInScreen(),
      );
    }
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
                try {
                  if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
                    final credential = await SignInWithApple.getAppleIDCredential(
                      scopes: [
                        AppleIDAuthorizationScopes.email,
                        AppleIDAuthorizationScopes.fullName,
                      ],
                    );
                    final oauthCredential = OAuthProvider("apple.com").credential(
                      idToken: credential.identityToken,
                      accessToken: credential.authorizationCode,
                    );
                    await FirebaseAuth.instance.signInWithCredential(oauthCredential);
                  } else {
                    setState(() => error = 'Apple sign-in is only available on iOS, macOS, and web.');
                  }
                } catch (e) {
                  setState(() => error = 'Apple sign-in error: ${e.toString()}');
                }
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
