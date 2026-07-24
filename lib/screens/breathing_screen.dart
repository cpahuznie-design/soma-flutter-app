import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../theme/soma_theme.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> {
  String _technique = '478';
  bool _running = false;
  bool _paused = false;
  int _phaseIdx = 0;
  int _secondsLeft = 0;
  int _cycles = 0;
  String _phaseName = '';
  double _circleScale = 1.0;
  Color _circleColor = SomaTheme.teal;

  // Audio via SystemSound (no external package needed)
  // Vibration handles physical feedback, SystemSound handles audio feedback
  Timer? _audioSweepTimer;

  final _techniques = {
    '478': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright},
      {'name': 'Tahan', 'dur': 7, 'scale': 1.8, 'color': SomaTheme.softBlue},
      {'name': 'Hembuskan', 'dur': 8, 'scale': 1.0, 'color': SomaTheme.lavender},
    ],
    'box': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright},
      {'name': 'Tahan', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.softBlue},
      {'name': 'Hembuskan', 'dur': 4, 'scale': 1.0, 'color': SomaTheme.lavender},
      {'name': 'Tahan', 'dur': 4, 'scale': 1.0, 'color': SomaTheme.softBlue},
    ],
    'calm': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright},
      {'name': 'Hembuskan', 'dur': 6, 'scale': 1.0, 'color': SomaTheme.lavender},
    ],
  };

  @override
  void dispose() {
    _audioSweepTimer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _running = true;
      _paused = false;
      _phaseIdx = 0;
      _secondsLeft = 0;
      _cycles = 0;
    });
    _enterPhase();
  }

  void _enterPhase() {
    if (!_running || _paused) return;
    final phases = _techniques[_technique]!;
    final phase = phases[_phaseIdx];
    final phaseName = phase['name'] as String;

    setState(() {
      _secondsLeft = (phase['dur'] as int);
      _phaseName = phaseName;
      _circleScale = (phase['scale'] as double);
      _circleColor = phase['color'] as Color;
    });

    // Vibration per phase
    _vibrate(phaseName);

    // Audio tone per phase
    _playPhaseAudio(phaseName, (phase['dur'] as int));

    _runCountdown();
  }

  void _runCountdown() {
    if (!_running || _paused) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (!_running || _paused) return;
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft > 0) {
        _runCountdown();
      } else {
        setState(() {
          _phaseIdx++;
        });
        final phases = _techniques[_technique]!;
        if (_phaseIdx >= phases.length) {
          setState(() {
            _phaseIdx = 0;
            _cycles++;
          });
        }
        _enterPhase();
      }
    });
  }

  void _vibrate(String phaseName) {
    try {
      if (phaseName == 'Tarik Napas') {
        Vibration.vibrate(pattern: [100, 50, 200, 50, 400]);
      } else if (phaseName == 'Tahan') {
        Vibration.vibrate(pattern: [80, 100, 80]);
      } else if (phaseName == 'Hembuskan') {
        Vibration.vibrate(pattern: [300, 50, 200, 50, 100]);
      }
    } catch (_) {
      // Vibration not supported on all devices — ignore.
    }
  }

  /// Play system sound for breathing phase feedback.
  /// Uses SystemSound (no external package needed, works on all platforms).
  Future<void> _playPhaseAudio(String phaseName, int durationSec) async {
    _audioSweepTimer?.cancel();
    try {
      // Play a system click sound at the start of each phase
      await SystemSound.play(SystemSoundType.click);
      
      // For inhale/exhale, play periodic clicks to simulate rising/falling tone
      if (phaseName == 'Tarik Napas' || phaseName == 'Hembuskan') {
        final int steps = durationSec;
        int i = 0;
        _audioSweepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          i++;
          if (i >= steps) {
            t.cancel();
          } else {
            SystemSound.play(SystemSoundType.click);
          }
        });
      }
    } catch (_) {
      // Audio may fail on some platforms — ignore.
    }
  }

  void _pause() {
    setState(() {
      _paused = !_paused;
    });
    if (!_paused) {
      _runCountdown();
    } else {
      _audioSweepTimer?.cancel();
    }
  }

  void _stop() {
    _audioSweepTimer?.cancel();
    setState(() {
      _running = false;
      _paused = false;
      _phaseIdx = 0;
      _secondsLeft = 0;
      _cycles = 0;
      _phaseName = '';
      _circleScale = 1.0;
      _circleColor = SomaTheme.teal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Breathing Exercise',
            style: TextStyle(
                color: SomaTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Latih pernapasan untuk menenangkan pikiran',
            style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 24),
        // Technique selector
        Row(
          children: [
            _buildTechButton('4-7-8', '478'),
            const SizedBox(width: 8),
            _buildTechButton('Box', 'box'),
            const SizedBox(width: 8),
            _buildTechButton('Calm', 'calm'),
          ],
        ),
        const SizedBox(height: 32),
        // Breathing circle
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: 200 * _circleScale,
            height: 200 * _circleScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [_circleColor.withOpacity(0.3), SomaTheme.bgCard]),
              border: Border.all(color: _circleColor, width: 3),
              boxShadow: [
                BoxShadow(color: _circleColor.withOpacity(0.4), blurRadius: 30)
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_running)
                    Text(_phaseName,
                        style: TextStyle(
                            color: SomaTheme.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600))
                  else
                    Text('Tekan Start',
                        style: TextStyle(
                            color: SomaTheme.textMuted, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_running)
                    Text('$_secondsLeft',
                        style: TextStyle(
                            color: _circleColor,
                            fontSize: 48,
                            fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Siklus: $_cycles',
            style: TextStyle(color: SomaTheme.textMuted, fontSize: 14),
            textAlign: TextAlign.center),
        if (_cycles >= 4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Alhamdulillah! Anda merasa lebih tenang? 🌿',
                style: TextStyle(color: SomaTheme.tealBright, fontSize: 14),
                textAlign: TextAlign.center),
          ),
        const SizedBox(height: 32),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_running)
              ElevatedButton.icon(
                onPressed: _startBreathing,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _pause,
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                label: Text(_paused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _stop,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTechButton(String label, String tech) {
    final active = _technique == tech;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!_running) setState(() => _technique = tech);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? SomaTheme.teal.withOpacity(0.2) : SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? SomaTheme.teal : SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? SomaTheme.tealBright : SomaTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}