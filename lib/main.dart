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
import 'config/api_config.dart';
import 'models/user_progress.dart';
import 'services/progress_service.dart';
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
                child: child ?? const SizedBox(),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 350 ? 16 : 24,
              vertical: isSmallScreen ? 8 : 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 40),
                  // App Logo and Branding
                  Column(
                    children: [
                      // Main Logo Container
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
                      // App Name
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
                      // Tagline
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
                    constraints: BoxConstraints(
                      maxWidth: screenWidth < 400 ? screenWidth - 32 : 400,
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
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 12 : 14,
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
                                        color: Colors.grey.shade600, 
                                        fontWeight: FontWeight.w500,
                                        fontSize: isSmallScreen ? 12 : 14,
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
                  SizedBox(height: isSmallScreen ? 20 : 40),
                ],
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 350 ? 16 : 24,
              vertical: isSmallScreen ? 8 : 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 40),
                  // App Logo and Branding
                  Column(
                    children: [
                      // Main Logo Container
                      Container(
                        width: isSmallScreen ? 80 : 100,
                        height: isSmallScreen ? 80 : 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: isSmallScreen ? 12 : 15,
                              offset: Offset(0, isSmallScreen ? 6 : 8),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.purple.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            color: Colors.white,
                            size: isSmallScreen ? 32 : 40,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      // App Name
                      Text(
                        'AI Talk English',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 40),
                  // Sign Up Card
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth < 400 ? screenWidth - 32 : 400,
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
                                'Join Us Today!',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Text(
                                'Create your account and start learning',
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
                              // Sign Up Button
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
                                  child: Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              // Back to Sign In
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.grey.shade600, 
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 40),
                ],
              ),
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

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  UserProgress? _userProgress;
  List<Achievement> _achievements = [];
  List<SkillAnalysis> _skillAnalyses = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final progress = await ProgressService.loadProgress(user.uid);
        final achievements = await ProgressService.loadAchievements();
        final skillAnalyses = await ProgressService.generateSkillAnalysis(progress);

        if (mounted) {
          setState(() {
            _userProgress = progress;
            _achievements = achievements;
            _skillAnalyses = skillAnalyses;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

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
          child: _isLoading
              ? _buildLoadingView()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: CustomScrollView(
                      slivers: [
                        // Header Section
                        SliverAppBar(
                          expandedHeight: 120,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          flexibleSpace: FlexibleSpaceBar(
                            background: _buildHeaderSection(user),
                          ),
                          actions: [
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.logout, color: Colors.deepPurple.shade600),
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                },
                              ),
                            ),
                          ],
                        ),

                        // Progress Overview Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
                            child: _buildProgressOverview(),
                          ),
                        ),

                        // Skill Analysis Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideScreen ? 24 : 16,
                              vertical: 8,
                            ),
                            child: _buildSkillAnalysisSection(),
                          ),
                        ),

                        // Recent Achievements Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideScreen ? 24 : 16,
                              vertical: 8,
                            ),
                            child: _buildAchievementsSection(),
                          ),
                        ),

                        // Quick Actions Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
                            child: _buildQuickActionsSection(isWideScreen),
                          ),
                        ),

                        // Bottom spacing
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 20),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your progress...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.deepPurple.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.displayName ?? user?.email?.split('@')[0] ?? 'Learner',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    if (_userProgress == null) return const SizedBox.shrink();

    return Card(
      elevation: 8,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.deepPurple.shade50,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Learning Journey',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 20),
            
            // Progress Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  title: 'Day Streak',
                  value: '${_userProgress!.streak}',
                  subtitle: 'days in a row',
                ),
                _buildStatCard(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.blue,
                  title: 'Messages',
                  value: '${_userProgress!.totalMessages}',
                  subtitle: 'conversations',
                ),
                _buildStatCard(
                  icon: Icons.school,
                  iconColor: Colors.green,
                  title: 'Lessons',
                  value: '${_userProgress!.lessonsCompleted}',
                  subtitle: 'completed',
                ),
                _buildStatCard(
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber,
                  title: 'Badges',
                  value: '${_achievements.length}',
                  subtitle: 'earned',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillAnalysisSection() {
    if (_skillAnalyses.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 8,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skill Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Skill Progress Bars
            ..._skillAnalyses.map((analysis) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSkillProgressBar(analysis),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillProgressBar(SkillAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              analysis.skillName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${(analysis.currentLevel * 10).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.deepPurple.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: analysis.currentLevel / 10,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getSkillColor(analysis.skillName),
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          analysis.recommendation,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getSkillColor(String skillName) {
    switch (skillName.toLowerCase()) {
      case 'vocabulary': return Colors.blue;
      case 'grammar': return Colors.green;
      case 'speaking': return Colors.orange;
      case 'writing': return Colors.purple;
      default: return Colors.deepPurple;
    }
  }

  Widget _buildAchievementsSection() {
    if (_achievements.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 8,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.amber.shade50,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Achievement List
            ..._achievements.take(3).map((achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAchievementItem(achievement),
            )),
            
            if (_achievements.length > 3)
              TextButton(
                onPressed: () {
                  // Navigate to full achievements page
                },
                child: Text(
                  'View all achievements',
                  style: TextStyle(
                    color: Colors.deepPurple.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getAchievementIcon(achievement.iconName),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'local_fire_department': return Icons.local_fire_department;
      case 'chat': return Icons.chat;
      case 'book': return Icons.book;
      case 'star': return Icons.star;
      default: return Icons.emoji_events;
    }
  }

  Widget _buildQuickActionsSection(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continue Learning',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade700,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWideScreen ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWideScreen ? 1.2 : 1.1,
          children: [
            _buildActionCard(
              icon: Icons.chat,
              title: 'AI Chat',
              subtitle: 'Practice conversation',
              gradient: [Colors.blue, Colors.blue.shade400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotScreen()),
              ),
            ),
            _buildActionCard(
              icon: Icons.spellcheck,
              title: 'Grammar',
              subtitle: 'Improve writing',
              gradient: [Colors.green, Colors.green.shade400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GrammarScreen()),
              ),
            ),
            _buildActionCard(
              icon: Icons.book,
              title: 'Vocabulary',
              subtitle: 'Learn new words',
              gradient: [Colors.purple, Colors.purple.shade400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabScreen()),
              ),
            ),
            _buildActionCard(
              icon: Icons.school,
              title: 'Lessons',
              subtitle: 'Structured learning',
              gradient: [Colors.orange, Colors.orange.shade400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LessonScreen()),
              ),
            ),
            _buildActionCard(
              icon: Icons.bar_chart,
              title: 'Progress',
              subtitle: 'Track improvement',
              gradient: [Colors.teal, Colors.teal.shade400],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              ),
            ),
            _buildActionCard(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Customize app',
              gradient: [Colors.grey.shade600, Colors.grey.shade500],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shadowColor: gradient[0].withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
