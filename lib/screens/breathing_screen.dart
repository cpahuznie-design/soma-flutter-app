import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  Timer? _audioSweepTimer;
  FlutterTts? _tts;
  bool _ttsReady = false;

  // Technique info (manfaat, deskripsi, panduan)
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
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright, 'voice': 'Tarik napas dalam lewat hidung'},
      {'name': 'Tahan', 'dur': 7, 'scale': 1.8, 'color': SomaTheme.softBlue, 'voice': 'Tahan napas Anda'},
      {'name': 'Hembuskan', 'dur': 8, 'scale': 1.0, 'color': SomaTheme.lavender, 'voice': 'Buang napas sepenuhnya lewat mulut dengan suara whoosh'},
    ],
    'box': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright, 'voice': 'Tarik napas perlahan lewat hidung'},
      {'name': 'Tahan', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.softBlue, 'voice': 'Tahan napas Anda'},
      {'name': 'Hembuskan', 'dur': 4, 'scale': 1.0, 'color': SomaTheme.lavender, 'voice': 'Hembuskan perlahan lewat mulut'},
      {'name': 'Tahan', 'dur': 4, 'scale': 1.0, 'color': SomaTheme.softBlue, 'voice': 'Tahan dalam kondisi kosong'},
    ],
    'calm': [
      {'name': 'Tarik Napas', 'dur': 4, 'scale': 1.8, 'color': SomaTheme.tealBright, 'voice': 'Tarik napas perlahan'},
      {'name': 'Hembuskan', 'dur': 6, 'scale': 1.0, 'color': SomaTheme.lavender, 'voice': 'Hembuskan santai'},
    ],
    'wimhof': [
      {'name': 'Napas Cepat', 'dur': 30, 'scale': 1.5, 'color': SomaTheme.tealBright, 'voice': 'Tarik napas dalam ke dada dan perut, lalu lepaskan santai. Ulangi cepat dan ritmis'},
      {'name': 'Tahan Napas', 'dur': 30, 'scale': 1.0, 'color': SomaTheme.softBlue, 'voice': 'Buang napas setengah, lalu tahan napas selama mungkin'},
      {'name': 'Tarik Dalam', 'dur': 15, 'scale': 1.8, 'color': SomaTheme.lavender, 'voice': 'Tarik napas dalam penuh, tahan lima belas detik, lalu lepaskan'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      await _tts!.setLanguage('id-ID');
      await _tts!.setSpeechRate(0.4);
      await _tts!.setVolume(0.8);
      await _tts!.setPitch(1.0);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  @override
  void dispose() {
    _audioSweepTimer?.cancel();
    _tts?.stop();
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
    final voiceText = phase['voice'] as String;

    setState(() {
      _secondsLeft = (phase['dur'] as int);
      _phaseName = phaseName;
      _circleScale = (phase['scale'] as double);
      _circleColor = phase['color'] as Color;
    });

    // Vibration per phase
    _vibrate(phaseName);

    // TTS voice guidance
    _speak(voiceText);

    // System sound click
    _playClick();

    _runCountdown();
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady || _tts == null) return;
    try {
      await _tts!.stop();
      await _tts!.speak(text);
    } catch (_) {}
  }

  void _playClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
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

  void _vibrate(String phaseName) {
    try {
      if (phaseName == 'Tarik Napas' || phaseName == 'Tarik Dalam') {
        Vibration.vibrate(pattern: [100, 50, 200, 50, 400]);
      } else if (phaseName == 'Tahan' || phaseName == 'Tahan Napas') {
        Vibration.vibrate(pattern: [80, 100, 80]);
      } else if (phaseName == 'Hembuskan') {
        Vibration.vibrate(pattern: [300, 50, 200, 50, 100]);
      } else if (phaseName == 'Napas Cepat') {
        Vibration.vibrate(pattern: [50, 50, 50, 50, 50, 50, 50, 50]);
      }
    } catch (_) {}
  }

  void _pause() {
    setState(() {
      _paused = !_paused;
    });
    if (!_paused) {
      _runCountdown();
    } else {
      _audioSweepTimer?.cancel();
      _tts?.stop();
    }
  }

  void _stop() {
    _audioSweepTimer?.cancel();
    _tts?.stop();
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
        // Title
        Text('Breathing Exercise',
            style: TextStyle(
                color: SomaTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Latih pernapasan untuk menenangkan pikiran',
            style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 24),

        // Technique selector (4 buttons)
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

        // Technique info card
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
        const SizedBox(height: 20),

        // Cycles
        Text('Siklus: $_cycles / ${info['rounds']}',
            style: TextStyle(color: SomaTheme.textMuted, fontSize: 14),
            textAlign: TextAlign.center),
        if (_cycles >= (info['rounds'] as int))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Alhamdulillah! Anda merasa lebih tenang? 🌿',
                style: TextStyle(color: SomaTheme.tealBright, fontSize: 14),
                textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),

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
        const SizedBox(height: 24),

        // Audio status indicator
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
              Icon(_ttsReady ? Icons.volume_up : Icons.volume_off,
                  color: _ttsReady ? SomaTheme.teal : SomaTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                _ttsReady ? 'Audio Pemandu: Aktif (TTS)' : 'Audio Pemandu: Tidak tersedia',
                style: TextStyle(color: SomaTheme.textMuted, fontSize: 12),
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
          border: Border.all(
              color: active ? SomaTheme.teal : SomaTheme.teal.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    color: active ? SomaTheme.tealBright : SomaTheme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: SomaTheme.textMuted, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}