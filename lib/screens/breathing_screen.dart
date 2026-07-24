import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
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

  final AudioPlayer _audioPlayer = AudioPlayer();
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
    _audioPlayer.dispose();
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

  /// Play a tone that sweeps (inhale/exhale) or holds steady (hold).
  /// Uses AudioPlayer's setSourceAsset-free approach: we generate a tone
  /// via release mode + UrlSource pointing to a tiny generated WAV is not
  /// available, so we use short beeps in a sweep pattern via play() with
  /// successive UrlSources is not feasible either. Instead we use a
  /// short tone using the player's `setReleaseMode` and loop a generated
  /// sine via bytes using a data URI with audio/wav is unsupported.
  ///
  /// Simplest portable approach: play a short tone for the phase and update
  /// the pitch via a sweep timer when inhale/exhale.
  Future<void> _playPhaseAudio(String phaseName, int durationSec) async {
    _audioSweepTimer?.cancel();
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.25);

      if (phaseName == 'Tarik Napas') {
        // Rising pitch 220 -> 440 Hz over the phase duration.
        const double startHz = 220;
        const double endHz = 440;
        await _playTone(startHz);
        final int steps = durationSec * 4;
        final double stepHz = (endHz - startHz) / steps;
        final Duration stepDur = Duration(
          milliseconds: (durationSec * 1000) ~/ steps,
        );
        int i = 0;
        _audioSweepTimer = Timer.periodic(stepDur, (t) {
          i++;
          if (i >= steps) {
            t.cancel();
          } else {
            _playTone(startHz + stepHz * i);
          }
        });
      } else if (phaseName == 'Tahan') {
        // Steady 330 Hz.
        await _playTone(330);
      } else if (phaseName == 'Hembuskan') {
        // Falling pitch 440 -> 165 Hz over the phase duration.
        const double startHz = 440;
        const double endHz = 165;
        await _playTone(startHz);
        final int steps = durationSec * 4;
        final double stepHz = (endHz - startHz) / steps;
        final Duration stepDur = Duration(
          milliseconds: (durationSec * 1000) ~/ steps,
        );
        int i = 0;
        _audioSweepTimer = Timer.periodic(stepDur, (t) {
          i++;
          if (i >= steps) {
            t.cancel();
          } else {
            _playTone(startHz + stepHz * i);
          }
        });
      }
    } catch (_) {
      // Audio playback may fail on unsupported platforms — ignore.
    }
  }

  /// Generate and play a short sine-wave tone at the given frequency.
  /// Builds a minimal WAV in memory and plays it via BytesSource.
  Future<void> _playTone(double freqHz) async {
    try {
      final bytes = _generateSineWave(freqHz, 0.3, 8000);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (_) {
      // Ignore audio errors.
    }
  }

  /// Generate a small mono 16-bit PCM sine-wave WAV blob.
  Uint8List _generateSineWave(double freq, double durationSec, int sampleRate) {
    final int numSamples = (durationSec * sampleRate).toInt();
    final int dataSize = numSamples * 2;
    final int totalSize = 44 + dataSize;
    final ByteData data = ByteData(totalSize);

    // RIFF header
    data.setUint8(0, 0x52); // 'R'
    data.setUint8(1, 0x49); // 'I'
    data.setUint8(2, 0x46); // 'F'
    data.setUint8(3, 0x46); // 'F'
    data.setUint32(4, totalSize - 8, Endian.little);
    data.setUint8(8, 0x57);  // 'W'
    data.setUint8(9, 0x41);  // 'A'
    data.setUint8(10, 0x56); // 'V'
    data.setUint8(11, 0x45); // 'E'

    // fmt chunk
    data.setUint8(12, 0x66); // 'f'
    data.setUint8(13, 0x6d); // 'm'
    data.setUint8(14, 0x74); // 't'
    data.setUint8(15, 0x20); // ' '
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    data.setUint16(32, 2, Endian.little); // block align
    data.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    data.setUint8(36, 0x64); // 'd'
    data.setUint8(37, 0x61); // 'a'
    data.setUint8(38, 0x74); // 't'
    data.setUint8(39, 0x61); // 'a'
    data.setUint32(40, dataSize, Endian.little);

    const double twoPi = 2 * math.pi;
    const double amplitude = 0.4;
    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double sampleValue =
          amplitude * math.sin(twoPi * freq * t);
      final int value = (32767 * sampleValue).toInt();
      data.setInt16(offset, value, Endian.little);
      offset += 2;
    }
    return data.buffer.asUint8List(0, totalSize);
  }

  void _pause() {
    setState(() {
      _paused = !_paused;
    });
    if (!_paused) {
      _runCountdown();
    } else {
      _audioSweepTimer?.cancel();
      _audioPlayer.pause();
    }
  }

  void _stop() {
    _audioSweepTimer?.cancel();
    _audioPlayer.stop();
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