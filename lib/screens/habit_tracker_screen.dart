import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/soma_theme.dart';

/// HABIT TRACKER
/// Brain-healthy habit list with streaks, weekly view, rewards/badges,
/// and statistics. Preset habits + custom habits, persisted to SharedPreferences.
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  static const _storageKey = 'soma_habits';

  final List<_Habit> _habits = [];

  // Add habit form
  final _nameCtrl = TextEditingController();
  String _newTarget = 'harian'; // harian / mingguan
  IconData _newIcon = Icons.check_circle;
  Color _newColor = SomaTheme.teal;

  static const _iconChoices = [
    Icons.menu_book,
    Icons.fitness_center,
    Icons.bedtime,
    Icons.auto_stories,
    Icons.air,
    Icons.psychology,
    Icons.phone_android,
    Icons.water_drop,
    Icons.check_circle,
    Icons.favorite,
    Icons.self_improvement,
    Icons.sports_esports,
  ];

  static const _colorChoices = [
    SomaTheme.teal,
    SomaTheme.tealBright,
    SomaTheme.lavender,
    SomaTheme.purple,
    SomaTheme.softBlue,
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ============ Persistence ============

  Future<void> _loadHabits() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _habits.clear();
        for (final e in list) {
          _habits.add(_Habit.fromJson(e as Map<String, dynamic>));
        }
      });
    } else {
      // Seed with preset habits
      _seedPresets();
    }
  }

  void _seedPresets() {
    final presets = [
      ('Baca 10 menit', Icons.menu_book, SomaTheme.tealBright, 'harian'),
      ('Olahraga 30 menit', Icons.fitness_center, SomaTheme.purple, 'harian'),
      ('Tidur 7+ jam', Icons.bedtime, SomaTheme.lavender, 'harian'),
      ('Tadarus Quran', Icons.auto_stories, SomaTheme.teal, 'harian'),
      ('Breathing exercise', Icons.air, SomaTheme.softBlue, 'harian'),
      ('Memory game', Icons.psychology, SomaTheme.purple, 'harian'),
      ('No gadget 1 jam sebelum tidur', Icons.phone_android, SomaTheme.lavender, 'harian'),
      ('Minum 8 gelas air', Icons.water_drop, SomaTheme.teal, 'harian'),
    ];
    setState(() {
      for (final p in presets) {
        _habits.add(_Habit(
          name: p.$1,
          icon: p.$2,
          color: p.$3,
          target: p.$4,
          streak: 0,
          record: 0,
          completedDates: [],
        ));
      }
    });
    _persistHabits();
  }

  Future<void> _persistHabits() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _storageKey, jsonEncode(_habits.map((h) => h.toJson()).toList()));
  }

  // ============ Habit operations ============

  String _todayKey() => _dateKey(DateTime.now());

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _toggleToday(_Habit h) {
    final today = _todayKey();
    setState(() {
      if (h.completedDates.contains(today)) {
        h.completedDates.remove(today);
        // Streak may break — recompute conservatively
        h.streak = (h.streak - 1).clamp(0, h.streak);
      } else {
        h.completedDates.add(today);
        // Recompute streak from today backwards
        h.streak = _computeStreak(h);
        if (h.streak > h.record) h.record = h.streak;
      }
    });
    _persistHabits();
  }

  int _computeStreak(_Habit h) {
    int streak = 0;
    DateTime d = DateTime.now();
    // If today not done yet, start from yesterday
    if (!h.completedDates.contains(_dateKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    while (h.completedDates.contains(_dateKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _addHabit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _habits.add(_Habit(
        name: _nameCtrl.text.trim(),
        icon: _newIcon,
        color: _newColor,
        target: _newTarget,
        streak: 0,
        record: 0,
        completedDates: [],
      ));
      _nameCtrl.clear();
    });
    _persistHabits();
  }

  void _deleteHabit(int idx) {
    setState(() => _habits.removeAt(idx));
    _persistHabits();
  }

  // ============ Weekly view helpers ============

  /// Returns 'done', 'miss', 'future', or 'empty' for a given day index (0=Mon..6=Sun)
  String _dayStatus(_Habit h, int dayIdx) {
    final today = DateTime.now();
    final weekday = today.weekday; // 1=Mon..7=Sun
    final monday = today.subtract(Duration(days: weekday - 1));
    final day = monday.add(Duration(days: dayIdx));
    final key = _dateKey(day);
    if (day.isAfter(today)) return 'future';
    if (h.completedDates.contains(key)) return 'done';
    // Miss only if day is before today and not completed
    if (day.isBefore(today)) return 'miss';
    // Today not done yet
    return 'empty';
  }

  int _completedTodayCount() =>
      _habits.where((h) => h.completedDates.contains(_todayKey())).length;

  // ============ Rewards ============

  List<String> _habitBadges(_Habit h) {
    final badges = <String>[];
    if (h.record >= 7) badges.add('7 hari');
    if (h.record >= 30) badges.add('30 hari');
    if (h.record >= 100) badges.add('100 hari');
    return badges;
  }

  bool get _perfectDay => _habits.isNotEmpty && _completedTodayCount() == _habits.length;

  bool get _perfectWeek {
    if (_habits.isEmpty) return false;
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      final key = _dateKey(d);
      for (final h in _habits) {
        if (!h.completedDates.contains(key)) return false;
      }
    }
    return true;
  }

  // ============ Statistics ============

  double _weeklyCompletionRate() {
    if (_habits.isEmpty) return 0;
    final today = DateTime.now();
    int total = 0;
    int done = 0;
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      final key = _dateKey(d);
      for (final h in _habits) {
        total++;
        if (h.completedDates.contains(key)) done++;
      }
    }
    return total == 0 ? 0 : done / total;
  }

  _Habit? get _mostConsistent {
    _Habit? best;
    for (final h in _habits) {
      if (best == null || h.streak > best.streak) best = h;
    }
    return best;
  }

  _Habit? get _mostMissed {
    // Habit with most misses in last 7 days
    _Habit? worst;
    int worstMisses = -1;
    final today = DateTime.now();
    for (final h in _habits) {
      int misses = 0;
      for (int i = 0; i < 7; i++) {
        final d = today.subtract(Duration(days: i));
        if (!h.completedDates.contains(_dateKey(d))) misses++;
      }
      if (misses > worstMisses) {
        worstMisses = misses;
        worst = h;
      }
    }
    return worst;
  }

  List<int> _weeklyDoneCounts() {
    final today = DateTime.now();
    final counts = <int>[];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = _dateKey(d);
      int c = 0;
      for (final h in _habits) {
        if (h.completedDates.contains(key)) c++;
      }
      counts.add(c);
    }
    return counts;
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SomaTheme.bgDeep,
        appBar: AppBar(
          title: const Text('Habit Tracker',
              style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Habit'),
              Tab(text: 'Reward'),
              Tab(text: 'Statistik'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHabitTab(),
            _buildRewardTab(),
            _buildStatsTab(),
          ],
        ),
      ),
    );
  }

  // ---- Habit tab ----
  Widget _buildHabitTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircularProgressIndicator(
                value: _habits.isEmpty ? 0 : _completedTodayCount() / _habits.length,
                backgroundColor: SomaTheme.bgDeep,
                color: SomaTheme.tealBright,
                strokeWidth: 6,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hari Ini',
                        style: TextStyle(
                            color: SomaTheme.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        '${_completedTodayCount()} dari ${_habits.length} habit selesai',
                        style: TextStyle(
                            color: SomaTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Tambah Habit', Icons.add),
        _buildAddHabitForm(),
        const SizedBox(height: 16),
        _sectionTitle('Habit Saya (${_habits.length})', Icons.list),
        ..._habits.asMap().entries.map((e) => _buildHabitCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildAddHabitForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Habit'),
            style: const TextStyle(color: SomaTheme.text),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Target: ', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
              ChoiceChip(
                label: const Text('Harian'),
                selected: _newTarget == 'harian',
                selectedColor: SomaTheme.teal,
                labelStyle: TextStyle(
                    color: _newTarget == 'harian'
                        ? SomaTheme.white
                        : SomaTheme.textMuted),
                onSelected: (_) => setState(() => _newTarget = 'harian'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Mingguan'),
                selected: _newTarget == 'mingguan',
                selectedColor: SomaTheme.teal,
                labelStyle: TextStyle(
                    color: _newTarget == 'mingguan'
                        ? SomaTheme.white
                        : SomaTheme.textMuted),
                onSelected: (_) => setState(() => _newTarget = 'mingguan'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Icon', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _iconChoices.length,
              itemBuilder: (ctx, i) {
                final icon = _iconChoices[i];
                final selected = _newIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _newIcon = icon),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: selected ? SomaTheme.teal.withOpacity(0.2) : SomaTheme.bgDeep,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected ? SomaTheme.tealBright : SomaTheme.teal.withOpacity(0.2)),
                    ),
                    child: Icon(icon,
                        color: selected ? SomaTheme.tealBright : SomaTheme.textMuted,
                        size: 22),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text('Warna', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: _colorChoices.map((c) {
              final selected = _newColor == c;
              return GestureDetector(
                onTap: () => setState(() => _newColor = c),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected ? SomaTheme.white : Colors.transparent,
                        width: 2),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _addHabit,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Habit'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(int idx, _Habit h) {
    final today = _todayKey();
    final doneToday = h.completedDates.contains(today);
    final badges = _habitBadges(h);
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: doneToday ? h.color.withOpacity(0.6) : SomaTheme.teal.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleToday(h),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: doneToday ? h.color : SomaTheme.bgDeep,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: doneToday ? h.color : h.color.withOpacity(0.4),
                        width: 2),
                  ),
                  child: Icon(
                    doneToday ? Icons.check : h.icon,
                    color: doneToday ? SomaTheme.bgDeep : h.color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name,
                        style: TextStyle(
                            color: SomaTheme.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(h.target,
                        style: TextStyle(
                            color: SomaTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              // Streak
              Column(
                children: [
                  Icon(Icons.local_fire_department,
                      color: h.streak > 0 ? Colors.orange : SomaTheme.textMuted,
                      size: 20),
                  Text('${h.streak}',
                      style: TextStyle(
                          color: h.streak > 0 ? Colors.orange : SomaTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 18),
                onPressed: () => _deleteHabit(idx),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weekly view
          Row(
            children: List.generate(7, (i) {
              final status = _dayStatus(h, i);
              Color c;
              IconData? icon;
              if (status == 'done') {
                c = SomaTheme.tealBright;
                icon = Icons.check;
              } else if (status == 'miss') {
                c = Colors.redAccent;
                icon = Icons.close;
              } else if (status == 'future') {
                c = SomaTheme.bgDeep;
              } else {
                c = SomaTheme.bgDeep;
              }
              final isToday = i == (DateTime.now().weekday - 1);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(days[i],
                          style: TextStyle(
                              color: isToday ? SomaTheme.tealBright : SomaTheme.textMuted,
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.normal)),
                      const SizedBox(height: 4),
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: isToday
                                  ? SomaTheme.tealBright
                                  : SomaTheme.teal.withOpacity(0.2),
                              width: isToday ? 1.5 : 1),
                        ),
                        child: icon != null
                            ? Icon(icon, color: SomaTheme.bgDeep, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: badges.map((b) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SomaTheme.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SomaTheme.purple.withOpacity(0.4)),
                  ),
                  child: Text('🏆 $b',
                      style: TextStyle(color: SomaTheme.lavender, fontSize: 10)),
                );
              }).toList(),
            ),
          ],
          if (h.record > 0) ...[
            const SizedBox(height: 4),
            Text('Record: ${h.record} hari',
                style: TextStyle(color: SomaTheme.textMuted, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  // ---- Reward tab ----
  Widget _buildRewardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Perfect Day', Icons.star),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _perfectDay
                    ? SomaTheme.tealBright
                    : SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(
                _perfectDay ? Icons.emoji_events : Icons.emoji_events_outlined,
                color: _perfectDay ? SomaTheme.tealBright : SomaTheme.textMuted,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(_perfectDay ? 'Perfect Day! 🎉' : 'Belum Perfect Day',
                  style: TextStyle(
                      color: _perfectDay ? SomaTheme.white : SomaTheme.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  'Selesaikan semua ${_habits.length} habit hari ini untuk dapatkan badge ini.',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Perfect Week', Icons.calendar_view_week),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _perfectWeek
                    ? SomaTheme.lavender
                    : SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(
                _perfectWeek ? Icons.bolt : Icons.bolt_outlined,
                color: _perfectWeek ? SomaTheme.lavender : SomaTheme.textMuted,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(_perfectWeek ? 'Perfect Week! 🔥' : 'Belum Perfect Week',
                  style: TextStyle(
                      color: _perfectWeek ? SomaTheme.white : SomaTheme.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Selesaikan semua habit 7 hari berturut-turut.',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Milestone Badge', Icons.military_tech),
        ..._habits.map((h) {
          final badges = _habitBadges(h);
          if (badges.isEmpty && h.record < 7) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SomaTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SomaTheme.teal.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(h.icon, color: h.color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(h.name,
                        style: TextStyle(color: SomaTheme.text, fontSize: 13)),
                  ),
                  Text('Record: ${h.record} hari',
                      style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
                ],
              ),
            );
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SomaTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: h.color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(h.icon, color: h.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name,
                          style: TextStyle(
                              color: SomaTheme.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final milestone in [7, 30, 100])
                            if (h.record >= milestone)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SomaTheme.teal.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('🏆 $milestone hari',
                                    style: TextStyle(
                                        color: SomaTheme.tealBright, fontSize: 10)),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text('Record: ${h.record}',
                    style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---- Statistics tab ----
  Widget _buildStatsTab() {
    final rate = _weeklyCompletionRate();
    final doneCounts = _weeklyDoneCounts();
    final maxCount = _habits.length == 0 ? 1 : _habits.length;
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final mostConsistent = _mostConsistent;
    final mostMissed = _mostMissed;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Completion Rate Minggu Ini', Icons.pie_chart),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text('${(rate * 100).round()}%',
                  style: TextStyle(
                      color: SomaTheme.tealBright,
                      fontSize: 36,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: rate,
                backgroundColor: SomaTheme.bgDeep,
                color: SomaTheme.tealBright,
                minHeight: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Habit Paling Konsisten', Icons.local_fire_department),
        _infoCard(
          mostConsistent != null
              ? '${mostConsistent.name} (${mostConsistent.streak} hari streak)'
              : 'Belum ada data',
          SomaTheme.tealBright,
        ),
        const SizedBox(height: 12),
        _sectionTitle('Habit Paling Sering Miss', Icons.warning),
        _infoCard(
          mostMissed != null ? mostMissed.name : 'Belum ada data',
          Colors.redAccent,
        ),
        const SizedBox(height: 16),
        _sectionTitle('Grafik 7 Hari', Icons.bar_chart),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = (doneCounts[i] / maxCount) * 120;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${doneCounts[i]}',
                            style: TextStyle(
                                color: SomaTheme.textMuted, fontSize: 9)),
                        const SizedBox(height: 2),
                        Container(
                          width: double.infinity,
                          height: h,
                          decoration: BoxDecoration(
                            color: i == 6
                                ? SomaTheme.tealBright
                                : SomaTheme.teal.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(days[i],
                            style: TextStyle(
                                color: SomaTheme.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String text, Color c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(color: SomaTheme.white, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionTitle(String t, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: SomaTheme.tealBright, size: 20),
          const SizedBox(width: 8),
          Text(t,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SomaTheme.white)),
        ],
      ),
    );
  }
}

class _Habit {
  final String name;
  final IconData icon;
  final Color color;
  final String target; // harian / mingguan
  int streak;
  int record;
  final List<String> completedDates;

  _Habit({
    required this.name,
    required this.icon,
    required this.color,
    required this.target,
    required this.streak,
    required this.record,
    required this.completedDates,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon.codePoint,
        'color': color.value,
        'target': target,
        'streak': streak,
        'record': record,
        'completedDates': completedDates,
      };

  factory _Habit.fromJson(Map<String, dynamic> j) => _Habit(
        name: j['name'] as String? ?? '',
        icon: IconData(j['icon'] as int? ?? Icons.check.codePoint,
            fontFamily: 'MaterialIcons'),
        color: Color(j['color'] as int? ?? SomaTheme.teal.value),
        target: j['target'] as String? ?? 'harian',
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        record: (j['record'] as num?)?.toInt() ?? 0,
        completedDates: (j['completedDates'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}