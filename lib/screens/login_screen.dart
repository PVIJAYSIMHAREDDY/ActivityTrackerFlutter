import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'privacy_screen.dart';

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
  bool _loadingGuest = false;

  Future<void> _handleGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      _showError(
        'Sign-in could not complete. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _handleGuest() async {
    setState(() => _loadingGuest = true);
    try {
      await AuthService.continueAsGuest();
    } catch (_) {
      _showError(
        'Guest sign-in could not complete. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loadingGuest = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingGoogle || _loadingGuest;
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
                        color: _navy.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 52,
                  ),
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
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEA4335),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C4043),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),

                // Guest / skip
                GestureDetector(
                  onTap: isLoading ? null : _handleGuest,
                  child: Text(
                    _loadingGuest ? 'Connecting…' : 'Continue as guest →',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                  child: const Text('Privacy & health information'),
                ),
                const SizedBox(height: 16),
                Text(
                  'For adults 18 and over.',
                  style: TextStyle(color: Colors.blueGrey.shade400),
                ),
                Text(
                  'Guest data is tied to this browser or device. Link Google in Profile to keep it across devices.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade300,
                  ),
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E3A5F),
        ),
      ),
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
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
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
                          : Colors.white,
                    ),
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
