import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/training_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

// localhost works via adb reverse port forwarding
const _emulatorHost = 'localhost';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    // Point to local Firebase emulators so tests don't need real Play Services
    await fa.FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  }

  runApp(const ActivityTrackerApp());
}

class ActivityTrackerApp extends StatelessWidget {
  const ActivityTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder<fa.User?>(
        stream: fa.FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return _loadingScaffold;
          }
          if (authSnap.hasData) {
            return const MainNavigator();
          }
          // No Firebase user — check for guest session
          return FutureBuilder<bool>(
            future: _isGuestSession(),
            builder: (context, guestSnap) {
              if (guestSnap.connectionState == ConnectionState.waiting) {
                return _loadingScaffold;
              }
              return (guestSnap.data == true)
                  ? const MainNavigator()
                  : const LoginScreen();
            },
          );
        },
      ),
    );
  }

  static const _loadingScaffold = Scaffold(
    backgroundColor: Color(0xFFF0F4F8),
    body: Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A5F)),
      ),
    ),
  );

  static Future<bool> _isGuestSession() async {
    final user = await AuthService.getCurrentUser();
    return user?.provider == AuthProvider.guest;
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabDef('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _TabDef('Training',  Icons.fitness_center_outlined, Icons.fitness_center),
    _TabDef('Diet',      Icons.restaurant_outlined, Icons.restaurant),
    _TabDef('Habits',    Icons.local_fire_department_outlined, Icons.local_fire_department),
    _TabDef('Tasks',     Icons.check_box_outline_blank, Icons.check_box),
    _TabDef('Goals',     Icons.emoji_events_outlined, Icons.emoji_events),
    _TabDef('Coach',     Icons.psychology_outlined, Icons.psychology),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    TrainingScreen(),
    DietScreen(),
    HabitsScreen(),
    TasksScreen(),
    GoalsScreen(),
    CoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_currentIndex].label),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabDef(this.label, this.icon, this.activeIcon);
}
