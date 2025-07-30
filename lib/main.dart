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
import 'models/user_progress.dart';
import 'services/progress_service.dart';

class AppState extends ChangeNotifier {
  int streak = 0;
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
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                color: Colors.deepPurple.shade50,
                child: child ?? const SizedBox(),
              ),
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
              const Text(
                'AI Talk English',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn English with AI',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple.shade400,
                ),
              ),
              const SizedBox(height: 48),
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
  bool _isInitialLoading = true;
  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    print('AuthGate: initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).startTransition();
    });
    _initializeAuthStream();
  }

  void _initializeAuthStream() {
    _currentUser = FirebaseAuth.instance.currentUser;
    print('AuthGate: Initial user state: ${_currentUser?.email ?? 'null'}');
    
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        print('AuthGate: Auth state changed: ${user?.email ?? 'null'}');
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isInitialLoading = false;
          });
          Provider.of<AppState>(context, listen: false).endTransition();
        }
      },
      onError: (error) {
        print('AuthGate: Auth stream error: $error');
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
          Provider.of<AppState>(context, listen: false).endTransition();
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isInitialLoading) {
        print('AuthGate: Timeout reached, stopping initial loading');
        setState(() {
          _isInitialLoading = false;
        });
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
    if (_isInitialLoading) {
      return Scaffold(
        key: const ValueKey('auth-loading'),
        backgroundColor: Colors.deepPurple.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
    
    if (_currentUser != null) {
      print('AuthGate: User is authenticated, navigating to WelcomeScreen');
      return Container(
        key: const ValueKey('welcome-screen'),
        child: const WelcomeScreen(),
      );
    } else {
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

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade400,
              Colors.purple.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 600 ? (screenWidth < 350 ? 16 : 24) : 32,
                vertical: isSmallScreen ? 8 : 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - (isSmallScreen ? 80 : 32),
                  maxWidth: screenWidth < 1200 ? double.infinity : 1000,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isSmallScreen ? 20 : 40),
                    // App Logo and Branding
                    Column(
                      children: [
                        Container(
                          width: isSmallScreen ? 90 : 120,
                          height: isSmallScreen ? 90 : 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 22 : 30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: isSmallScreen ? 15 : 20,
                                offset: Offset(0, isSmallScreen ? 6 : 10),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.deepPurple, Colors.purple.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                            ),
                            child: Icon(
                              Icons.psychology_outlined,
                              color: Colors.white,
                              size: isSmallScreen ? 40 : 50,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        Text(
                          'AI Talk English',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 26 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16, 
                            vertical: isSmallScreen ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Master English with AI-Powered Learning',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 48),
                    // Sign In Card
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: screenWidth < 600 ? screenWidth - 32 : 
                                  screenWidth < 1000 ? 500 : 600,
                      ),
                      child: Card(
                        elevation: 12,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 24 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 8),
                                Text(
                                  'Sign in to continue your learning journey',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 32),
                                // Email Field
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                      prefixIcon: Icon(Icons.email_outlined, color: Colors.deepPurple.shade400),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20, 
                                        vertical: isSmallScreen ? 12 : 16,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                // Password Field
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                      prefixIcon: Icon(Icons.lock_outline, color: Colors.deepPurple.shade400),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20, 
                                        vertical: isSmallScreen ? 12 : 16,
                                      ),
                                    ),
                                  ),
                                ),
                                if (error.isNotEmpty) ...[
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  Container(
                                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            error,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: isSmallScreen ? 12 : 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                // Sign In Button
                                Container(
                                  width: double.infinity,
                                  height: isSmallScreen ? 48 : 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.deepPurple, Colors.purple.shade600],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
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
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 20),
                                // Navigation Links
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                                      },
                                      child: Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontSize: isSmallScreen ? 12 : 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 16),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontSize: isSmallScreen ? 12 : 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'or continue with',
                                        style: TextStyle(
                                          color: Colors.grey.shade600, 
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                // Social Sign In Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildSocialButton(
                                      icon: Icons.login,
                                      color: Colors.red,
                                      label: 'Google',
                                      onPressed: () async { await _signInWithGoogle(); },
                                    ),
                                    _buildSocialButton(
                                      icon: Icons.facebook,
                                      color: Colors.blue,
                                      label: 'Facebook',
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
                                          setState(() => error = 'Facebook sign-in error: ${e.toString()}');
                                        }
                                      },
                                    ),
                                    _buildSocialButton(
                                      icon: Icons.apple,
                                      color: Colors.black,
                                      label: 'Apple',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 15),
                  ],
                ),
              ),
            ),
          ),
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
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(error, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                    } catch (e) {
                      setState(() => error = e.toString());
                    }
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
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

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with user info and logout
              _buildHeader(user),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      _buildWelcomeMessage(user),
                      const SizedBox(height: 24),
                      
                      // Progress dashboard
                      _buildProgressDashboard(),
                      const SizedBox(height: 24),
                      
                      // Learning modules
                      _buildLearningModules(isWideScreen),
                      const SizedBox(height: 24),
                      
                      // Quick stats
                      _buildQuickStats(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  user?.displayName ?? user?.email?.split('@')[0] ?? 'Learner',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          
          // Logout button
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: Icon(
              Icons.logout,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to learn today?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Continue your English learning journey with AI-powered lessons',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDashboard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress stats
            Row(
              children: [
                Expanded(child: _buildStatCard('Current Streak', '5 days', Icons.local_fire_department, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Lessons', '12', Icons.school, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Level', 'Intermediate', Icons.star, Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningModules(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Modules',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWideScreen ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildModuleCard(
              'AI Chatbot',
              'Practice conversations',
              Icons.chat_bubble_outline,
              Colors.blue,
              () => _navigateToModule(0),
            ),
            _buildModuleCard(
              'Grammar',
              'Improve your grammar',
              Icons.spellcheck,
              Colors.green,
              () => _navigateToModule(1),
            ),
            _buildModuleCard(
              'Vocabulary',
              'Learn new words',
              Icons.book,
              Colors.orange,
              () => _navigateToModule(2),
            ),
            _buildModuleCard(
              'Lessons',
              'Structured learning',
              Icons.school,
              Colors.purple,
              () => _navigateToModule(3),
            ),
            _buildModuleCard(
              'Progress',
              'Track your improvement',
              Icons.bar_chart,
              Colors.teal,
              () => _navigateToModule(4),
            ),
            _buildModuleCard(
              'All Features',
              'Access everything',
              Icons.dashboard,
              Colors.deepPurple,
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildGoalProgress('Complete 2 lessons', 1, 2, Colors.blue),
            const SizedBox(height: 12),
            _buildGoalProgress('Practice 15 minutes', 10, 15, Colors.green),
            const SizedBox(height: 12),
            _buildGoalProgress('Learn 5 new words', 3, 5, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress(String title, int current, int target, Color color) {
    double progress = current / target;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$current/$target',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  void _navigateToModule(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreenWithIndex(initialIndex: index),
      ),
    );
  }
}

// Helper class to navigate to MainScreen with specific index
class MainScreenWithIndex extends StatefulWidget {
  final int initialIndex;
  
  const MainScreenWithIndex({super.key, required this.initialIndex});

  @override
  State<MainScreenWithIndex> createState() => _MainScreenWithIndexState();
}

class _MainScreenWithIndexState extends State<MainScreenWithIndex> {
  late int _selectedIndex;
  
  static const List<Widget> _screens = [
    ChatbotScreen(),
    GrammarScreen(),
    VocabScreen(),
    LessonScreen(),
    ProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
