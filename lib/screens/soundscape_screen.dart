import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/soma_theme.dart';

/// SOUNDSCAPE GENERATOR
/// Ambient sound mixer with 6 nature sounds, presets, timer, and saved mixes.
/// Each sound is synthesized as a looping WAV (white/brown noise or sine waves)
/// played by a dedicated [AudioPlayer] so sounds can be mixed simultaneously.
class SoundscapeScreen extends StatefulWidget {
  const SoundscapeScreen({super.key});

  @override
  State<SoundscapeScreen> createState() => _SoundscapeScreenState();
}

class _SoundscapeScreenState extends State<SoundscapeScreen> {
  // Sound keys + display metadata
  static const _soundKeys = ['rain', 'ocean', 'wind', 'fire', 'birds', 'bowl'];
  static const _soundLabels = {
    'rain': '🌧️ Hujan',
    'ocean': '🌊 Ombak',
    'wind': '🌲 Angin',
    'fire': '🔥 Api Unggun',
    'birds': '🐦 Burung',
    'bowl': '🎵 Singing Bowl',
  };
  static const _soundColors = {
    'rain': SomaTheme.softBlue,
    'ocean': SomaTheme.teal,
    'wind': SomaTheme.lavender,
    'fire': SomaTheme.purple,
    'birds': SomaTheme.tealBright,
    'bowl': SomaTheme.lavender,
  };

  // Per-sound state
  final Map<String, bool> _enabled = {for (final k in _soundKeys) k: false};
  final Map<String, double> _volume = {for (final k in _soundKeys) k: 0.5};
  final Map<String, AudioPlayer> _players = {};

  // Timer
  int _timerMinutes = 0; // 0 = tanpa batas
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _timerRunning = false;

  // Saved mixes
  final List<Map<String, dynamic>> _savedMixes = [];
  static const _storageKey = 'soma_soundscapes';

  // UI
  final _mixNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPlayers();
    _loadSavedMixes();
  }

  Future<void> _initPlayers() async {
    for (final k in _soundKeys) {
      final p = AudioPlayer();
      try {
        final wav = _generateSound(k);
        final b64 = base64Encode(wav);
        await p.setUrl('data:audio/wav;base64,$b64');
        await p.setLoopMode(LoopMode.one);
        await p.setVolume(0.0);
        _players[k] = p;
      } catch (_) {
        // ignore — sound disabled
      }
    }
  }

  Future<void> _loadSavedMixes() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_storageKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        setState(() {
          _savedMixes
              .clear(); // safe before adding — clear then add the decoded entries
          for (final e in list) {
            _savedMixes.add(Map<String, dynamic>.from(e as Map));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _persistMixes() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_storageKey, jsonEncode(_savedMixes));
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final p in _players.values) {
      p.dispose();
    }
    _mixNameCtrl.dispose();
    super.dispose();
  }

  // ============ Audio synthesis ============

  /// Generate a looping WAV for the given sound key.
  /// - rain:  high-frequency filtered white noise
  /// - ocean: low-frequency sine with slow LFO (0.5-1 Hz swell)
  /// - wind:  mid-frequency filtered noise
  /// - fire:  brown noise with random crackle spikes
  /// - birds: random short tones 2000-4000 Hz
  /// - bowl:  steady 440 Hz sine + harmonics
  Uint8List _generateSound(String key) {
    const int sampleRate = 22050;
    const double durationSec = 4.0;
    final int numSamples = (durationSec * sampleRate).toInt();
    final int dataSize = numSamples * 2;
    final int totalSize = 44 + dataSize;
    final ByteData data = ByteData(totalSize);

    // WAV header (standard PCM 16-bit mono)
    _writeWavHeader(data, totalSize, dataSize, sampleRate);

    final rng = math.Random(42); // deterministic for loop seam
    int offset = 44;
    double brown = 0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sample = 0;

      switch (key) {
        case 'rain':
          // High-frequency white noise (high-pass-ish via differentiated noise)
          final white = rng.nextDouble() * 2 - 1;
          sample = white * 0.5;
          break;
        case 'ocean':
          // Low sine swell with slow LFO amplitude
          final lfo = 0.5 + 0.5 * math.sin(2 * math.pi * 0.25 * t);
          sample = 0.4 * lfo * math.sin(2 * math.pi * 80 * t);
          break;
        case 'wind':
          // Mid-frequency filtered noise (sum of low-amplitude noise + band-ish)
          final white = rng.nextDouble() * 2 - 1;
          brown = (brown + 0.02 * white).clamp(-1.0, 1.0);
          final tone = 0.2 * math.sin(2 * math.pi * 220 * t);
          sample = 0.4 * brown + tone;
          break;
        case 'fire':
          // Brown noise + random crackle pops
          final white = rng.nextDouble() * 2 - 1;
          brown = (brown + 0.02 * white).clamp(-1.0, 1.0);
          sample = 0.35 * brown;
          if (rng.nextDouble() < 0.005) {
            sample += 0.6 * (rng.nextDouble() * 2 - 1);
          }
          break;
        case 'birds':
          // Random short chirp tones 2000-4000 Hz with gap
          final chirpPhase = (t * 0.5) % 1.0; // chirp every 2s
          if (chirpPhase < 0.2) {
            final freq = 2000 + 2000 * math.sin(2 * math.pi * 5 * t);
            sample = 0.35 * math.sin(2 * math.pi * freq * t) *
                (0.5 + 0.5 * math.sin(2 * math.pi * 12 * t));
          } else {
            sample = 0.0;
          }
          break;
        case 'bowl':
          // Steady 440 Hz sine + harmonics (octave + fifth)
          sample = 0.3 * math.sin(2 * math.pi * 440 * t) +
              0.1 * math.sin(2 * math.pi * 880 * t) +
              0.05 * math.sin(2 * math.pi * 660 * t);
          break;
      }

      // Fade edges for seamless loop
      final double fade = 0.05;
      final double progress = i / numSamples;
      double amp = 1.0;
      if (progress < fade) {
        amp = progress / fade;
      } else if (progress > 1.0 - fade) {
        amp = (1.0 - progress) / fade;
      }

      final int value = (32767 * sample * amp).toInt().clamp(-32768, 32767);
      data.setInt16(offset, value, Endian.little);
      offset += 2;
    }

    return data.buffer.asUint8List(0, totalSize);
  }

  void _writeWavHeader(
      ByteData data, int totalSize, int dataSize, int sampleRate) {
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
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    data.setUint8(36, 0x64); // d
    data.setUint8(37, 0x61); // a
    data.setUint8(38, 0x74); // t
    data.setUint8(39, 0x61); // a
    data.setUint32(40, dataSize, Endian.little);
  }

  // ============ Sound control ============

  void _toggleSound(String key) {
    final player = _players[key];
    if (player == null) return;
    setState(() {
      final next = !(_enabled[key] ?? false);
      _enabled[key] = next;
      if (next) {
        player.setVolume(_volume[key] ?? 0.5);
        player.play();
      } else {
        player.setVolume(0.0);
        player.pause();
      }
    });
  }

  void _setVolume(String key, double v) {
    setState(() {
      _volume[key] = v;
      if (_enabled[key] == true) {
        _players[key]?.setVolume(v);
      }
    });
  }

  void _stopAll() {
    for (final k in _soundKeys) {
      _players[k]?.pause();
    }
    setState(() {
      for (final k in _soundKeys) {
        _enabled[k] = false;
      }
    });
    _cancelTimer();
  }

  // ============ Presets ============

  void _applyPreset(String name) {
    // Define preset volumes (0.0-1.0). Off sounds get 0 + disabled.
    final Map<String, Map<String, double>> presets = {
      'Deep Sleep': {'rain': 0.6, 'bowl': 0.3},
      'Focus Flow': {'wind': 0.4, 'birds': 0.2},
      'Calm Morning': {'birds': 0.5, 'ocean': 0.3},
      'Stress Relief': {'bowl': 0.5, 'rain': 0.4},
    };
    final active = presets[name] ?? {};
    setState(() {
      for (final k in _soundKeys) {
        if (active.containsKey(k)) {
          _enabled[k] = true;
          _volume[k] = active[k]!;
          _players[k]?.setVolume(active[k]!);
          _players[k]?.play();
        } else {
          _enabled[k] = false;
          _volume[k] = 0.0;
          _players[k]?.setVolume(0.0);
          _players[k]?.pause();
        }
      }
    });
  }

  // ============ Timer ============

  void _startTimer(int minutes) {
    _cancelTimer();
    setState(() {
      _timerMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _timerRunning = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      // Auto-fade last 5 minutes (300s)
      if (_remainingSeconds <= 300 && _remainingSeconds > 0) {
        final fadeRatio = _remainingSeconds / 300.0;
        for (final k in _soundKeys) {
          if (_enabled[k] == true) {
            _players[k]?.setVolume(_volume[k]! * fadeRatio);
          }
        }
      }
      if (_remainingSeconds <= 0) {
        t.cancel();
        _stopAll();
        setState(() {
          _timerRunning = false;
        });
      }
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (mounted) {
      setState(() {
        _timerRunning = false;
        _remainingSeconds = 0;
      });
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ============ Save / Load Mix ============

  void _saveMix() {
    if (_mixNameCtrl.text.trim().isEmpty) return;
    final active = <String, double>{};
    for (final k in _soundKeys) {
      if (_enabled[k] == true) active[k] = _volume[k]!;
    }
    if (active.isEmpty) return;
    setState(() {
      if (_savedMixes.length >= 5) {
        _savedMixes.removeAt(0); // cap at 5
      }
      _savedMixes.add({
        'name': _mixNameCtrl.text.trim(),
        'volumes': active,
      });
      _mixNameCtrl.clear();
    });
    _persistMixes();
  }

  void _loadMix(Map<String, dynamic> mix) {
    final volumes = Map<String, double>.from(
      (mix['volumes'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
    setState(() {
      for (final k in _soundKeys) {
        if (volumes.containsKey(k)) {
          _enabled[k] = true;
          _volume[k] = volumes[k]!;
          _players[k]?.setVolume(volumes[k]!);
          _players[k]?.play();
        } else {
          _enabled[k] = false;
          _players[k]?.setVolume(0.0);
          _players[k]?.pause();
        }
      }
    });
  }

  void _deleteMix(int idx) {
    setState(() => _savedMixes.removeAt(idx));
    _persistMixes();
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Soundscape Generator',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Sound Mixer', Icons.graphic_eq),
          ..._soundKeys.map(_buildSoundRow),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _stopAll,
                icon: const Icon(Icons.stop),
                label: const Text('Stop All'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle('Presets', Icons.auto_awesome),
          _buildPresets(),
          const SizedBox(height: 24),
          _sectionTitle('Timer', Icons.timer),
          _buildTimer(),
          const SizedBox(height: 24),
          _sectionTitle('Save Mix', Icons.save),
          _buildSaveMix(),
          const SizedBox(height: 24),
          if (_savedMixes.isNotEmpty) ...[
            _sectionTitle('Saved Mixes', Icons.library_music),
            ..._savedMixes.asMap().entries.map((e) => _buildSavedMixCard(e.key, e.value)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSoundRow(String key) {
    final enabled = _enabled[key]!;
    final color = _soundColors[key]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: enabled ? color.withOpacity(0.6) : SomaTheme.teal.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Switch(
            value: enabled,
            activeColor: color,
            onChanged: (_) => _toggleSound(key),
          ),
          const SizedBox(width: 4),
          Text(_soundLabels[key]!,
              style: TextStyle(
                  color: enabled ? SomaTheme.white : SomaTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: _volume[key]!,
              min: 0.0,
              max: 1.0,
              activeColor: color,
              onChanged: enabled ? (v) => _setVolume(key, v) : null,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text('${(_volume[key]! * 100).round()}%',
                style: TextStyle(color: SomaTheme.textMuted, fontSize: 11),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    final presets = ['Deep Sleep', 'Focus Flow', 'Calm Morning', 'Stress Relief'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: presets.map((name) {
        return ActionChip(
          label: Text(name),
          backgroundColor: SomaTheme.bgCard,
          side: BorderSide(color: SomaTheme.lavender.withOpacity(0.4)),
          labelStyle: TextStyle(color: SomaTheme.lavender, fontWeight: FontWeight.w600),
          onPressed: () => _applyPreset(name),
        );
      }).toList(),
    );
  }

  Widget _buildTimer() {
    final durations = [15, 30, 45, 60];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_timerRunning)
            Center(
              child: Text(
                _formatDuration(_remainingSeconds),
                style: TextStyle(
                    color: SomaTheme.tealBright,
                    fontSize: 32,
                    fontWeight: FontWeight.w800),
              ),
            ),
          if (_timerRunning) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...durations.map((m) => ChoiceChip(
                    label: Text('$m min'),
                    selected: _timerMinutes == m,
                    selectedColor: SomaTheme.teal,
                    labelStyle: TextStyle(
                        color: _timerMinutes == m
                            ? SomaTheme.white
                            : SomaTheme.textMuted),
                    onSelected: (_) => _startTimer(m),
                  )),
              ChoiceChip(
                label: const Text('Tanpa batas'),
                selected: _timerMinutes == 0 && !_timerRunning,
                selectedColor: SomaTheme.teal,
                labelStyle: TextStyle(
                    color: _timerMinutes == 0 && !_timerRunning
                        ? SomaTheme.white
                        : SomaTheme.textMuted),
                onSelected: (_) => _cancelTimer(),
              ),
            ],
          ),
          if (_timerRunning) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: _cancelTimer,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Timer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveMix() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _mixNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Mix',
              hintText: 'contoh: Malam Tenang',
            ),
            style: const TextStyle(color: SomaTheme.text),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saveMix,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Mix'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMixCard(int idx, Map<String, dynamic> mix) {
    final name = mix['name'] as String;
    final volumes = Map<String, double>.from(
      (mix['volumes'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SomaTheme.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: SomaTheme.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  volumes.entries
                      .map((e) => '${_soundLabels[e.key]} ${(e.value * 100).round()}%')
                      .join(' + '),
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: SomaTheme.tealBright),
            onPressed: () => _loadMix(mix),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteMix(idx),
          ),
        ],
      ),
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