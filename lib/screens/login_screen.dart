import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _navy = Color(0xFF1E3A5F);
  static const Color _blue = Color(0xFF2E86AB);
  static const Color _bg = Color(0xFFF0F4F8);

  bool _loadingGoogle = false;
  bool _loadingFacebook = false;

  void _goToApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigator()),
    );
  }

  Future<void> _handleGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null) _goToApp();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
        _showError('SHA-1 certificate mismatch. Check Firebase Console → Android app settings.');
      } else if (msg.contains('network') || msg.contains('NETWORK')) {
        _showError('No internet connection. Please check your network.');
      } else if (msg.contains('no tokens')) {
        _showError('Google token error. Ensure SHA-1 is registered in Firebase Console.');
      } else {
        _showError('Google Sign-In failed: ${msg.length > 80 ? msg.substring(0, 80) : msg}');
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _handleFacebook() async {
    setState(() => _loadingFacebook = true);
    try {
      final user = await AuthService.signInWithFacebook();
      if (user != null) _goToApp();
    } catch (e) {
      _showError('Facebook Sign-In failed. Check your App ID configuration.');
    } finally {
      if (mounted) setState(() => _loadingFacebook = false);
    }
  }

  Future<void> _handleGuest() async {
    await AuthService.continueAsGuest();
    _goToApp();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingGoogle || _loadingFacebook;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_navy, _blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: Colors.white, size: 52),
                ),
                const SizedBox(height: 28),

                // App name
                const Text(
                  'Activity Tracker',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'by Viral Systems',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Feature pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: const [
                    _Pill('🏋️ Workouts'),
                    _Pill('🥗 Diet'),
                    _Pill('🔥 Habits'),
                    _Pill('✅ Tasks'),
                    _Pill('🏆 Goals'),
                    _Pill('📊 Dashboard'),
                  ],
                ),
                const SizedBox(height: 44),

                // Google button
                _AuthButton(
                  loading: _loadingGoogle,
                  disabled: isLoading,
                  onTap: _handleGoogle,
                  color: Colors.white,
                  borderColor: const Color(0xFFDADCE0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google G
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: const Text('G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEA4335),
                            )),
                      ),
                      const SizedBox(width: 12),
                      const Text('Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C4043),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Facebook button
                _AuthButton(
                  loading: _loadingFacebook,
                  disabled: isLoading,
                  onTap: _handleFacebook,
                  color: const Color(0xFF1877F2),
                  borderColor: const Color(0xFF1877F2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: const Text('f',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'serif',
                            )),
                      ),
                      const SizedBox(width: 12),
                      const Text('Continue with Facebook',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ]),
                const SizedBox(height: 16),

                // Guest / skip
                GestureDetector(
                  onTap: isLoading ? null : _handleGuest,
                  child: Text(
                    'Continue without account →',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'By continuing you agree to our Terms & Privacy Policy',
                  style: TextStyle(
                      fontSize: 11, color: Colors.blueGrey.shade300),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A5F))),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;
  final Widget child;

  const _AuthButton({
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.color,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        color == Colors.white
                            ? const Color(0xFF1E3A5F)
                            : Colors.white),
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
