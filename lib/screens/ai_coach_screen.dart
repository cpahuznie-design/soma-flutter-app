import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/soma_theme.dart';
import '../services/auth_service.dart';
import 'breathing_screen.dart';
import 'memory_screen.dart';
import 'focus_screen.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  List<double> _sleepData = [];
  List<double> _focusData = [];
  List<double> _memoryData = [];
  List<double> _stressData = [];
  List<Map<String, dynamic>> _insights = [];
  String _bestDay = '';
  String _worstDay = '';
  int _bestScore = 0;
  int _worstScore = 0;
  double _weekAvg = 0;
  double _lastWeekAvg = 0;
  double _weekChange = 0;
  String _userName = '';
  bool _loading = true;

  final List<String> _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load sleep data
    final sleepJson = prefs.getString('soma_sleep_data');
    if (sleepJson != null) {
      final list = jsonDecode(sleepJson) as List;
      _sleepData = list.map((e) => (e as num).toDouble()).toList();
    }

    // Load focus data
    final focusJson = prefs.getString('soma_focus_data');
    if (focusJson != null) {
      final list = jsonDecode(focusJson) as List;
      _focusData = list.map((e) => (e as num).toDouble()).toList();
    }

    // Load memory scores
    final memoryJson = prefs.getString('soma_memory_scores');
    if (memoryJson != null) {
      final list = jsonDecode(memoryJson) as List;
      _memoryData = list.map((e) => (e as num).toDouble()).toList();
    }

    // Load stress data
    final stressJson = prefs.getString('soma_stress_data');
    if (stressJson != null) {
      final list = jsonDecode(stressJson) as List;
      _stressData = list.map((e) => (e as num).toDouble()).toList();
    }

    // Fill with dummy data if empty
    if (_sleepData.isEmpty) {
      _sleepData = [7.2, 5.5, 6.0, 5.8, 7.5, 8.0, 6.8];
    }
    if (_focusData.isEmpty) {
      _focusData = [72, 65, 68, 60, 75, 85, 78];
    }
    if (_memoryData.isEmpty) {
      _memoryData = [70, 72, 75, 73, 78, 80, 82];
    }
    if (_stressData.isEmpty) {
      _stressData = [5, 7, 8, 6, 4, 3, 5];
    }

    // Load user name
    final name = await AuthService.getUserName();
    _userName = name ?? 'Pengguna';

    _generateInsights();
    _analyzePatterns();
    _calculateWeeklyRecap();

    setState(() {
      _loading = false;
    });
  }

  void _generateInsights() {
    _insights = [];

    // Check sleep < 6 hours for last 3 days
    if (_sleepData.length >= 3) {
      final last3 = _sleepData.sublist(_sleepData.length - 3);
      final lowSleep = last3.where((s) => s < 6).length;
      if (lowSleep >= 2) {
        _insights.add({
          'type': 'warning',
          'icon': Icons.bedtime_off,
          'color': SomaTheme.lavender,
          'title': 'Tidur Kurang',
          'text':
              'Tidur Anda kurang 3 hari terakhir. Coba breathing 4-7-8 sebelum tidur malam ini.',
        });
      }
    }

    // Check memory score trend
    if (_memoryData.length >= 7) {
      final thisWeek = _memoryData.sublist(_memoryData.length - 7);
      final firstHalf = thisWeek.sublist(0, 3).fold<double>(0, (a, b) => a + b) / 3;
      final secondHalf = thisWeek.sublist(4).fold<double>(0, (a, b) => a + b) / 3;
      final diff = secondHalf - firstHalf;
      if (diff > 5) {
        _insights.add({
          'type': 'success',
          'icon': Icons.trending_up,
          'color': SomaTheme.tealBright,
          'title': 'Memory Meningkat',
          'text':
              'Memory score naik ${diff.round()} poin minggu ini! Pertahankan latihan harian.',
        });
      } else if (diff < -5) {
        _insights.add({
          'type': 'down',
          'icon': Icons.trending_down,
          'color': SomaTheme.softBlue,
          'title': 'Memory Menurun',
          'text':
              'Memory score turun ${diff.abs().round()} poin minggu ini. Tingkatkan latihan memory game.',
        });
      }
    }

    // Check stress level > 7
    if (_stressData.isNotEmpty) {
      final latestStress = _stressData.last;
      if (latestStress > 7) {
        _insights.add({
          'type': 'warning',
          'icon': Icons.warning_amber_rounded,
          'color': SomaTheme.purple,
          'title': 'Stress Tinggi',
          'text': 'Stress Anda tinggi. Coba 5 menit Box Breathing sekarang.',
        });
      }
    }

    // Check focus declining
    if (_focusData.length >= 3) {
      final last2 = _focusData.sublist(_focusData.length - 2);
      final prevAvg = _focusData.length > 3
          ? _focusData.sublist(_focusData.length - 4, _focusData.length - 2).fold<double>(0, (a, b) => a + b) / 2
          : 70.0;
      final recentAvg = last2.fold<double>(0, (a, b) => a + b) / 2;
      if (recentAvg < prevAvg - 5) {
        _insights.add({
          'type': 'down',
          'icon': Icons.trending_down,
          'color': SomaTheme.softBlue,
          'title': 'Fokus Turun',
          'text': 'Fokus turun 2 hari terakhir. Coba pomodoro 25 menit + brown noise.',
        });
      }
    }

    // If no insights, add a positive one
    if (_insights.isEmpty) {
      _insights.add({
        'type': 'success',
        'icon': Icons.check_circle,
        'color': SomaTheme.tealBright,
        'title': 'Kondisi Stabil',
        'text': 'Otak Anda dalam kondisi baik. Pertahankan ritme latihan dan tidur Anda.',
      });
    }
  }

  void _analyzePatterns() {
    // Calculate brain score per day = average of focus + memory
    final dailyScores = <double>[];
    final minLen = _focusData.length < _memoryData.length ? _focusData.length : _memoryData.length;
    for (var i = 0; i < minLen; i++) {
      dailyScores.add((_focusData[i] + _memoryData[i]) / 2);
    }

    if (dailyScores.isEmpty) return;

    // Find best and worst day
    var bestIdx = 0;
    var worstIdx = 0;
    for (var i = 1; i < dailyScores.length; i++) {
      if (dailyScores[i] > dailyScores[bestIdx]) bestIdx = i;
      if (dailyScores[i] < dailyScores[worstIdx]) worstIdx = i;
    }

    _bestDay = _dayNames[bestIdx % 7];
    _worstDay = _dayNames[worstIdx % 7];
    _bestScore = dailyScores[bestIdx].round();
    _worstScore = dailyScores[worstIdx].round();
  }

  void _calculateWeeklyRecap() {
    // This week brain scores
    final dailyScores = <double>[];
    final minLen = _focusData.length < _memoryData.length ? _focusData.length : _memoryData.length;
    for (var i = 0; i < minLen; i++) {
      dailyScores.add((_focusData[i] + _memoryData[i]) / 2);
    }

    if (dailyScores.isEmpty) return;

    // This week (last 7 or available)
    final thisWeek = dailyScores.length >= 7
        ? dailyScores.sublist(dailyScores.length - 7)
        : dailyScores;
    _weekAvg = thisWeek.fold<double>(0, (a, b) => a + b) / thisWeek.length;

    // Last week (simulate: slightly lower)
    _lastWeekAvg = _weekAvg - 4.2;
    _weekChange = ((_weekAvg - _lastWeekAvg) / _lastWeekAvg) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: SomaTheme.bgDeep,
        body: Center(
          child: CircularProgressIndicator(color: SomaTheme.tealBright),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        title: Text('AI Brain Coach', style: TextStyle(color: SomaTheme.white, fontWeight: FontWeight.w700)),
        backgroundColor: SomaTheme.bgDeep,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildGreeting(),
          const SizedBox(height: 20),
          _buildSectionTitle('Daily Insight', Icons.lightbulb_outline),
          const SizedBox(height: 12),
          ..._insights.map((i) => _buildInsightCard(i)),
          const SizedBox(height: 24),
          _buildSectionTitle('Brain Pattern Analysis', Icons.insights),
          const SizedBox(height: 12),
          _buildPatternCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Saran Personal Hari Ini', Icons.recommend),
          const SizedBox(height: 12),
          _buildSuggestionCard(
            'Breathing 4-7-8',
            'Breathing 4-7-8 selama 4 menit sebelum tidur',
            Icons.air,
            SomaTheme.tealBright,
            'breathing',
          ),
          const SizedBox(height: 12),
          _buildSuggestionCard(
            'Memory Game',
            'Memory game 10 menit untuk latih hippocampus',
            Icons.psychology,
            SomaTheme.lavender,
            'memory',
          ),
          const SizedBox(height: 12),
          _buildSuggestionCard(
            'Pomodoro Focus',
            'Coba pomodoro 25 menit dengan brown noise',
            Icons.timer,
            SomaTheme.softBlue,
            'focus',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Weekly Recap', Icons.bar_chart),
          const SizedBox(height: 12),
          _buildWeeklyRecap(),
          const SizedBox(height: 24),
          _buildSectionTitle('Smart Notification', Icons.notifications_active),
          const SizedBox(height: 12),
          _buildSmartNotifCard(
            'Berdasarkan pola, jam 6 pagi adalah waktu terbaik untuk breathing Anda',
            Icons.wb_sunny,
            SomaTheme.tealBright,
          ),
          const SizedBox(height: 12),
          _buildSmartNotifCard(
            'Memory game paling efektif setelah jam 3 sore',
            Icons.hourglass_bottom,
            SomaTheme.lavender,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SomaTheme.teal.withOpacity(0.15), SomaTheme.purple.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [SomaTheme.teal, SomaTheme.purple]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: SomaTheme.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo $_userName', style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('AI menganalisa data otak Anda hari ini',
                    style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: SomaTheme.tealBright, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (insight['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (insight['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight['icon'] as IconData, color: insight['color'] as Color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight['title'] as String,
                    style: TextStyle(color: SomaTheme.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(insight['text'] as String,
                    style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: SomaTheme.tealBright, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Otak Anda paling tajam hari $_bestDay (avg score $_bestScore), paling lemah $_worstDay (avg $_worstScore)',
                  style: TextStyle(color: SomaTheme.text, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: SomaTheme.teal.withOpacity(0.15), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.pattern, color: SomaTheme.lavender, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pola: tidur kurang = fokus turun 15% keesokan harinya',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    String title,
    String desc,
    IconData icon,
    Color color,
    String screen,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: SomaTheme.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _navigateToScreen(screen),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.2),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Mulai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(String screen) {
    Widget target;
    switch (screen) {
      case 'breathing':
        target = const BreathingExerciseScreen();
        break;
      case 'memory':
        target = const MemoryScreen();
        break;
      case 'focus':
        target = const FocusScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => target));
  }

  Widget _buildWeeklyRecap() {
    final dailyScores = <double>[];
    final minLen = _focusData.length < _memoryData.length ? _focusData.length : _memoryData.length;
    for (var i = 0; i < minLen; i++) {
      dailyScores.add((_focusData[i] + _memoryData[i]) / 2);
    }
    final maxScore = dailyScores.isEmpty ? 100.0 : dailyScores.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('7 Hari Terakhir', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _weekChange >= 0
                      ? SomaTheme.tealBright.withOpacity(0.15)
                      : SomaTheme.softBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _weekChange >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: _weekChange >= 0 ? SomaTheme.tealBright : SomaTheme.softBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_weekChange >= 0 ? '+' : ''}${_weekChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _weekChange >= 0 ? SomaTheme.tealBright : SomaTheme.softBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(dailyScores.length.clamp(0, 7), (i) {
                final score = dailyScores[i];
                final heightRatio = maxScore > 0 ? score / maxScore : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: (90 * heightRatio).clamp(10, 90),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: i == dailyScores.length - 1
                              ? [SomaTheme.tealBright, SomaTheme.teal]
                              : [SomaTheme.teal.withOpacity(0.5), SomaTheme.teal.withOpacity(0.2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_dayNames[i % 7], style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: SomaTheme.teal.withOpacity(0.15), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Minggu Ini', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                    Text('${_weekAvg.round()}', style: TextStyle(color: SomaTheme.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: SomaTheme.teal.withOpacity(0.15)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Minggu Lalu', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                      Text('${_lastWeekAvg.round()}', style: TextStyle(color: SomaTheme.textMuted, fontSize: 22, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartNotifCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: SomaTheme.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// Placeholder screens for navigation targets
class BreathingPlaceholder extends StatelessWidget {
  const BreathingPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(title: Text('Breathing 4-7-8', style: TextStyle(color: SomaTheme.white))),
      body: Center(child: Text('Breathing Screen', style: TextStyle(color: SomaTheme.text))),
    );
  }
}

class MemoryPlaceholder extends StatelessWidget {
  const MemoryPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(title: Text('Memory Game', style: TextStyle(color: SomaTheme.white))),
      body: Center(child: Text('Memory Screen', style: TextStyle(color: SomaTheme.text))),
    );
  }
}

class FocusPlaceholder extends StatelessWidget {
  const FocusPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(title: Text('Pomodoro Focus', style: TextStyle(color: SomaTheme.white))),
      body: Center(child: Text('Focus Screen', style: TextStyle(color: SomaTheme.text))),
    );
  }
}