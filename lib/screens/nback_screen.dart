import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/soma_theme.dart';

/// N-BACK TRAINING
/// Working memory game (visual position + letter mode) with scoring,
/// progress chart, achievements, and instructions.
class NBackScreen extends StatefulWidget {
  const NBackScreen({super.key});

  @override
  State<NBackScreen> createState() => _NBackScreenState();
}

class _NBackScreenState extends State<NBackScreen> {
  // Game setup
  int _nLevel = 2; // 1, 2, or 3
  bool _letterMode = false; // false = position, true = letter
  static const int _totalTrials = 20;
  static const int _trialDurationMs = 3000; // 500ms flash + 2500ms gap
  static const int _flashDurationMs = 500;

  // Game state
  bool _playing = false;
  int _currentTrial = 0;
  int _activeCell = -1;
  String _activeLetter = '';
  final List<int> _positionHistory = [];
  final List<String> _letterHistory = [];
  final List<bool> _userAnswers = []; // true = match pressed
  final List<int> _reactionTimes = [];
  int _trialStartTime = 0;
  Timer? _trialTimer;
  Timer? _flashTimer;
  bool _awaitingAnswer = false;

  // Score
  int _correct = 0;
  double _accuracy = 0;
  int _avgReactionMs = 0;

  // Persisted
  final List<double> _recentAccuracies = []; // 7 most recent sessions
  int _bestScore1 = 0;
  int _bestScore2 = 0;
  int _bestScore3 = 0;
  int _highestLevel = 1;
  int _sessionsCompleted = 0;
  int _sessionsIn7Days = 0;
  String _lastSessionDate = '';
  final List<String> _sessionDates = [];

  // Achievements
  bool _achFirstTry = false;
  bool _achSharpMind = false;
  bool _achGenius = false;
  bool _achConsistent = false;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _trialTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  // ============ Persistence ============

  Future<void> _loadProgress() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _bestScore1 = sp.getInt('soma_nback_best_1') ?? 0;
      _bestScore2 = sp.getInt('soma_nback_best_2') ?? 0;
      _bestScore3 = sp.getInt('soma_nback_best_3') ?? 0;
      _highestLevel = sp.getInt('soma_nback_highest') ?? 1;
      _sessionsCompleted = sp.getInt('soma_nback_sessions') ?? 0;
      _lastSessionDate = sp.getString('soma_nback_last_date') ?? '';
      _achFirstTry = sp.getBool('soma_nback_ach_first') ?? false;
      _achSharpMind = sp.getBool('soma_nback_ach_sharp') ?? false;
      _achGenius = sp.getBool('soma_nback_ach_genius') ?? false;
      _achConsistent = sp.getBool('soma_nback_ach_consistent') ?? false;
    });
    final histRaw = sp.getString('soma_nback_history');
    if (histRaw != null) {
      final h = jsonDecode(histRaw) as List;
      for (final e in h) {
        _recentAccuracies.add((e as num).toDouble());
      }
      if (_recentAccuracies.length > 7) {
        _recentAccuracies.removeRange(0, _recentAccuracies.length - 7);
      }
    }
    final datesRaw = sp.getString('soma_nback_dates');
    if (datesRaw != null) {
      _sessionDates.clear();
      _sessionDates.addAll((jsonDecode(datesRaw) as List).cast<String>());
    }
    _updateConsistent();
  }

  Future<void> _persistProgress() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('soma_nback_best_1', _bestScore1);
    await sp.setInt('soma_nback_best_2', _bestScore2);
    await sp.setInt('soma_nback_best_3', _bestScore3);
    await sp.setInt('soma_nback_highest', _highestLevel);
    await sp.setInt('soma_nback_sessions', _sessionsCompleted);
    await sp.setString('soma_nback_last_date', _lastSessionDate);
    await sp.setBool('soma_nback_ach_first', _achFirstTry);
    await sp.setBool('soma_nback_ach_sharp', _achSharpMind);
    await sp.setBool('soma_nback_ach_genius', _achGenius);
    await sp.setBool('soma_nback_ach_consistent', _achConsistent);
    await sp.setString(
        'soma_nback_history', jsonEncode(_recentAccuracies));
    await sp.setString('soma_nback_dates', jsonEncode(_sessionDates));
  }

  void _updateConsistent() {
    final today = _today();
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      if (_sessionDates.contains(d)) count++;
    }
    _sessionsIn7Days = count;
    _achConsistent = count >= 7;
  }

  DateTime _today() => DateTime.now();

  // ============ Game logic ============

  void _startGame() {
    setState(() {
      _playing = true;
      _currentTrial = 0;
      _positionHistory.clear();
      _letterHistory.clear();
      _userAnswers.clear();
      _reactionTimes.clear();
      _correct = 0;
      _accuracy = 0;
      _avgReactionMs = 0;
      _activeCell = -1;
      _activeLetter = '';
      _awaitingAnswer = false;
    });
    _runTrial();
  }

  void _runTrial() {
    if (_currentTrial >= _totalTrials) {
      _endGame();
      return;
    }
    final rng = Random();
    final cell = rng.nextInt(9);
    final letter = _letters[rng.nextInt(_letters.length)];
    setState(() {
      _activeCell = cell;
      _activeLetter = letter;
      _positionHistory.add(cell);
      _letterHistory.add(letter);
      _awaitingAnswer = true;
      _trialStartTime = DateTime.now().millisecondsSinceEpoch;
    });

    // Flash off after 500ms
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: _flashDurationMs), () {
      if (!mounted) return;
      setState(() {
        _activeCell = -1;
      });
    });

    // Next trial after 3s
    _trialTimer?.cancel();
    _trialTimer = Timer(const Duration(milliseconds: _trialDurationMs), () {
      if (!mounted) return;
      // If user didn't answer, treat as "no match" (no press)
      if (_awaitingAnswer) {
        _userAnswers.add(false);
        _reactionTimes.add(_trialDurationMs);
        _evaluateTrial(false, _trialDurationMs);
      }
      setState(() {
        _currentTrial++;
      });
      _runTrial();
    });
  }

  void _userAnswer(bool matchPressed) {
    if (!_awaitingAnswer) return;
    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartTime;
    _userAnswers.add(matchPressed);
    _reactionTimes.add(rt);
    _evaluateTrial(matchPressed, rt);
    setState(() {
      _awaitingAnswer = false;
    });
  }

  void _evaluateTrial(bool matchPressed, int rt) {
    final nIdx = _positionHistory.length - _nLevel - 1;
    bool isMatch;
    if (_letterMode) {
      isMatch = nIdx >= 0 &&
          _letterHistory.last == _letterHistory[nIdx];
    } else {
      isMatch = nIdx >= 0 &&
          _positionHistory.last == _positionHistory[nIdx];
    }
    if (matchPressed == isMatch) {
      _correct++;
    }
    // Use rt for stats
    _reactionTimes.add(rt);
  }

  void _endGame() {
    _trialTimer?.cancel();
    _flashTimer?.cancel();
    setState(() {
      _playing = false;
      _accuracy = _totalTrials > 0 ? _correct / _totalTrials : 0;
      _avgReactionMs = _reactionTimes.isEmpty
          ? 0
          : (_reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length);
    });

    // Save best score
    final scorePct = (_accuracy * 100).round();
    if (_nLevel == 1 && scorePct > _bestScore1) _bestScore1 = scorePct;
    if (_nLevel == 2 && scorePct > _bestScore2) _bestScore2 = scorePct;
    if (_nLevel == 3 && scorePct > _bestScore3) _bestScore3 = scorePct;
    if (_nLevel > _highestLevel && _accuracy >= 0.7) {
      _highestLevel = _nLevel;
    }

    // Update session count
    _sessionsCompleted++;
    final todayStr = _today().toIso8601String().substring(0, 10);
    _lastSessionDate = todayStr;
    _sessionDates.add(todayStr);
    if (_sessionDates.length > 30) {
      _sessionDates.removeRange(0, _sessionDates.length - 30);
    }
    _recentAccuracies.add(_accuracy);
    if (_recentAccuracies.length > 7) {
      _recentAccuracies.removeRange(0, _recentAccuracies.length - 7);
    }

    // Achievements
    if (_sessionsCompleted >= 1) _achFirstTry = true;
    if (_nLevel == 2 && _accuracy >= 0.8) _achSharpMind = true;
    if (_nLevel == 3 && _accuracy >= 0.7) _achGenius = true;
    _updateConsistent();

    _persistProgress();
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SomaTheme.bgDeep,
        appBar: AppBar(
          title: const Text('N-Back Training',
              style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Game'),
              Tab(text: 'Progress'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGameTab(),
            _buildProgressTab(),
            _buildInfoTab(),
          ],
        ),
      ),
    );
  }

  // ---- Game tab ----
  Widget _buildGameTab() {
    if (_playing) return _buildGamePlay();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Setup', Icons.settings),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text('Level N-Back',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3].map((n) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text('$n-back'),
                      selected: _nLevel == n,
                      selectedColor: SomaTheme.teal,
                      labelStyle: TextStyle(
                          color: _nLevel == n
                              ? SomaTheme.white
                              : SomaTheme.textMuted),
                      onSelected: (_) => setState(() => _nLevel = n),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Posisi'),
                    selected: !_letterMode,
                    selectedColor: SomaTheme.purple,
                    labelStyle: TextStyle(
                        color: !_letterMode
                            ? SomaTheme.white
                            : SomaTheme.textMuted),
                    onSelected: (_) => setState(() => _letterMode = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Huruf'),
                    selected: _letterMode,
                    selectedColor: SomaTheme.purple,
                    labelStyle: TextStyle(
                        color: _letterMode
                            ? SomaTheme.white
                            : SomaTheme.textMuted),
                    onSelected: (_) => setState(() => _letterMode = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Sesi (20 trial)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Score summary
        _sectionTitle('Skor Terakhir', Icons.score),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox('Accuracy', '${(_accuracy * 100).round()}%',
                      SomaTheme.tealBright),
                  _statBox('Avg RT', '${_avgReactionMs}ms', SomaTheme.lavender),
                  _statBox('Benar', '$_correct/$_totalTrials', SomaTheme.softBlue),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox('Best 1-back', '$_bestScore1%', SomaTheme.teal),
                  _statBox('Best 2-back', '$_bestScore2%', SomaTheme.teal),
                  _statBox('Best 3-back', '$_bestScore3%', SomaTheme.teal),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamePlay() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Trial ${_currentTrial + 1} / $_totalTrials — $_nLevel-back',
          textAlign: TextAlign.center,
          style: TextStyle(color: SomaTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentTrial + 1) / _totalTrials,
          backgroundColor: SomaTheme.bgCard,
          color: SomaTheme.tealBright,
          minHeight: 6,
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (ctx, i) {
                final active = _activeCell == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: active ? SomaTheme.tealBright : SomaTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: active
                            ? SomaTheme.tealBright
                            : SomaTheme.teal.withOpacity(0.3),
                        width: active ? 2 : 1),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: SomaTheme.tealBright.withOpacity(0.5),
                                blurRadius: 20)
                          ]
                        : null,
                  ),
                  child: Center(
                    child: active && _letterMode
                        ? Text(_activeLetter,
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: SomaTheme.bgDeep))
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _awaitingAnswer ? () => _userAnswer(true) : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('MATCH'),
              style: ElevatedButton.styleFrom(backgroundColor: SomaTheme.teal),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _awaitingAnswer ? () => _userAnswer(false) : null,
              icon: const Icon(Icons.cancel),
              label: const Text('NO MATCH'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: SomaTheme.purple),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {
              _trialTimer?.cancel();
              _flashTimer?.cancel();
              setState(() => _playing = false);
            },
            icon: const Icon(Icons.stop, color: Colors.redAccent),
            label: const Text('Stop',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ),
      ],
    );
  }

  // ---- Progress tab ----
  Widget _buildProgressTab() {
    final maxAcc = _recentAccuracies.isEmpty
        ? 1.0
        : _recentAccuracies.reduce((a, b) => a > b ? a : b);
    final days = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7'];
    String trend = '—';
    if (_recentAccuracies.length >= 2) {
      final first = _recentAccuracies.first;
      final last = _recentAccuracies.last;
      if (last > first + 0.05) {
        trend = '↑ Naik';
      } else if (last < first - 0.05) {
        trend = '↓ Turun';
      } else {
        trend = '→ Stabil';
      }
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Progress', Icons.trending_up),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox('Sesi', '$_sessionsCompleted', SomaTheme.softBlue),
                  _statBox('Level Tertinggi', '$_highestLevel-back',
                      SomaTheme.tealBright),
                  _statBox('7 Hari', '$_sessionsIn7Days', SomaTheme.lavender),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Accuracy 7 Sesi Terakhir', Icons.bar_chart),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final has = i < _recentAccuracies.length;
                    final acc = has ? _recentAccuracies[i] : 0.0;
                    final h = (acc / (maxAcc == 0 ? 1 : maxAcc)) * 120;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(has ? '${(acc * 100).round()}%' : '-',
                                style: TextStyle(
                                    color: SomaTheme.textMuted, fontSize: 9)),
                            const SizedBox(height: 2),
                            Container(
                              width: double.infinity,
                              height: has ? h : 2,
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
              const SizedBox(height: 12),
              Text('Tren: $trend',
                  style: TextStyle(
                      color: SomaTheme.lavender,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Achievements', Icons.emoji_events),
        _buildAchievements(),
      ],
    );
  }

  Widget _buildAchievements() {
    final badges = [
      {'name': 'First Try', 'icon': '🎯', 'desc': 'Selesaikan 1 sesi', 'unlocked': _achFirstTry},
      {'name': 'Sharp Mind', 'icon': '⚡', 'desc': 'Accuracy >80% di 2-back', 'unlocked': _achSharpMind},
      {'name': 'Genius', 'icon': '🧠', 'desc': '3-back accuracy >70%', 'unlocked': _achGenius},
      {'name': 'Consistent', 'icon': '🔥', 'desc': '7 sesi dalam 7 hari', 'unlocked': _achConsistent},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: badges.map((b) {
        final unlocked = b['unlocked'] as bool;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: unlocked
                    ? SomaTheme.tealBright
                    : SomaTheme.textMuted.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Opacity(
                  opacity: unlocked ? 1 : 0.3,
                  child: Text(b['icon'] as String, style: const TextStyle(fontSize: 28))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b['name'] as String,
                        style: TextStyle(
                            color: unlocked ? SomaTheme.white : SomaTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text(b['desc'] as String,
                        style: TextStyle(
                            color: SomaTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---- Info tab ----
  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Cara Main', Icons.school),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'N-Back adalah latihan working memory paling ilmiah. '
                'Penelitian membuktikan naikkan IQ dan fluid intelligence.',
                style: TextStyle(color: SomaTheme.text, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _infoStep('1', 'Pilih level (1-back, 2-back, atau 3-back).'),
              _infoStep('2', 'Setiap trial, sebuah kotak akan menyala (atau huruf muncul).'),
              _infoStep('3', 'Tekan MATCH jika kotak/huruf sekarang sama dengan N langkah sebelumnya.'),
              _infoStep('4', 'Tekan NO MATCH jika berbeda.'),
              _infoStep('5', '20 trial per sesi. Setiap trial 3 detik.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Tips', Icons.lightbulb),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.lavender.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡 Mulai dari 1-back, naik ke 2-back setelah accuracy >80%.',
                  style: TextStyle(color: SomaTheme.text, fontSize: 13)),
              const SizedBox(height: 8),
              Text('💡 Latih 15-20 menit sehari untuk hasil terbaik.',
                  style: TextStyle(color: SomaTheme.text, fontSize: 13)),
              const SizedBox(height: 8),
              Text('💡 Mode posisi melatih spasial, mode huruf melatih verbal.',
                  style: TextStyle(color: SomaTheme.text, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SomaTheme.teal,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(num,
                style: TextStyle(
                    color: SomaTheme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(color: SomaTheme.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ---- Helpers ----
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

  Widget _statBox(String label, String value, Color c) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}