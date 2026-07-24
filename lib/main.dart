import 'package:flutter/material.dart';
import 'theme/soma_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/memory_screen.dart' show MemoryScreen;
import 'screens/chess_screen.dart' show ChessScreen;
import 'screens/learn_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const SomaApp());
}

class SomaApp extends StatelessWidget {
  const SomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA — Bangunkan Kekuatan Otak yang Tidur',
      theme: SomaTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    SleepScreen(),
    BreathingExerciseScreen(),
    FocusScreen(),
    MemoryScreen(),
    LearnScreen(),
    ChessScreen(),
    SettingsScreen(),
  ];

  final _titles = ['SOMA', 'Tidur', 'Relaksasi', 'Fokus', 'Memory', 'Belajar', 'Catur', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: SomaTheme.bgDeep,
        title: Text(_titles[_currentIndex], style: const TextStyle(color: SomaTheme.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SomaTheme.bgCard,
          border: Border(top: BorderSide(color: SomaTheme.teal.withOpacity(0.2))),
        ),
        child: NavigationBar(
          backgroundColor: SomaTheme.bgCard,
          selectedIndex: _currentIndex > 5 ? 0 : _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          indicatorColor: SomaTheme.teal.withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), selectedIcon: Icon(Icons.dashboard, color: SomaTheme.tealBright), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.bedtime), selectedIcon: Icon(Icons.bedtime, color: SomaTheme.tealBright), label: 'Tidur'),
            NavigationDestination(icon: Icon(Icons.waves), selectedIcon: Icon(Icons.waves, color: SomaTheme.tealBright), label: 'Relaksasi'),
            NavigationDestination(icon: Icon(Icons.timer), selectedIcon: Icon(Icons.timer, color: SomaTheme.tealBright), label: 'Fokus'),
            NavigationDestination(icon: Icon(Icons.extension), selectedIcon: Icon(Icons.extension, color: SomaTheme.tealBright), label: 'Memory'),
            NavigationDestination(icon: Icon(Icons.book), selectedIcon: Icon(Icons.book, color: SomaTheme.tealBright), label: 'Belajar'),
          ],
        ),
      ),
      endDrawer: Drawer(
        backgroundColor: SomaTheme.bgCard,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: SomaTheme.bgDeep),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SOMA', style: TextStyle(color: SomaTheme.tealBright, fontSize: 28, fontWeight: FontWeight.w800)),
                  Text('Bangunkan kekuatan otak yang tidur', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.sports_esports, color: SomaTheme.teal),
              title: Text('Catur', style: TextStyle(color: SomaTheme.text)),
              onTap: () { setState(() => _currentIndex = 6); Navigator.pop(context); },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: SomaTheme.teal),
              title: Text('Settings', style: TextStyle(color: SomaTheme.text)),
              onTap: () { setState(() => _currentIndex = 7); Navigator.pop(context); },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: SomaTheme.teal),
              title: Text('Brain Analytics', style: TextStyle(color: SomaTheme.text)),
              onTap: () { Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}