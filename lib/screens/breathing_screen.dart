import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:just_audio/just_audio.dart';
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
  Timer? _audioTimer;
  Timer? _ambientTimer;
  AudioPlayer? _audioPlayer;
  bool _audioReady = false;

  final _techniqueInfo = {
    '478': {
      'title': '4-7-8 Technique',
      'subtitle': 'Dr. Andrew Weil',
      'manfaat': 'Mengatasi kecemasan, rasa panik, dan membantu tidur lebih cepat',
      'panduan': 'Tarik napas 4 detik → Tahan 7 detik → Hembuskan 8 detik. Ulangi 4 kali.',
      'rounds': 4,
    },
    'box': {
      'title': 'Box Breathing',
      'subtitle': 'Navy SEALs Technique',
      'manfaat': 'Meredakan stres seketika, menenangkan pikiran, meningkatkan fokus',
      'panduan': 'Tarik 4 detik → Tahan 4 detik → Hembuskan 4 detik → Tahan 4 detik. Ulangi 5 kali.',
      'rounds': 5,
    },
    'calm': {
      'title': 'Calm Breathing',
      'subtitle': 'Relaksasi Harian',
      'manfaat': 'Menenangkan pikiran, mengurangi stress harian',
      'panduan': 'Tarik napas 4 detik → Hembuskan 6 detik. Ulangi 6 kali.',
      'rounds': 6,
    },
    'wimhof': {
      'title': 'Wim Hof Method',
      'subtitle': 'Napas Energik',
      'manfaat': 'Meningkatkan energi tubuh, daya tahan fisik, dan imunitas',
      'panduan': '30 napas cepat ritmis → Tahan napas → Tarik dalam → Tahan 15 detik. Ulangi 3 kali.',
      'rounds': 3,
    },
  };

  final _techniques = {
    '478': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright, 'freq': 220.0, 'endFreq': 440.0, 'type': 'inhale'},
      {'name': 'Tahan', 'dur': 7, 'scale': 1.8, 'color': SomaTheme.softBlue, 'freq': 330.0, 'endFreq': 330.0, 'type': 'hold'},
      {'name': 'Hembuskan', 'dur': 8, 'scale': 1.0, 'color': SomaTheme.lavender, 'freq': 440.0, 'endFreq': 165.0, 'type': 'exhale'},
    ],
    'box': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright, 'freq': 220.0, 'endFreq': 440.0, 'type': 'inhale'},
      {'name': 'Tahan', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.softBlue, 'freq': 330.0, 'endFreq': 330.0, 'type': 'hold'},
      {'name': 'Hembuskan', 'dur': 4, 'scale': 1.0, 'color': SomaTheme.lavender, 'freq': 440.0, 'endFreq': 165.0, 'type': 'exhale'},
      {'name': 'Tahan', 'dur': 4, 'scale': 1.0, 'color': SomaTheme.softBlue, 'freq': 261.0, 'endFreq': 261.0, 'type': 'hold'},
    ],
    'calm': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright, 'freq': 220.0, 'endFreq': 440.0, 'type': 'inhale'},
      {'name': 'Hembuskan', 'dur': 6, 'scale': 1.0, 'color': SomaTheme.lavender, 'freq': 440.0, 'endFreq': 165.0, 'type': 'exhale'},
    ],
    'wimhof': [
      {'name': 'Napas Cepat', 'dur': 30, 'scale': 1.5, 'color': SomaTheme.tealBright, 'freq': 440.0, 'endFreq': 440.0, 'type': 'quick'},
      {'name': 'Tahan Napas', 'dur': 30, 'scale': 1.0, 'color': SomaTheme.softBlue, 'freq': 196.0, 'endFreq': 196.0, 'type': 'hold'},
      {'name': 'Tarik Dalam', 'dur': 15, 'scale': 1.8, 'color': SomaTheme.lavender, 'freq': 220.0, 'endFreq': 660.0, 'type': 'inhale'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer!.setVolume(0.3);
      _audioReady = true;
    } catch (_) {
      _audioReady = false;
    }
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _ambientTimer?.cancel();
    _audioPlayer?.dispose();
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
    _startAmbient();
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

    // Haptic feedback
    _hapticFeedback(phaseName);

    // Audio tone — natural sine wave sweep
    _playPhaseTone(
      phase['freq'] as double,
      phase['endFreq'] as double,
      (phase['dur'] as int),
      phase['type'] as String,
    );

    _runCountdown();
  }

  /// Generate natural sine wave audio tone with smooth frequency sweep.
  /// Inhale: rising tone (calming up-sweep)
  /// Exhale: falling tone (release down-sweep)
  /// Hold: steady tone (sustained note)
  /// Quick: rhythmic short tones
  void _playPhaseTone(double startFreq, double endFreq, int durationSec, String type) {
    _audioTimer?.cancel();
    if (!_audioReady || _audioPlayer == null) return;

    try {
      // Generate WAV tone for this phase
      final wavBytes = _generateSineSweep(startFreq, endFreq, durationSec.toDouble(), 44100);
      
      // Convert to base64 data URI for just_audio
      final b64 = _bytesToBase64(wavBytes);
      final dataUri = 'data:audio/wav;base64,$b64';
      
      _audioPlayer!.setUrl(dataUri).then((_) {
        _audioPlayer!.play();
      });

      // For quick breathing (Wim Hof), add rhythmic pulses
      if (type == 'quick') {
        int pulseCount = 0;
        _audioTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
          pulseCount++;
          if (pulseCount >= durationSec * 1.25) {
            t.cancel();
          } else {
            HapticFeedback.lightImpact();
          }
        });
      }
    } catch (_) {
      // Audio failed — fall back to system sound
      SystemSound.play(SystemSoundType.click);
    }
  }

  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Generate a smooth sine wave WAV with frequency sweep.
  /// Creates a natural, premium-sounding tone (like singing bowl / meditation bell).
  Uint8List _generateSineSweep(double startFreq, double endFreq, double durationSec, int sampleRate) {
    final int numSamples = (durationSec * sampleRate).toInt();
    final int dataSize = numSamples * 2; // 16-bit mono
    final int totalSize = 44 + dataSize;
    final ByteData data = ByteData(totalSize);

    // WAV header
    data.setUint8(0, 0x52); // R
    data.setUint8(1, 0x49); // I
    data.setUint8(2, 0x46); // F
    data.setUint8(3, 0x46); // F
    data.setUint32(4, totalSize - 8, Endian.little);
    data.setUint8(8, 0x57);  // W
    data.setUint8(9, 0x41);  // A
    data.setUint8(10, 0x56); // V
    data.setUint8(11, 0x45); // E
    data.setUint8(12, 0x66); // f
    data.setUint8(13, 0x6d); // m
    data.setUint8(14, 0x74); // t
    data.setUint8(15, 0x20); // space
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);   // PCM
    data.setUint16(22, 1, Endian.little);   // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    data.setUint8(36, 0x64); // d
    data.setUint8(37, 0x61); // a
    data.setUint8(38, 0x74); // t
    data.setUint8(39, 0x61); // a
    data.setUint32(40, dataSize, Endian.little);

    // Generate sine wave with smooth frequency transition
    const double twoPi = 2 * math.pi;
    double phase = 0.0;
    int offset = 44;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double progress = t / durationSec;
      
      // Smooth frequency interpolation (exponential for natural feel)
      final double currentFreq = startFreq * math.pow(endFreq / startFreq, progress);
      
      // Accumulate phase for continuous waveform
      phase += twoPi * currentFreq / sampleRate;
      
      // Amplitude envelope: fade in/out for natural sound
      double amplitude = 0.35;
      final double fadeIn = 0.1; // 10% fade in
      final double fadeOut = 0.15; // 15% fade out
      if (progress < fadeIn) {
        amplitude *= progress / fadeIn;
      } else if (progress > 1.0 - fadeOut) {
        amplitude *= (1.0 - progress) / fadeOut;
      }
      
      // Add slight harmonic for richer tone (like singing bowl)
      final double fundamental = math.sin(phase);
      final double harmonic = 0.15 * math.sin(phase * 2); // octave
      final double sampleValue = amplitude * (fundamental + harmonic);
      
      final int value = (32767 * sampleValue).toInt();
      data.setInt16(offset, value.clamp(-32768, 32767), Endian.little);
      offset += 2;
    }

    return data.buffer.asUint8List(0, totalSize);
  }

  /// Play soft ambient background tone during breathing session
  void _startAmbient() {
    // Low-frequency drone for ambient background (like meditation room)
    if (!_audioReady || _audioPlayer == null) return;
    // Ambient handled by phase tones — no separate ambient needed
  }

  void _hapticFeedback(String phaseName) {
    try {
      if (phaseName == 'Tarik Napas' || phaseName == 'Tarik Dalam') {
        HapticFeedback.lightImpact();
      } else if (phaseName == 'Tahan' || phaseName == 'Tahan Napas') {
        HapticFeedback.mediumImpact();
      } else if (phaseName == 'Hembuskan') {
        HapticFeedback.heavyImpact();
      } else if (phaseName == 'Napas Cepat') {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  void _vibrate(String phaseName) {
    try {
      if (phaseName == 'Tarik Napas' || phaseName == 'Tarik Dalam') {
        Vibration.vibrate(pattern: [100, 50, 200, 50, 400]);
      } else if (phaseName == 'Tahan' || phaseName == 'Tahan Napas') {
        Vibration.vibrate(pattern: [80, 100, 80]);
      } else if (phaseName == 'Hembuskan') {
        Vibration.vibrate(pattern: [300, 50, 200, 50, 100]);
      } else if (phaseName == 'Napas Cepat') {
        Vibration.vibrate(pattern: [50, 50, 50, 50, 50, 50]);
      }
    } catch (_) {}
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

  void _pause() {
    setState(() {
      _paused = !_paused;
    });
    if (!_paused) {
      _runCountdown();
    } else {
      _audioTimer?.cancel();
      _audioPlayer?.pause();
    }
  }

  void _stop() {
    _audioTimer?.cancel();
    _audioPlayer?.stop();
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
    final info = _techniqueInfo[_technique]!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Breathing Exercise',
            style: TextStyle(color: SomaTheme.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Latih pernapasan untuk menenangkan pikiran',
            style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [
            _buildTechButton('4-7-8', '478', 'Dr. Andrew Weil'),
            _buildTechButton('Box', 'box', 'Navy SEALs'),
            _buildTechButton('Calm', 'calm', 'Relaksasi Harian'),
            _buildTechButton('Wim Hof', 'wimhof', 'Napas Energik'),
          ],
        ),
        const SizedBox(height: 20),
        // Technique info
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
              Row(
                children: [
                  Icon(Icons.info_outline, color: SomaTheme.teal, size: 18),
                  const SizedBox(width: 8),
                  Text(info['title'] as String,
                      style: TextStyle(color: SomaTheme.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(info['subtitle'] as String,
                      style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manfaat: ', style: TextStyle(color: SomaTheme.tealBright, fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(child: Text(info['manfaat'] as String, style: TextStyle(color: SomaTheme.text, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panduan: ', style: TextStyle(color: SomaTheme.lavender, fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(child: Text(info['panduan'] as String, style: TextStyle(color: SomaTheme.textMuted, fontSize: 12))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Breathing circle
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: 200 * _circleScale,
            height: 200 * _circleScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_circleColor.withOpacity(0.3), SomaTheme.bgCard]),
              border: Border.all(color: _circleColor, width: 3),
              boxShadow: [BoxShadow(color: _circleColor.withOpacity(0.4), blurRadius: 30)],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_running)
                    Text(_phaseName, style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w600))
                  else
                    Text('Tekan Start', style: TextStyle(color: SomaTheme.textMuted, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_running)
                    Text('$_secondsLeft', style: TextStyle(color: _circleColor, fontSize: 48, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Siklus: $_cycles / ${info['rounds']}',
            style: TextStyle(color: SomaTheme.textMuted, fontSize: 14), textAlign: TextAlign.center),
        if (_cycles >= (info['rounds'] as int))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Alhamdulillah! Anda merasa lebih tenang? 🌿',
                style: TextStyle(color: SomaTheme.tealBright, fontSize: 14), textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_running)
              ElevatedButton.icon(onPressed: _startBreathing, icon: const Icon(Icons.play_arrow), label: const Text('Start'))
            else ...[
              ElevatedButton.icon(onPressed: _pause, icon: Icon(_paused ? Icons.play_arrow : Icons.pause), label: Text(_paused ? 'Resume' : 'Pause')),
              const SizedBox(width: 12),
              OutlinedButton.icon(onPressed: _stop, icon: const Icon(Icons.stop), label: const Text('Stop')),
            ],
          ],
        ),
        const SizedBox(height: 24),
        // Audio status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_audioReady ? Icons.graphic_eq : Icons.volume_off,
                  color: _audioReady ? SomaTheme.teal : SomaTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                _audioReady ? 'Premium Audio: Sine wave sweep + Harmonics (singing bowl effect)' : 'Audio: Menggunakan vibration + haptic',
                style: TextStyle(color: SomaTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechButton(String label, String tech, String subtitle) {
    final active = _technique == tech;
    return GestureDetector(
      onTap: () {
        if (!_running) setState(() => _technique = tech);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? SomaTheme.teal.withOpacity(0.15) : SomaTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? SomaTheme.teal : SomaTheme.teal.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: active ? SomaTheme.tealBright : SomaTheme.text, fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: SomaTheme.textMuted, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}