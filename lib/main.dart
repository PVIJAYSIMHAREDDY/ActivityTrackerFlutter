import 'services/app_config.dart';
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
import 'screens/adaptive_plan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      const host = String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: 'localhost',
      );
      await fa.FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: AppConfig.databaseId,
      ).useFirestoreEmulator(host, 8080);
    }
    runApp(const ActivityTrackerApp());
  } catch (error) {
    debugPrint('Startup failed: $error');
    runApp(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Activity Tracker could not start. Please check your connection and try again.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: main, child: const Text('Try again')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          return authSnap.hasData
              ? MainNavigator(key: ValueKey(authSnap.data!.uid))
              : const LoginScreen();
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
    _TabDef('Training', Icons.fitness_center_outlined, Icons.fitness_center),
    _TabDef('Diet', Icons.restaurant_outlined, Icons.restaurant),
    _TabDef(
      'Habits',
      Icons.local_fire_department_outlined,
      Icons.local_fire_department,
    ),
    _TabDef('Tasks', Icons.check_box_outline_blank, Icons.check_box),
    _TabDef('Goals', Icons.emoji_events_outlined, Icons.emoji_events),
    _TabDef('Coach', Icons.psychology_outlined, Icons.psychology),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    TrainingScreen(),
    DietScreen(),
    HabitsScreen(),
    TasksScreen(),
    GoalsScreen(),
    AdaptivePlanScreen(),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          );
          if (constraints.maxWidth < 800) return content;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                labelType: NavigationRailLabelType.all,
                destinations: _tabs
                    .map(
                      (t) => NavigationRailDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.activeIcon),
                        label: Text(t.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 800
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: _tabs
                  .map(
                    (t) => BottomNavigationBarItem(
                      icon: Icon(t.icon),
                      activeIcon: Icon(t.activeIcon),
                      label: t.label,
                    ),
                  )
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
