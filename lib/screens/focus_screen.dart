import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // ---------- Pomodoro ----------
  int _pMode = 0; // 0 fokus, 1 pendek, 2 panjang
  final List<int> _pDurations = [25 * 60, 5 * 60, 15 * 60];
  int _pSeconds = 25 * 60;
  bool _pRunning = false;
  Timer? _pTimer;
  int _pSessions = 0;
  int _pTotalFocusSec = 0;

  // ---------- Dot Focus ----------
  int _dotDuration = 60;
  int _dotSeconds = 0;
  bool _dotActive = false;
  Timer? _dotTimer;
  String _dotResult = '';

  // ---------- Reaction ----------
  bool _rWaiting = false;
  bool _rReady = false;
  int _rRound = 0;
  final List<int> _rTimes = [];
  DateTime? _rShowTime;
  Timer? _rDelay;
  String _rResult = '';

  // ---------- Countdown Focus ----------
  int _countVal = 100;
  bool _countActive = false;
  Timer? _countTimer;

  // ---------- Focus Level ----------
  double _level = 7;
  final List<int> _weekly = [5, 7, 6, 8, 4, 7, 9];

  @override
  void dispose() {
    _pTimer?.cancel();
    _dotTimer?.cancel();
    _rDelay?.cancel();
    _countTimer?.cancel();
    super.dispose();
  }

  // ============ Pomodoro ============
  void _pStart() {
    if (_pRunning) {
      setState(() => _pRunning = false);
      _pTimer?.cancel();
    } else {
      setState(() => _pRunning = true);
      _pTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          if (_pSeconds > 0) {
            _pSeconds--;
          } else {
            t.cancel();
            _pRunning = false;
            if (_pMode == 0) {
              _pSessions++;
              _pTotalFocusSec += _pDurations[0];
            }
          }
        });
      });
    }
  }

  void _pReset() {
    _pTimer?.cancel();
    setState(() {
      _pRunning = false;
      _pSeconds = _pDurations[_pMode];
    });
  }

  void _pChangeMode(int m) {
    _pTimer?.cancel();
    setState(() {
      _pMode = m;
      _pRunning = false;
      _pSeconds = _pDurations[m];
    });
  }

  String _fmtTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtTotal(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
  }

  // ============ Dot Focus ============
  void _dotStart() {
    _dotTimer?.cancel();
    setState(() {
      _dotActive = true;
      _dotSeconds = _dotDuration;
      _dotResult = '';
    });
    _dotTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _dotSeconds--;
        if (_dotSeconds <= 0) {
          t.cancel();
          _dotActive = false;
          _dotResult = 'Sempurna! Fokus 100%';
        }
      });
    });
  }

  void _dotClick() {
    if (!_dotActive) return;
    _dotTimer?.cancel();
    setState(() {
      _dotActive = false;
      _dotResult = 'Klik terlalu cepat! Sisa ${_dotSeconds}s';
    });
  }

  // ============ Reaction ============
  void _rStart() {
    _rDelay?.cancel();
    setState(() {
      _rWaiting = true;
      _rReady = false;
      _rRound = 0;
      _rTimes.clear();
      _rResult = '';
    });
    _rNext();
  }

  void _rNext() {
    if (_rRound >= 5) {
      final avg = _rTimes.reduce((a, b) => a + b) ~/ _rTimes.length;
      setState(() {
        _rResult = 'Rata-rata: $avg ms';
        _rWaiting = false;
      });
      return;
    }
    setState(() {
      _rWaiting = true;
      _rReady = false;
    });
    final delay = 1500 + (DateTime.now().millisecondsSinceEpoch % 3000);
    _rDelay = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _rWaiting = false;
        _rReady = true;
        _rShowTime = DateTime.now();
      });
    });
  }

  void _rClick() {
    if (!_rReady) return;
    final diff = DateTime.now().difference(_rShowTime!).inMilliseconds;
    setState(() {
      _rTimes.add(diff);
      _rRound++;
    });
    _rNext();
  }

  void _rEarlyClick() {
    if (!_rWaiting) return;
    _rDelay?.cancel();
    setState(() {
      _rResult = 'Terlalu cepat! Ulangi.';
      _rWaiting = false;
    });
  }

  // ============ Countdown Focus ============
  void _countStart() {
    _countTimer?.cancel();
    setState(() {
      _countVal = 100;
      _countActive = true;
    });
    _countTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      setState(() {
        _countVal--;
        if (_countVal <= 0) {
          t.cancel();
          _countActive = false;
        }
      });
    });
  }

  void _countStop() {
    _countTimer?.cancel();
    setState(() => _countActive = false);
  }

  // ============ Focus Level ============
  String _levelEmoji(double v) {
    if (v <= 2) return '😵';
    if (v <= 4) return '😕';
    if (v <= 6) return '😐';
    if (v <= 8) return '🙂';
    return '😃';
  }

  void _saveLevel() {
    setState(() {
      _weekly[_weekly.length - 1] = _level.round();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Level fokus ${_level.round()} tersimpan'),
        backgroundColor: SomaTheme.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SomaTheme.bgDeep,
        appBar: AppBar(
          title: const Text('Focus Therapy', style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pomodoro'),
              Tab(text: 'Training'),
              Tab(text: 'Level'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPomodoro(),
            _buildTraining(),
            _buildLevel(),
          ],
        ),
      ),
    );
  }

  // ============ Pomodoro Tab ============
  Widget _buildPomodoro() {
    final progress = _pSeconds / _pDurations[_pMode];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: List.generate(3, (i) {
            final labels = ['Fokus 25m', 'Pendek 5m', 'Panjang 15m'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(labels[i], style: const TextStyle(fontSize: 11)),
                  selected: _pMode == i,
                  selectedColor: SomaTheme.teal,
                  backgroundColor: SomaTheme.bgCard,
                  labelStyle: TextStyle(color: _pMode == i ? SomaTheme.white : SomaTheme.textMuted),
                  onSelected: (_) => _pChangeMode(i),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _RingPainter(progress, SomaTheme.teal),
              child: Center(
                child: Text(
                  _fmtTime(_pSeconds),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: SomaTheme.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pStart,
              icon: Icon(_pRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_pRunning ? 'Pause' : 'Start'),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _pReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _statCard('Sesi Hari Ini', '$_pSessions', Icons.timer, SomaTheme.tealBright),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard('Total Fokus', _fmtTotal(_pTotalFocusSec), Icons.access_time, SomaTheme.lavender),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: c, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SomaTheme.white)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: SomaTheme.textMuted)),
        ],
      ),
    );
  }

  // ============ Training Tab ============
  Widget _buildTraining() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Dot Focus', Icons.center_focus_strong),
        _card(
          Column(
            children: [
              if (!_dotActive && _dotSeconds == 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 3, 5].map((m) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$m menit'),
                        selected: _dotDuration == m * 60,
                        selectedColor: SomaTheme.teal,
                        backgroundColor: SomaTheme.bgDeep,
                        labelStyle: TextStyle(color: _dotDuration == m * 60 ? SomaTheme.white : SomaTheme.textMuted),
                        onSelected: (_) => setState(() => _dotDuration = m * 60),
                      ),
                    );
                  }).toList(),
                )
              else
                Text('Sisa: ${_dotSeconds}s', style: TextStyle(fontSize: 16, color: SomaTheme.textMuted)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _dotActive ? _dotClick : _dotStart,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dotActive ? SomaTheme.teal : SomaTheme.bgDeep,
                    border: Border.all(color: SomaTheme.teal, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _dotActive ? '•' : (_dotSeconds == 0 ? 'Mulai' : ''),
                      style: TextStyle(fontSize: 48, color: SomaTheme.white),
                    ),
                  ),
                ),
              ),
              if (_dotResult.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_dotResult, style: TextStyle(color: SomaTheme.tealBright, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Reaction Time', Icons.bolt),
        _card(
          Column(
            children: [
              if (_rWaiting)
                GestureDetector(
                  onTap: _rEarlyClick,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: SomaTheme.purple.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text('Tunggu hijau...', style: TextStyle(color: SomaTheme.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )
              else if (_rReady)
                GestureDetector(
                  onTap: _rClick,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: SomaTheme.tealBright,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('KLIK!', style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Round ${_rRound > 0 ? _rRound : 0}/5', style: TextStyle(color: SomaTheme.textMuted, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_rTimes.isNotEmpty)
                        Text('Riwayat: ${_rTimes.join(" ms, ")} ms', style: TextStyle(color: SomaTheme.lavender, fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _rStart,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Mulai'),
                      ),
                    ],
                  ),
                ),
              if (_rResult.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_rResult, style: TextStyle(color: SomaTheme.tealBright, fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Countdown Focus', Icons.looks),
        _card(
          Column(
            children: [
              Text(
                '$_countVal',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: _countActive ? SomaTheme.tealBright : SomaTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _countActive ? null : _countStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Mulai'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _countActive ? _countStop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ Level Tab ============
  Widget _buildLevel() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxV = _weekly.reduce((a, b) => a > b ? a : b).toDouble();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Focus Level Tracker', Icons.insights),
        _card(
          Column(
            children: [
              Text(_levelEmoji(_level), style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text('Level: ${_level.round()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SomaTheme.white)),
              Slider(
                value: _level,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: SomaTheme.teal,
                inactiveColor: SomaTheme.bgDeep,
                thumbColor: SomaTheme.tealBright,
                onChanged: (v) => setState(() => _level = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('😵 1', style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
                  Text('😃 10', style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveLevel,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Weekly Chart', Icons.bar_chart),
        _card(
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = (maxV > 0 ? _weekly[i] / maxV : 0.0) * 140;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: h,
                          decoration: BoxDecoration(
                            color: i == 6 ? SomaTheme.tealBright : SomaTheme.teal.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(days[i], style: TextStyle(color: SomaTheme.textMuted, fontSize: 10)),
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

  // ============ Helpers ============
  Widget _sectionTitle(String t, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: SomaTheme.tealBright, size: 20),
          const SizedBox(width: 8),
          Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SomaTheme.white)),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final bgPaint = Paint()..color = SomaTheme.bgCard..style = PaintingStyle.stroke..strokeWidth = 8;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}