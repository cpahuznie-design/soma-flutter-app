import 'package:flutter/material.dart';
import 'theme/soma_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/chess_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/sleep_stories_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/auth_service.dart';

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
      home: const SplashGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final loggedIn = await AuthService.isLoggedIn();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => loggedIn ? const MainScreen() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [SomaTheme.teal.withOpacity(0.3), SomaTheme.bgCard]),
                border: Border.all(color: SomaTheme.teal, width: 2),
              ),
              child: Icon(Icons.psychology, color: SomaTheme.tealBright, size: 44),
            ),
            const SizedBox(height: 20),
            Text('SOMA', style: TextStyle(
              color: SomaTheme.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 6,
            )),
            const SizedBox(height: 30),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(color: SomaTheme.teal, strokeWidth: 2),
            ),
          ],
        ),
      ),
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
  int _gameIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      body: _getBody(),
      bottomNavigationBar: _buildNavBar(),
      endDrawer: _currentIndex == 3 ? _buildGameDrawer() : null,
      drawer: _buildSideDrawer(),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0: return const DashboardScreen();
      case 1: return const SleepScreen();
      case 2: return const BreathingExerciseScreen();
      case 3: return _gameScreen;
      case 4: return const LearnScreen();
      case 5: return const SettingsScreen();
      default: return const DashboardScreen();
    }
  }

  Widget get _gameScreen {
    switch (_gameIndex) {
      case 0: return const FocusScreen();
      case 1: return const MemoryScreen();
      case 2: return const ChessScreen();
      default: return const FocusScreen();
    }
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        border: Border(top: BorderSide(color: SomaTheme.teal.withOpacity(0.15))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(Icons.dashboard, 'Home', 0),
              _buildNavButton(Icons.bedtime, 'Tidur', 1),
              _buildNavButton(Icons.waves, 'Tenang', 2),
              _buildNavButton(Icons.sports_esports, 'Game', 3),
              _buildNavButton(Icons.book, 'Belajar', 4),
              _buildNavButton(Icons.settings, 'Setting', 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? SomaTheme.teal.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? SomaTheme.tealBright : SomaTheme.textMuted),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              color: active ? SomaTheme.tealBright : SomaTheme.textMuted,
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  // Side drawer untuk fitur premium (AI Coach, Challenge, Sleep Stories, Subscription)
  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: SomaTheme.bgCard,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: SomaTheme.bgDeep),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology, color: SomaTheme.teal, size: 32),
                  const SizedBox(height: 12),
                  Text('SOMA Premium', style: TextStyle(color: SomaTheme.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Fitur tambahan untuk otak Anda', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
            _buildSideItem(Icons.auto_awesome, 'AI Brain Coach', 'Insight & saran personal harian', const AICoachScreen()),
            _buildSideItem(Icons.local_fire_department, 'Daily Challenge', 'Tantangan otak harian + streak', const ChallengeScreen()),
            _buildSideItem(Icons.nightlight, 'Sleep Stories', 'Cerita audio pengantar tidur', const SleepStoriesScreen()),
            _buildSideItem(Icons.workspace_premium, 'Upgrade Premium', 'Buka semua fitur SOMA', const SubscriptionScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildSideItem(IconData icon, String title, String subtitle, Widget screen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: SomaTheme.teal),
        title: Text(title, style: TextStyle(color: SomaTheme.text, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }

  Widget _buildGameDrawer() {
    return Drawer(
      backgroundColor: SomaTheme.bgCard,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: SomaTheme.bgDeep),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sports_esports, color: SomaTheme.teal, size: 32),
                  const SizedBox(height: 12),
                  Text('Game', style: TextStyle(color: SomaTheme.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Pilih latihan otak', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.timer, 'Fokus Therapy', 'Pomodoro, latihan konsentrasi', 0),
            _buildDrawerItem(Icons.extension, 'Memory Trainer', '4 game + flashcard', 1),
            _buildDrawerItem(Icons.sports_esports, 'Catur', 'Main vs AI minimax', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String subtitle, int gameIdx) {
    final active = _gameIndex == gameIdx;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? SomaTheme.teal.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? SomaTheme.tealBright : SomaTheme.teal),
        title: Text(title, style: TextStyle(
          color: active ? SomaTheme.tealBright : SomaTheme.text,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          fontSize: 15,
        )),
        subtitle: Text(subtitle, style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
        onTap: () {
          setState(() => _gameIndex = gameIdx);
          Navigator.pop(context);
        },
      ),
    );
  }
}