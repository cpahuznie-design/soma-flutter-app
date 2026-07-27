import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/soma_theme.dart';

/// Daily Brain Challenge screen.
///
/// Setiap hari menghasilkan 1 tantangan berdasarkan weekday. Menyimpan
/// progress harian, streak, badge, dan menampilkan leaderboard mock.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  // --- Persisted state -------------------------------------------------
  int _streak = 0;
  int _bestStreak = 14; // "Rencord: 14 hari" default
  int _totalCompleted = 0;
  // weekday -> 'done' | 'missed' | null
  final Map<int, String> _weekStatus = {};
  String _todayKey = '';

  // --- Today's challenge (derived) -------------------------------------
  late final ChallengeOfDay _todayChallenge;

  bool _challengeStarted = false;
  bool _challengeCompleted = false;
  int _elapsedSeconds = 0;

  static const String _prefsKey = 'soma_challenge_data';

  // --- Challenge catalog per weekday ----------------------------------
  // 1 = Monday ... 7 = Sunday
  static final Map<int, ChallengeOfDay> _catalog = {
    1: ChallengeOfDay(
      title: 'Memory Match',
      description: 'Cocokkan 8 pasang kartu dalam 2 menit',
      duration: const Duration(minutes: 2),
      difficulty: 'Medium',
      icon: Icons.flip,
      color: SomaTheme.tealBright,
    ),
    2: ChallengeOfDay(
      title: 'Focus Streak',
      description: 'Tahan fokus 3 menit tanpa gangguan',
      duration: const Duration(minutes: 3),
      difficulty: 'Hard',
      icon: Icons.visibility,
      color: SomaTheme.softBlue,
    ),
    3: ChallengeOfDay(
      title: 'Number Memory',
      description: 'Hafal 6 digit angka',
      duration: const Duration(seconds: 45),
      difficulty: 'Easy',
      icon: Icons.pin,
      color: SomaTheme.lavender,
    ),
    4: ChallengeOfDay(
      title: 'Chess Puzzle',
      description: 'Cari mate in 1',
      duration: const Duration(minutes: 1),
      difficulty: 'Hard',
      icon: Icons.extension,
      color: SomaTheme.purple,
    ),
    5: ChallengeOfDay(
      title: 'Word Recall',
      description: 'Hafal 8 kata dalam 10 detik',
      duration: const Duration(seconds: 10),
      difficulty: 'Medium',
      icon: Icons.text_fields,
      color: SomaTheme.tealBright,
    ),
    6: ChallengeOfDay(
      title: 'Sequence Memory',
      description: 'Ingat urutan 5 kotak',
      duration: const Duration(seconds: 30),
      difficulty: 'Medium',
      icon: Icons.grid_view,
      color: SomaTheme.softBlue,
    ),
    7: ChallengeOfDay(
      title: 'Breathing Marathon',
      description: '8 siklus breathing pilihan Bapak',
      duration: const Duration(minutes: 4),
      difficulty: 'Easy',
      icon: Icons.self_improvement,
      color: SomaTheme.lavender,
    ),
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayChallenge = _catalog[now.weekday]!;
    _todayKey = _dateKey(now);
    _loadData();
  }

  // --- Persistence -----------------------------------------------------

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _streak = (json['streak'] as num?)?.toInt() ?? 0;
          _bestStreak = (json['bestStreak'] as num?)?.toInt() ?? 14;
          _totalCompleted = (json['totalCompleted'] as num?)?.toInt() ?? 0;
          _challengeCompleted =
              (json['lastCompletedDate'] as String?) == _todayKey;
          final ws = json['weekStatus'] as Map<String, dynamic>?;
          if (ws != null) {
            ws.forEach((key, value) {
              final wd = int.tryParse(key);
              if (wd != null) _weekStatus[wd] = value.toString();
            });
          }
        });
      } catch (_) {
        // Corrupt data — start fresh
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final ws = <String, String>{};
    _weekStatus.forEach((k, v) => ws[k.toString()] = v);
    final payload = jsonEncode({
      'streak': _streak,
      'bestStreak': _bestStreak,
      'totalCompleted': _totalCompleted,
      'lastCompletedDate': _challengeCompleted ? _todayKey : null,
      'weekStatus': ws,
    });
    await prefs.setString(_prefsKey, payload);
  }

  // --- Actions ---------------------------------------------------------

  void _startChallenge() {
    setState(() {
      _challengeStarted = true;
      _challengeCompleted = false;
      _elapsedSeconds = 0;
    });
  }

  void _completeChallenge() {
    final now = DateTime.now();
    setState(() {
      _challengeCompleted = true;
      _challengeStarted = false;
      _weekStatus[now.weekday] = 'done';
      _streak += 1;
      _totalCompleted += 1;
      if (_streak > _bestStreak) _bestStreak = _streak;
    });
    _saveData();
  }

  /// Simulate "miss" today (for testing / demo).
  void _missToday() {
    final now = DateTime.now();
    setState(() {
      _weekStatus[now.weekday] = 'missed';
      _streak = 0;
      _challengeStarted = false;
    });
    _saveData();
  }

  // --- Build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Daily Brain Challenge'),
        backgroundColor: SomaTheme.bgDeep,
        foregroundColor: SomaTheme.text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTodayChallenge(),
          const SizedBox(height: 16),
          _buildStreakTracker(),
          const SizedBox(height: 16),
          _buildWeeklyCalendar(),
          const SizedBox(height: 16),
          _buildRewards(),
          const SizedBox(height: 16),
          _buildLeaderboard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1. Today's Challenge ------------------------------------------------
  Widget _buildTodayChallenge() {
    final c = _todayChallenge;
    final remaining =
        c.duration.inSeconds - _elapsedSeconds;
    final progress = c.duration.inSeconds == 0
        ? 0.0
        : (_elapsedSeconds / c.duration.inSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(c.icon, color: c.color, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TANTANGAN HARI INI',
                        style: TextStyle(
                          color: SomaTheme.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Text(c.title,
                        style: TextStyle(
                          color: SomaTheme.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
              _DifficultyBadge(difficulty: c.difficulty),
            ],
          ),
          const SizedBox(height: 16),
          Text(c.description,
              style: TextStyle(color: SomaTheme.text, fontSize: 15, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer, color: SomaTheme.tealBright, size: 18),
              const SizedBox(width: 6),
              Text(
                _formatDuration(c.duration),
                style: TextStyle(
                  color: SomaTheme.tealBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_challengeStarted) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: SomaTheme.bgDeep,
                valueColor: AlwaysStoppedAnimation(c.color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sisa ${_formatDuration(Duration(seconds: remaining < 0 ? 0 : remaining))}',
              style: TextStyle(color: SomaTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _completeChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SomaTheme.tealBright,
                      foregroundColor: SomaTheme.bgDeep,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tandai Selesai',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _challengeStarted = false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SomaTheme.textMuted,
                    side: BorderSide(color: SomaTheme.textMuted),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ] else if (_challengeCompleted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SomaTheme.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SomaTheme.tealBright),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: SomaTheme.tealBright),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Challenge hari ini selesai! Streak: $_streak hari 🔥',
                      style: TextStyle(
                          color: SomaTheme.tealBright,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.color,
                  foregroundColor: SomaTheme.bgDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Mulai Challenge',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _missToday,
              child: Text('Lewati hari ini (streak reset)',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  // 2. Streak Tracker ---------------------------------------------------
  Widget _buildStreakTracker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SomaTheme.purple.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_fire_department,
                color: Colors.orange, size: 36),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_streak',
                    style: TextStyle(
                      color: SomaTheme.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    )),
                Text('hari berturut-turut',
                    style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Rencord: $_bestStreak hari',
                    style: TextStyle(
                        color: SomaTheme.lavender,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (_streak > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text('$_streak',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 3. Weekly Calendar --------------------------------------------------
  Widget _buildWeeklyCalendar() {
    final now = DateTime.now();
    final today = now.weekday;
    final labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Minggu Ini',
              style: TextStyle(
                  color: SomaTheme.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final wd = i + 1;
              final status = _weekStatus[wd];
              final isToday = wd == today;
              final isDone = status == 'done';
              final isMissed = status == 'missed';
              final isPast = wd < today;

              Color? bg;
              Color? fg;
              IconData? mark;
              if (isDone) {
                bg = SomaTheme.teal;
                fg = SomaTheme.white;
                mark = Icons.check;
              } else if (isMissed) {
                bg = Colors.red.withOpacity(0.25);
                fg = Colors.red.shade300;
                mark = Icons.close;
              } else if (isToday) {
                bg = SomaTheme.tealBright.withOpacity(0.2);
                fg = SomaTheme.tealBright;
              } else if (isPast) {
                // Past day without status = implicitly missed
                bg = Colors.red.withOpacity(0.1);
                fg = Colors.red.shade300.withOpacity(0.5);
                mark = Icons.close;
              } else {
                bg = SomaTheme.bgDeep;
                fg = SomaTheme.textMuted;
              }

              return Column(
                children: [
                  Text(labels[i],
                      style: TextStyle(
                          color: isToday
                              ? SomaTheme.tealBright
                              : SomaTheme.textMuted,
                          fontSize: 11,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: SomaTheme.tealBright, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: mark != null
                          ? Icon(mark, color: fg, size: 18)
                          : Text(
                              '${now.day + (wd - today)}'.toString(),
                              style: TextStyle(
                                  color: fg, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(SomaTheme.teal, 'Selesai'),
              const SizedBox(width: 16),
              _legendDot(Colors.red.shade300, 'Miss'),
              const SizedBox(width: 16),
              _legendDot(SomaTheme.tealBright, 'Hari ini'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
      ],
    );
  }

  // 4. Rewards / Badges -------------------------------------------------
  Widget _buildRewards() {
    final milestones = [
      Milestone(days: 3, label: '3 Hari', icon: Icons.emoji_events, color: SomaTheme.tealBright),
      Milestone(days: 7, label: '7 Hari', icon: Icons.star, color: SomaTheme.softBlue),
      Milestone(days: 14, label: '14 Hari', icon: Icons.workspace_premium, color: SomaTheme.lavender),
      Milestone(days: 30, label: '30 Hari', icon: Icons.diamond, color: SomaTheme.purple),
      Milestone(days: 100, label: '100 Hari', icon: Icons.celebration, color: Colors.orange),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.lavender.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reward Badge',
                  style: TextStyle(
                      color: SomaTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              Text('Total: $_totalCompleted selesai',
                  style: TextStyle(
                      color: SomaTheme.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: milestones.map((m) {
              final achieved = _bestStreak >= m.days;
              return Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: achieved
                          ? m.color.withOpacity(0.18)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: achieved ? m.color : Colors.grey.shade700,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      m.icon,
                      color: achieved ? m.color : Colors.grey,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(m.label,
                      style: TextStyle(
                          color: achieved ? m.color : SomaTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 5. Leaderboard ------------------------------------------------------
  Widget _buildLeaderboard() {
    final top5 = [
      {'name': 'Andi Wijaya', 'score': 1240},
      {'name': 'Siti Rahma', 'score': 1180},
      {'name': 'Budi Santoso', 'score': 1050},
      {'name': 'Dewi Lestari', 'score': 980},
      {'name': 'Rudi Hartono', 'score': 920},
    ];
    final ranks = ['1', '2', '3', '4', '5'];
    final rankColors = [
      Colors.amber,
      Colors.grey.shade300,
      Colors.brown.shade300,
      SomaTheme.textMuted,
      SomaTheme.textMuted,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.softBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: SomaTheme.softBlue, size: 20),
              const SizedBox(width: 8),
              Text('Leaderboard Mingguan',
                  style: TextStyle(
                      color: SomaTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: SomaTheme.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SomaTheme.teal.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin, color: SomaTheme.tealBright, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anda rank #142 dari 1,200 pengguna SOMA minggu ini',
                    style: TextStyle(
                        color: SomaTheme.tealBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(top5.length, (i) {
            final e = top5[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rankColors[i].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(ranks[i],
                          style: TextStyle(
                              color: rankColors[i],
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e['name'] as String,
                        style: TextStyle(
                            color: SomaTheme.text, fontSize: 14)),
                  ),
                  Text('${e['score']} pts',
                      style: TextStyle(
                          color: SomaTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Helpers ---------------------------------------------------------
  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}j ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}

// --- Models -----------------------------------------------------------

class ChallengeOfDay {
  final String title;
  final String description;
  final Duration duration;
  final String difficulty; // Easy | Medium | Hard
  final IconData icon;
  final Color color;

  const ChallengeOfDay({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.icon,
    required this.color,
  });
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final map = {
      'Easy': (SomaTheme.tealBright, 'Easy'),
      'Medium': (SomaTheme.lavender, 'Medium'),
      'Hard': (SomaTheme.purple, 'Hard'),
    };
    final entry = map[difficulty] ?? (SomaTheme.textMuted, difficulty);
    final color = entry.$1;
    final label = entry.$2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class Milestone {
  final int days;
  final String label;
  final IconData icon;
  final Color color;
  const Milestone({
    required this.days,
    required this.label,
    required this.icon,
    required this.color,
  });
}