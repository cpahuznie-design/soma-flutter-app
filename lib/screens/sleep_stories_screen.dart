import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/soma_theme.dart';

/// Sleep Stories screen.
///
/// 10 cerita pengantar tidur dengan kategori, player mini, favorites,
/// sleep timer dengan auto-fade, dan indikator PREMIUM (lock).
class SleepStoriesScreen extends StatefulWidget {
  const SleepStoriesScreen({super.key});

  @override
  State<SleepStoriesScreen> createState() => _SleepStoriesScreenState();
}

class _SleepStoriesScreenState extends State<SleepStoriesScreen> {
  // --- Story data ------------------------------------------------------
  final List<SleepStory> _allStories = const [
    SleepStory(
      id: 's1',
      title: 'Hutan Tenang di Malam Hari',
      duration: 15,
      category: 'Alam',
      sound: 'Suara alam hutan — jangkrik, daun, burung malam',
      icon: Icons.forest,
      color: SomaTheme.teal,
      isPremium: false,
    ),
    SleepStory(
      id: 's2',
      title: 'Ombak Pantai Selatan',
      duration: 20,
      category: 'Alam',
      sound: 'Suara ombak berirutas — deburan lembut ke pasir',
      icon: Icons.waves,
      color: SomaTheme.softBlue,
      isPremium: false,
    ),
    SleepStory(
      id: 's3',
      title: 'Hujan di Pegunungan',
      duration: 12,
      category: 'Alam',
      sound: 'Suara hujan rintik-rintik di atap kayu',
      icon: Icons.cloudy_snowing,
      color: SomaTheme.lavender,
      isPremium: false,
    ),
    SleepStory(
      id: 's4',
      title: 'Malam di Padang Rumput',
      duration: 18,
      category: 'Alam',
      sound: 'Suara angin membentang padang rumput luas',
      icon: Icons.grass,
      color: SomaTheme.tealBright,
      isPremium: true,
    ),
    SleepStory(
      id: 's5',
      title: 'Sungai Mengalir di Lembah',
      duration: 15,
      category: 'Relaksasi',
      sound: 'Suara air mengalir tenang di batu sungai',
      icon: Icons.water,
      color: SomaTheme.purple,
      isPremium: true,
    ),
    SleepStory(
      id: 's6',
      title: 'Bintang di Gurun',
      duration: 22,
      category: 'Relaksasi',
      sound: 'Suara malam gurun — keheningan luas, angin samar',
      icon: Icons.nights_stay,
      color: SomaTheme.lavender,
      isPremium: true,
    ),
    SleepStory(
      id: 's7',
      title: 'Kabut Pagi di Sawah',
      duration: 14,
      category: 'Alam',
      sound: 'Suara burung pagi dan embun di sawah',
      icon: Icons.spa,
      color: SomaTheme.teal,
      isPremium: true,
    ),
    SleepStory(
      id: 's8',
      title: 'Api Ungu di Hutan Pinus',
      duration: 16,
      category: 'Relaksasi',
      sound: 'Suara api unggun — kayu terbakar, retak lembut',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      isPremium: true,
    ),
    SleepStory(
      id: 's9',
      title: 'Perjalanan Kereta Malam',
      duration: 20,
      category: 'Kota',
      sound: 'Suara kereta malam — ritmis, rel, mesin tenang',
      icon: Icons.train,
      color: SomaTheme.softBlue,
      isPremium: true,
    ),
    SleepStory(
      id: 's10',
      title: 'Taman Bunga di Angin',
      duration: 13,
      category: 'Relaksasi',
      sound: 'Suara angin lembut di taman bunga',
      icon: Icons.local_florist,
      color: SomaTheme.tealBright,
      isPremium: true,
    ),
  ];

  final List<String> _tabs = ['Semua', 'Alam', 'Kota', 'Relaksasi', 'Favorit'];
  int _activeTab = 0;

  // --- Favorites -------------------------------------------------------
  final Set<String> _favorites = {};
  static const String _favKey = 'soma_sleep_stories_fav';

  // --- Player state ----------------------------------------------------
  AudioPlayer? _player;
  SleepStory? _currentStory;
  bool _isPlaying = false;
  double _progress = 0.0;
  int _playerSeconds = 0;
  double _volume = 0.5;
  Timer? _progressTimer;

  // --- Sleep timer -----------------------------------------------------
  int? _sleepTimerMinutes; // 15 | 30 | 45 | 60 | null
  int _sleepTimerRemaining = 0; // seconds
  Timer? _sleepTimer;
  Timer? _fadeTimer;

  // --- Lifecycle ------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initPlayer();
    _loadFavorites();
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();
    try {
      await _player!.setVolume(_volume);
      await _player!.setLoopMode(LoopMode.one);
    } catch (_) {
      _player = null;
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        setState(() {
          _favorites.addAll(list.map((e) => e.toString()));
        });
      } catch (_) {}
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favKey, jsonEncode(_favorites.toList()));
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    _saveFavorites();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  // --- Filter ----------------------------------------------------------
  List<SleepStory> get _filteredStories {
    final tabName = _tabs[_activeTab];
    if (tabName == 'Semua') return _allStories;
    if (tabName == 'Favorit') {
      return _allStories.where((s) => _favorites.contains(s.id)).toList();
    }
    return _allStories.where((s) => s.category == tabName).toList();
  }

  // --- Player actions --------------------------------------------------
  Future<void> _playStory(SleepStory story) async {
    if (story.isPremium) {
      // Show premium prompt — no playback
      _showPremiumPrompt();
      return;
    }

    // Stop current if switching
    if (_currentStory?.id != story.id) {
      await _player?.stop();
      _progressTimer?.cancel();
      setState(() {
        _currentStory = story;
        _progress = 0.0;
        _playerSeconds = 0;
        _isPlaying = false;
      });
    }

    // Generate ambient low-frequency sine wave loop
    await _loadAmbientTone(story);

    setState(() => _isPlaying = true);
    try {
      await _player!.play();
      _startProgressTimer();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _loadAmbientTone(SleepStory story) async {
    if (_player == null) return;
    try {
      // Map each story to a different ambient low-frequency tone
      final freq = _frequencyForStory(story);
      final wav = _generateAmbientWav(freq, 30.0); // 30s loop
      final b64 = base64Encode(wav);
      final dataUri = 'data:audio/wav;base64,$b64';
      await _player!.setUrl(dataUri);
      await _player!.setVolume(_volume);
      await _player!.setLoopMode(LoopMode.one);
    } catch (_) {
      // Silent fail
    }
  }

  double _frequencyForStory(SleepStory s) {
    // Low-frequency ambient tones (80–160 Hz range)
    switch (s.id) {
      case 's1':
        return 110.0; // hutan — A2
      case 's2':
        return 130.0; // ombak — C3
      case 's3':
        return 98.0; // hujan — G2
      default:
        return 120.0;
    }
  }

  /// Generate a 30-second ambient sine wave loop WAV with gentle fade in/out.
  Uint8List _generateAmbientWav(double freq, double durationSec) {
    final sampleRate = 44100;
    final numSamples = (durationSec * sampleRate).toInt();
    final dataSize = numSamples * 2;
    final totalSize = 44 + dataSize;
    final ByteData data = ByteData(totalSize);

    // WAV header
    data.setUint8(0, 0x52); data.setUint8(1, 0x49);
    data.setUint8(2, 0x46); data.setUint8(3, 0x46);
    data.setUint32(4, totalSize - 8, Endian.little);
    data.setUint8(8, 0x57); data.setUint8(9, 0x41);
    data.setUint8(10, 0x56); data.setUint8(11, 0x45);
    data.setUint8(12, 0x66); data.setUint8(13, 0x6d);
    data.setUint8(14, 0x74); data.setUint8(15, 0x20);
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    data.setUint8(36, 0x64); data.setUint8(37, 0x61);
    data.setUint8(38, 0x74); data.setUint8(39, 0x61);
    data.setUint32(40, dataSize, Endian.little);

    const twoPi = 2 * math.pi;
    double phase = 0.0;
    int offset = 44;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final progress = t / durationSec;

      // Accumulate phase for continuous waveform
      phase += twoPi * freq / sampleRate;

      // Amplitude envelope: fade in 5%, fade out 5%, gentle LFO wobble
      double amp = 0.25;
      const fadePct = 0.05;
      if (progress < fadePct) {
        amp *= progress / fadePct;
      } else if (progress > 1 - fadePct) {
        amp *= (1 - progress) / fadePct;
      }
      // Subtle vibrato for organic feel
      final lfo = 0.85 + 0.15 * math.sin(2 * math.pi * 0.1 * t);
      amp *= lfo;

      // Fundamental + sub-harmonic for richer texture
      final fundamental = math.sin(phase);
      final sub = 0.3 * math.sin(phase * 0.5);
      final sampleValue = amp * (fundamental + sub);

      final value = (32767 * sampleValue).toInt().clamp(-32768, 32767);
      data.setInt16(offset, value, Endian.little);
      offset += 2;
    }

    return data.buffer.asUint8List(0, totalSize);
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _playerSeconds += 1;
        final total = (_currentStory?.duration ?? 1) * 60;
        _progress = (_playerSeconds / total).clamp(0.0, 1.0);
      });
      // Auto-stop when story duration ends
      if (_currentStory != null && _playerSeconds >= _currentStory!.duration * 60) {
        _stopPlayback();
      }
    });
  }

  Future<void> _togglePlayPause() async {
    if (_currentStory == null || _player == null) return;
    if (_isPlaying) {
      await _player!.pause();
      _progressTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      await _player!.play();
      _startProgressTimer();
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _stopPlayback() async {
    await _player?.stop();
    _progressTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _progress = 0.0;
      _playerSeconds = 0;
      _currentStory = null;
    });
  }

  Future<void> _setVolume(double v) async {
    setState(() => _volume = v);
    try {
      await _player?.setVolume(v);
    } catch (_) {}
  }

  // --- Sleep Timer -----------------------------------------------------
  void _startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    setState(() {
      _sleepTimerMinutes = minutes;
      _sleepTimerRemaining = minutes * 60;
    });

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _sleepTimerRemaining -= 1);

      // Start fade in last 5 minutes
      final fadeStart = 5 * 60;
      if (_sleepTimerRemaining <= fadeStart && _sleepTimerRemaining > 0) {
        final fadeRatio = _sleepTimerRemaining / fadeStart;
        final targetVol = _volume * fadeRatio;
        _player?.setVolume(targetVol.clamp(0.0, 1.0));
      }

      if (_sleepTimerRemaining <= 0) {
        t.cancel();
        _stopPlayback();
        setState(() {
          _sleepTimerMinutes = null;
          _sleepTimerRemaining = 0;
        });
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    // Restore full volume
    _player?.setVolume(_volume);
    setState(() {
      _sleepTimerMinutes = null;
      _sleepTimerRemaining = 0;
    });
  }

  // --- Premium prompt --------------------------------------------------
  void _showPremiumPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SomaTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SomaTheme.purple.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock, color: SomaTheme.purple, size: 40),
            ),
            const SizedBox(height: 18),
            Text('Cerita Premium',
                style: TextStyle(
                    color: SomaTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Upgrade ke Premium untuk buka semua cerita pengantar tidur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SomaTheme.textMuted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SomaTheme.purple,
                  foregroundColor: SomaTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Upgrade ke Premium'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Nanti saja',
                  style: TextStyle(color: SomaTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Build -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Sleep Stories'),
        backgroundColor: SomaTheme.bgDeep,
        foregroundColor: SomaTheme.text,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _filteredStories.length,
              itemBuilder: (ctx, i) => _storyCard(_filteredStories[i]),
            ),
          ),
          if (_currentStory != null) _buildMiniPlayer(),
        ],
      ),
    );
  }

  // --- Tabs ------------------------------------------------------------
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final active = _activeTab == i;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? SomaTheme.teal : SomaTheme.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active
                          ? SomaTheme.tealBright
                          : SomaTheme.teal.withOpacity(0.3)),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    color: active ? SomaTheme.white : SomaTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- Story card ------------------------------------------------------
  Widget _storyCard(SleepStory story) {
    final isFav = _favorites.contains(story.id);
    final isActive = _currentStory?.id == story.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? SomaTheme.tealBright
              : SomaTheme.teal.withOpacity(0.2),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail / icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: story.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Center(
                    child: Icon(story.icon, color: story.color, size: 28)),
                if (story.isPremium)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: SomaTheme.bgCard,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock,
                          color: SomaTheme.purple, size: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(story.title,
                    style: TextStyle(
                        color: SomaTheme.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(story.sound,
                    style: TextStyle(
                        color: SomaTheme.textMuted, fontSize: 12, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        color: SomaTheme.tealBright, size: 14),
                    const SizedBox(width: 4),
                    Text('${story.duration} min',
                        style: TextStyle(
                            color: SomaTheme.tealBright,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: story.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(story.category,
                          style: TextStyle(
                              color: story.color, fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () => _toggleFavorite(story.id),
                icon: Icon(
                  isFav ? Icons.bookmark : Icons.bookmark_border,
                  color: isFav ? SomaTheme.lavender : SomaTheme.textMuted,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () => _playStory(story),
                icon: Icon(
                  isActive && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: SomaTheme.tealBright,
                  size: 30,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Mini Player -----------------------------------------------------
  Widget _buildMiniPlayer() {
    final story = _currentStory!;
    final totalSec = story.duration * 60;
    final elapsedMin = _playerSeconds ~/ 60;
    final elapsedSec = _playerSeconds % 60;
    // remaining time used implicitly via _progress; keep totalSec for elapsed display
    assert(totalSec > 0);

    return Container(
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        border: Border(
            top: BorderSide(color: SomaTheme.teal.withOpacity(0.4), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(story.icon, color: story.color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(story.title,
                        style: TextStyle(
                            color: SomaTheme.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${elapsedMin.toString().padLeft(2, '0')}:${elapsedSec.toString().padLeft(2, '0')} / ${story.duration}:00',
                      style:
                          TextStyle(color: SomaTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Play/Pause
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: SomaTheme.tealBright,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              // Stop
              IconButton(
                onPressed: _stopPlayback,
                icon: Icon(Icons.stop, color: SomaTheme.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 4,
              backgroundColor: SomaTheme.bgDeep,
              valueColor: AlwaysStoppedAnimation(story.color),
            ),
          ),
          const SizedBox(height: 10),
          // Volume slider
          Row(
            children: [
              Icon(Icons.volume_down, color: SomaTheme.textMuted, size: 18),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: _setVolume,
                  activeColor: SomaTheme.teal,
                  thumbColor: SomaTheme.tealBright,
                ),
              ),
              Icon(Icons.volume_up, color: SomaTheme.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          // Sleep timer row
          Row(
            children: [
              Icon(Icons.bedtime, color: SomaTheme.lavender, size: 18),
              const SizedBox(width: 6),
              if (_sleepTimerMinutes == null) ...[
                Text('Sleep timer:',
                    style: TextStyle(
                        color: SomaTheme.textMuted, fontSize: 12)),
                const SizedBox(width: 8),
                ...[15, 30, 45, 60].map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _startSleepTimer(m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SomaTheme.bgDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: SomaTheme.lavender.withOpacity(0.3)),
                        ),
                        child: Text('$m m',
                            style: TextStyle(
                                color: SomaTheme.lavender, fontSize: 11)),
                      ),
                    ),
                  );
                }),
              ] else ...[
                Expanded(
                  child: Text(
                    'Sleep timer: ${_sleepTimerRemaining ~/ 60}:${(_sleepTimerRemaining % 60).toString().padLeft(2, '0')} tersisa',
                    style: TextStyle(
                        color: SomaTheme.lavender,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _cancelSleepTimer,
                  child: Text('Batal',
                      style:
                          TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// --- Model -----------------------------------------------------------

class SleepStory {
  final String id;
  final String title;
  final int duration; // minutes
  final String category;
  final String sound;
  final IconData icon;
  final Color color;
  final bool isPremium;

  const SleepStory({
    required this.id,
    required this.title,
    required this.duration,
    required this.category,
    required this.sound,
    required this.icon,
    required this.color,
    required this.isPremium,
  });
}