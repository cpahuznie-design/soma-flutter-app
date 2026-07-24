import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double brainScore = 83;
  double sleepScore = 100;
  double focusScore = 95;
  double memoryScore = 65;
  double stressLevel = 47;

  String get brainStatus {
    if (brainScore >= 70) return 'Otak Optimal';
    if (brainScore >= 40) return 'Otak Bangkit';
    return 'Otak Tidur';
  }

  Color get statusColor {
    if (brainScore >= 70) return SomaTheme.tealBright;
    if (brainScore >= 40) return SomaTheme.lavender;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Brain Health Score
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: SomaTheme.teal.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Text('Brain Health Score', style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
              const SizedBox(height: 16),
              // Brain SVG placeholder — circle with glow
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [SomaTheme.teal.withOpacity(0.3), SomaTheme.bgCard]),
                  border: Border.all(color: SomaTheme.teal, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${brainScore.round()}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: SomaTheme.tealBright)),
                      Text(brainStatus, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Breakdown bars
              _buildScoreBar('Sleep', sleepScore, SomaTheme.teal),
              _buildScoreBar('Focus', focusScore, SomaTheme.softBlue),
              _buildScoreBar('Memory', memoryScore, SomaTheme.purple),
              _buildScoreBar('Stress', stressLevel, Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Quick Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('8.2h', 'Jam Tidur Semalam', Icons.bedtime),
            _buildStatCard('3', 'Sesi Fokus Hari Ini', Icons.timer),
            _buildStatCard('${memoryScore.round()}', 'Memory Score', Icons.psychology),
            _buildStatCard('${stressLevel.round()}%', 'Stress Level', Icons.waves),
          ],
        ),
        const SizedBox(height: 16),
        // Daily Routine
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Brain Routine', style: TextStyle(color: SomaTheme.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _buildRoutineItem('Pagi', 'Breathing Exercise 5 menit', Icons.wb_sunny, false),
              _buildRoutineItem('Siang', 'Focus Session 25 menit', Icons.work, false),
              _buildRoutineItem('Sore', 'Memory Game 10 menit', Icons.games, false),
              _buildRoutineItem('Malam', 'Sleep Prep + Relax 15 menit', Icons.nightlight, false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Motivation Quote
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SomaTheme.lavender.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.lightbulb, color: SomaTheme.lavender, size: 28),
              const SizedBox(height: 12),
              Text('"Otak seperti otot. Kalau tidak dilatih, dia menyusut."', 
                style: TextStyle(color: SomaTheme.text, fontSize: 14, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('— Soma', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
              Text('${value.round()}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: SomaTheme.bgDeep,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: SomaTheme.teal, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: SomaTheme.white, fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(String time, String activity, IconData icon, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: SomaTheme.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                Text(activity, style: TextStyle(color: SomaTheme.text, fontSize: 14)),
              ],
            ),
          ),
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, 
            color: done ? SomaTheme.tealBright : SomaTheme.textMuted, size: 24),
        ],
      ),
    );
  }
}