import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),
          // Brain Score
          _buildBrainScore(),
          const SizedBox(height: 16),
          // Quick Stats (2x2 grid, simetris)
          _buildQuickStats(),
          const SizedBox(height: 16),
          // Daily Routine
          _buildDailyRoutine(),
          const SizedBox(height: 16),
          // Motivation
          _buildMotivation(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat Datang', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
            Text('Pak Husni', style: TextStyle(color: SomaTheme.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Icon(Icons.psychology, color: SomaTheme.teal, size: 24),
        ),
      ],
    );
  }

  Widget _buildBrainScore() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text('Brain Health Score', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          // Score circle
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [SomaTheme.teal.withOpacity(0.25), SomaTheme.bgCard]),
              border: Border.all(color: SomaTheme.teal, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('83', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: SomaTheme.tealBright)),
                  Text('Otak Optimal', style: TextStyle(color: SomaTheme.tealBright, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Breakdown — simetris 2 kolom
          Row(
            children: [
              Expanded(child: _buildMiniScore('Sleep', 100, SomaTheme.teal)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniScore('Focus', 95, SomaTheme.softBlue)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMiniScore('Memory', 65, SomaTheme.purple)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniScore('Stress', 47, Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SomaTheme.bgDeep,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
          const Spacer(),
          Text('$value', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {'value': '8.2h', 'label': 'Jam Tidur', 'icon': Icons.bedtime},
      {'value': '3', 'label': 'Sesi Fokus', 'icon': Icons.timer},
      {'value': '65', 'label': 'Memory Score', 'icon': Icons.psychology},
      {'value': '47%', 'label': 'Stress Level', 'icon': Icons.waves},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: stats.map((s) => _buildStatCard(s['value'] as String, s['label'] as String, s['icon'] as IconData)).toList(),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SomaTheme.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: SomaTheme.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRoutine() {
    final routines = [
      {'time': 'Pagi', 'activity': 'Breathing Exercise 5 min', 'icon': Icons.wb_sunny, 'done': false},
      {'time': 'Siang', 'activity': 'Focus Session 25 min', 'icon': Icons.work, 'done': false},
      {'time': 'Sore', 'activity': 'Memory Game 10 min', 'icon': Icons.games, 'done': false},
      {'time': 'Malam', 'activity': 'Sleep Prep + Relax 15 min', 'icon': Icons.nightlight, 'done': false},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Brain Routine', style: TextStyle(color: SomaTheme.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...routines.map((r) => _buildRoutineItem(r)),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Map<String, dynamic> r) {
    final done = r['done'] as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SomaTheme.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(r['icon'] as IconData, color: SomaTheme.teal, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['time'] as String, style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
                Text(r['activity'] as String, style: TextStyle(color: SomaTheme.text, fontSize: 13)),
              ],
            ),
          ),
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? SomaTheme.tealBright : SomaTheme.textMuted, size: 22),
        ],
      ),
    );
  }

  Widget _buildMotivation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.lavender.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb, color: SomaTheme.lavender, size: 24),
          const SizedBox(height: 12),
          Text('"Otak seperti otot. Kalau tidak dilatih, dia menyusut."',
            style: TextStyle(color: SomaTheme.text, fontSize: 13, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('— Soma', style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}