import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  int _activeGame = -1;

  // ---------- Word Recall ----------
  final List<String> _wordPool = [
    'mimpi', 'samudra', 'komet', 'lentera', 'hutan', 'gurun', 'fajar',
    'kristal', 'badai', 'permata', 'galaksi', 'sungai', 'gunung', 'angin',
    'petir', 'ombak', 'salju', 'embun', 'raja', 'naga',
  ];
  List<String> _words = [];
  int _wrPhase = 0; // 0 idle, 1 show, 2 input, 3 done
  int _wrShow = 10;
  Timer? _wrTimer;
  final List<TextEditingController> _wrCtrl = List.generate(5, (_) => TextEditingController());
  int _wrScore = 0;

  // ---------- Sequence Memory ----------
  List<int> _seq = [];
  int _seqStep = 0;
  int _seqShowIdx = -1;
  bool _seqShowing = false;
  int _seqPhase = 0; // 0 idle, 1 show, 2 play, 3 done
  int _seqScore = 0;
  Timer? _seqTimer;

  // ---------- Pattern Matching ----------
  List<String> _patternCards = [];
  List<int> _flipped = [];
  List<int> _matched = [];
  bool _pmLock = false;
  int _pmMoves = 0;
  int _pmScore = 0;

  // ---------- Number Memory ----------
  String _number = '';
  int _nmPhase = 0; // 0 idle, 1 show, 2 input, 3 done
  int _nmShow = 5;
  Timer? _nmTimer;
  final _nmCtrl = TextEditingController();
  int _nmScore = 0;

  // ---------- Flashcard ----------
  final _fcFront = TextEditingController();
  final _fcBack = TextEditingController();
  String _fcCategory = 'Quran';
  final List<Map<String, String>> _flashcards = [];
  int _fcIdx = 0;
  bool _fcShowBack = false;
  int _fcKnown = 0;
  int _fcUnknown = 0;

  // ---------- Weekly scores ----------
  final List<int> _weekly = [40, 55, 70, 60, 80, 75, 0];

  @override
  void dispose() {
    _wrTimer?.cancel();
    _seqTimer?.cancel();
    _nmTimer?.cancel();
    for (final c in _wrCtrl) c.dispose();
    _nmCtrl.dispose();
    _fcFront.dispose();
    _fcBack.dispose();
    super.dispose();
  }

  // ============ Word Recall ============
  void _wrStart() {
    final rng = Random();
    _words = List.generate(5, (_) => _wordPool[rng.nextInt(_wordPool.length)]);
    setState(() {
      _wrPhase = 1;
      _wrShow = 10;
      _wrScore = 0;
      for (final c in _wrCtrl) c.clear();
    });
    _wrTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _wrShow--;
        if (_wrShow <= 0) {
          t.cancel();
          _wrPhase = 2;
        }
      });
    });
  }

  void _wrSubmit() {
    int s = 0;
    for (int i = 0; i < 5; i++) {
      if (_wrCtrl[i].text.trim().toLowerCase() == _words[i]) s++;
    }
    setState(() {
      _wrScore = (s * 20);
      _wrPhase = 3;
      _weekly[6] = _weekly[6] + s * 4;
    });
  }

  // ============ Sequence Memory ============
  void _seqStart() {
    final rng = Random();
    _seq = List.generate(4, (_) => rng.nextInt(9));
    _seqStep = 0;
    _seqScore = 0;
    setState(() => _seqPhase = 1);
    _seqShowSequence();
  }

  void _seqShowSequence() {
    _seqShowing = true;
    int i = 0;
    void next() {
      if (i >= _seq.length) {
        setState(() {
          _seqShowIdx = -1;
          _seqShowing = false;
          _seqPhase = 2;
        });
        return;
      }
      setState(() => _seqShowIdx = _seq[i]);
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() => _seqShowIdx = -1);
        Future.delayed(const Duration(milliseconds: 300), () {
          i++;
          next();
        });
      });
    }
    next();
  }

  void _seqClick(int idx) {
    if (_seqPhase != 2) return;
    if (idx == _seq[_seqStep]) {
      setState(() {
        _seqShowIdx = idx;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() => _seqShowIdx = -1);
      });
      _seqStep++;
      if (_seqStep >= _seq.length) {
        setState(() {
          _seqScore = 100;
          _seqPhase = 3;
          _weekly[6] += 15;
        });
      }
    } else {
      setState(() {
        _seqScore = (_seqStep * 25);
        _seqPhase = 3;
        _weekly[6] += _seqStep * 3;
      });
    }
  }

  // ============ Pattern Matching ============
  void _pmStart() {
    final emojis = ['🧠', '🔮', '💎', '⚡', '🌙', '🌟', '🔥', '❄️'];
    final all = [...emojis, ...emojis];
    all.shuffle(Random());
    setState(() {
      _patternCards = all;
      _flipped = [];
      _matched = [];
      _pmMoves = 0;
      _pmScore = 0;
    });
  }

  void _pmFlip(int idx) {
    if (_pmLock || _flipped.contains(idx) || _matched.contains(idx)) return;
    setState(() {
      _flipped.add(idx);
      if (_flipped.length == 2) {
        _pmMoves++;
        _pmLock = true;
        if (_patternCards[_flipped[0]] == _patternCards[_flipped[1]]) {
          _matched.addAll(_flipped);
          _flipped.clear();
          _pmLock = false;
          if (_matched.length == 16) {
            _pmScore = _pmMoves <= 10 ? 100 : (100 - (_pmMoves - 10) * 5).clamp(0, 100);
            _weekly[6] += 10;
          }
        } else {
          Future.delayed(const Duration(milliseconds: 800), () {
            setState(() {
              _flipped.clear();
              _pmLock = false;
            });
          });
        }
      }
    });
  }

  // ============ Number Memory ============
  void _nmStart() {
    final rng = Random();
    _number = List.generate(6, (_) => rng.nextInt(10)).join();
    setState(() {
      _nmPhase = 1;
      _nmShow = 5;
      _nmCtrl.clear();
    });
    _nmTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _nmShow--;
        if (_nmShow <= 0) {
          t.cancel();
          _nmPhase = 2;
        }
      });
    });
  }

  void _nmSubmit() {
    final correct = _nmCtrl.text.trim() == _number;
    setState(() {
      _nmScore = correct ? 100 : 0;
      _nmPhase = 3;
      _weekly[6] += correct ? 10 : 0;
    });
  }

  // ============ Flashcard ============
  void _fcAdd() {
    if (_fcFront.text.trim().isEmpty || _fcBack.text.trim().isEmpty) return;
    setState(() {
      _flashcards.add({
        'front': _fcFront.text.trim(),
        'back': _fcBack.text.trim(),
        'category': _fcCategory,
      });
      _fcFront.clear();
      _fcBack.clear();
      _fcIdx = _flashcards.length - 1;
      _fcShowBack = false;
    });
  }

  void _fcFlip() {
    setState(() => _fcShowBack = !_fcShowBack);
  }

  void _fcAnswer(bool known) {
    if (_flashcards.isEmpty) return;
    setState(() {
      if (known) _fcKnown++; else _fcUnknown++;
      _fcShowBack = false;
      if (_fcIdx < _flashcards.length - 1) {
        _fcIdx++;
      } else {
        _fcIdx = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SomaTheme.bgDeep,
        appBar: AppBar(
          title: const Text('Memory Trainer', style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Games'),
              Tab(text: 'Flashcard'),
              Tab(text: 'Score'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGames(),
            _buildFlashcard(),
            _buildScore(),
          ],
        ),
      ),
    );
  }

  // ============ Games Tab ============
  Widget _buildGames() {
    if (_activeGame == -1) {
      return GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: [
          _gameTile(0, 'Word Recall', Icons.text_fields, SomaTheme.tealBright),
          _gameTile(1, 'Sequence Memory', Icons.grid_on, SomaTheme.lavender),
          _gameTile(2, 'Pattern Match', Icons.style, SomaTheme.purple),
          _gameTile(3, 'Number Memory', Icons.pin, SomaTheme.softBlue),
        ],
      );
    }
    switch (_activeGame) {
      case 0:
        return _wordRecall();
      case 1:
        return _sequenceMemory();
      case 2:
        return _patternMatch();
      case 3:
        return _numberMemory();
      default:
        return Container();
    }
  }

  Widget _gameTile(int idx, String name, IconData icon, Color c) {
    return GestureDetector(
      onTap: () => setState(() => _activeGame = idx),
      child: Container(
        decoration: BoxDecoration(
          color: SomaTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: c),
            const SizedBox(height: 8),
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SomaTheme.text)),
          ],
        ),
      ),
    );
  }

  Widget _gameBackBtn() {
    return Align(
      alignment: Alignment.topLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _activeGame = -1),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Kembali'),
        style: TextButton.styleFrom(foregroundColor: SomaTheme.tealBright),
      ),
    );
  }

  Widget _wordRecall() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _gameBackBtn(),
        _sectionTitle('Word Recall', Icons.text_fields),
        _card(Column(
          children: [
            if (_wrPhase == 0)
              ElevatedButton.icon(onPressed: _wrStart, icon: const Icon(Icons.play_arrow), label: const Text('Mulai'))
            else if (_wrPhase == 1) ...[
              Text('Hafalkan kata-kata ini!', style: TextStyle(color: SomaTheme.tealBright, fontSize: 14)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _words.map((w) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: SomaTheme.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SomaTheme.teal),
                  ),
                  child: Text(w, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SomaTheme.white)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Text('$_wrShow detik', style: TextStyle(fontSize: 20, color: SomaTheme.lavender, fontWeight: FontWeight.w700)),
            ] else if (_wrPhase == 2) ...[
              Text('Tulis kata yang Anda hafal:', style: TextStyle(color: SomaTheme.tealBright, fontSize: 14)),
              const SizedBox(height: 12),
              for (int i = 0; i < 5; i++) ...[
                TextField(
                  controller: _wrCtrl[i],
                  decoration: InputDecoration(hintText: 'Kata ${i + 1}'),
                  style: TextStyle(color: SomaTheme.text),
                ),
                if (i < 4) const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _wrSubmit, icon: const Icon(Icons.check), label: const Text('Submit')),
            ] else ...[
              Text('Skor: $_wrScore / 100', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: SomaTheme.tealBright)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _words.map((w) => Text(w, style: TextStyle(color: SomaTheme.textMuted, fontSize: 14))).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _wrStart, icon: const Icon(Icons.refresh), label: const Text('Ulangi')),
            ],
          ],
        )),
      ],
    );
  }

  Widget _sequenceMemory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _gameBackBtn(),
        _sectionTitle('Sequence Memory', Icons.grid_on),
        _card(Column(
          children: [
            if (_seqPhase == 0)
              ElevatedButton.icon(onPressed: _seqStart, icon: const Icon(Icons.play_arrow), label: const Text('Mulai'))
            else ...[
              if (_seqShowing)
                Text('Perhatikan...', style: TextStyle(color: SomaTheme.tealBright, fontSize: 14))
              else if (_seqPhase == 2)
                Text('Ulangi urutan!', style: TextStyle(color: SomaTheme.tealBright, fontSize: 14))
              else
                Text('Skor: $_seqScore / 100', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SomaTheme.tealBright)),
              const SizedBox(height: 12),
              SizedBox(
                width: 240,
                height: 240,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
                  itemCount: 9,
                  itemBuilder: (ctx, i) {
                    final active = _seqShowIdx == i;
                    return GestureDetector(
                      onTap: _seqPhase == 2 ? () => _seqClick(i) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: active ? SomaTheme.tealBright : SomaTheme.bgDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SomaTheme.teal, width: 1.5),
                        ),
                        child: active ? const Center(child: Icon(Icons.circle, color: Colors.black)) : null,
                      ),
                    );
                  },
                ),
              ),
              if (_seqPhase == 3) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: _seqStart, icon: const Icon(Icons.refresh), label: const Text('Ulangi')),
              ],
            ],
          ],
        )),
      ],
    );
  }

  Widget _patternMatch() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _gameBackBtn(),
        _sectionTitle('Pattern Matching', Icons.style),
        _card(Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Moves: $_pmMoves', style: TextStyle(color: SomaTheme.textMuted)),
                if (_matched.length == 16)
                  Text('Menang! $_pmScore pts', style: TextStyle(color: SomaTheme.tealBright, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 280,
              height: 280,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 4, crossAxisSpacing: 4),
                itemCount: 16,
                itemBuilder: (ctx, i) {
                  final show = _flipped.contains(i) || _matched.contains(i);
                  return GestureDetector(
                    onTap: () => _pmFlip(i),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        key: ValueKey('$i-$show'),
                        decoration: BoxDecoration(
                          color: show ? SomaTheme.purple : SomaTheme.bgDeep,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: SomaTheme.purple.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(show ? _patternCards[i] : '?', style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              ElevatedButton.icon(onPressed: _pmStart, icon: const Icon(Icons.play_arrow), label: const Text('Mulai / Reset')),
              ],
            ),
          ],
        )),
      ],
    );
  }

  Widget _numberMemory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _gameBackBtn(),
        _sectionTitle('Number Memory', Icons.pin),
        _card(Column(
          children: [
            if (_nmPhase == 0)
              ElevatedButton.icon(onPressed: _nmStart, icon: const Icon(Icons.play_arrow), label: const Text('Mulai'))
            else if (_nmPhase == 1) ...[
              Text('Hafalkan angka ini!', style: TextStyle(color: SomaTheme.tealBright, fontSize: 14)),
              const SizedBox(height: 16),
              Text(_number, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: SomaTheme.white, letterSpacing: 4)),
              const SizedBox(height: 16),
              Text('$_nmShow detik', style: TextStyle(fontSize: 18, color: SomaTheme.lavender)),
            ] else if (_nmPhase == 2) ...[
              Text('Masukkan angka:', style: TextStyle(color: SomaTheme.tealBright, fontSize: 14)),
              const SizedBox(height: 12),
              TextField(
                controller: _nmCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: SomaTheme.white, fontSize: 24, letterSpacing: 2),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'Angka...'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _nmSubmit, icon: const Icon(Icons.check), label: const Text('Submit')),
            ] else ...[
              Text('Skor: $_nmScore / 100', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: SomaTheme.tealBright)),
              const SizedBox(height: 12),
              Text('Jawaban: $_number', style: TextStyle(color: SomaTheme.textMuted, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _nmStart, icon: const Icon(Icons.refresh), label: const Text('Ulangi')),
            ],
          ],
        )),
      ],
    );
  }

  // ============ Flashcard Tab ============
  Widget _buildFlashcard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Buat Flashcard', Icons.add_card),
        _card(Column(
          children: [
            TextField(
              controller: _fcFront,
              style: TextStyle(color: SomaTheme.text),
              decoration: const InputDecoration(labelText: 'Depan (Pertanyaan)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fcBack,
              style: TextStyle(color: SomaTheme.text),
              decoration: const InputDecoration(labelText: 'Belakang (Jawaban)'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Quran', 'Vocabulary', 'Angka', 'Nama', 'Lainnya'].map((cat) {
                return ChoiceChip(
                  label: Text(cat),
                  selected: _fcCategory == cat,
                  selectedColor: SomaTheme.purple,
                  backgroundColor: SomaTheme.bgDeep,
                  labelStyle: TextStyle(color: _fcCategory == cat ? SomaTheme.white : SomaTheme.textMuted),
                  onSelected: (_) => setState(() => _fcCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(onPressed: _fcAdd, icon: const Icon(Icons.add), label: const Text('Tambah Kartu')),
            ),
          ],
        )),
        const SizedBox(height: 20),
        if (_flashcards.isNotEmpty) ...[
          _sectionTitle('Kartu ${_fcIdx + 1}/${_flashcards.length}', Icons.quiz),
          GestureDetector(
            onTap: _fcFlip,
            child: _card(
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) {
                  final tilt = Tween(begin: 0.0, end: 1.0).animate(anim);
                  return RotationTransition(
                    turns: tilt,
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Container(
                  key: ValueKey(_fcShowBack),
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    key: ValueKey('fc${_fcIdx}_$_fcShowBack'),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SomaTheme.purple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_flashcards[_fcIdx]['category']!, style: TextStyle(color: SomaTheme.lavender, fontSize: 12)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _fcShowBack ? _flashcards[_fcIdx]['back']! : _flashcards[_fcIdx]['front']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: SomaTheme.white),
                      ),
                      const SizedBox(height: 16),
                      Text('Tap untuk flip', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _fcAnswer(false),
                  icon: const Icon(Icons.close),
                  label: const Text('Tidak Tahu'),
                  style: ElevatedButton.styleFrom(backgroundColor: SomaTheme.purple),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _fcAnswer(true),
                  icon: const Icon(Icons.check),
                  label: const Text('Tahu'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _flashcards.isEmpty ? 0 : _fcKnown / _flashcards.length,
            backgroundColor: SomaTheme.bgCard,
            color: SomaTheme.teal,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('Hafal: $_fcKnown / ${_flashcards.length}  |  Belum: $_fcUnknown', style: TextStyle(color: SomaTheme.tealBright, fontSize: 12)),
        ] else
          _card(Center(child: Text('Belum ada kartu. Buat dulu!', style: TextStyle(color: SomaTheme.textMuted)))),
      ],
    );
  }

  // ============ Score Tab ============
  Widget _buildScore() {
    final totalScore = (_wrScore + _seqScore + _pmScore + _nmScore) ~/ 4;
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxV = _weekly.reduce((a, b) => a > b ? a : b).toDouble().clamp(1, double.infinity);
    final badges = <Map<String, dynamic>>[
      {'name': 'First Steps', 'icon': '🎯', 'unlocked': totalScore > 0},
      {'name': 'Sharp Mind', 'icon': '🧠', 'unlocked': totalScore >= 50},
      {'name': 'Memory Master', 'icon': '🏆', 'unlocked': totalScore >= 80},
      {'name': 'Flashcard Pro', 'icon': '📇', 'unlocked': _fcKnown >= 5},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Memory Score', Icons.emoji_events),
        _card(Column(
          children: [
            Text('Total Skor', style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 4),
            Text('$totalScore / 100', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: SomaTheme.tealBright)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniScore('Word', _wrScore, SomaTheme.tealBright),
                _miniScore('Seq', _seqScore, SomaTheme.lavender),
                _miniScore('Pattern', _pmScore, SomaTheme.purple),
                _miniScore('Number', _nmScore, SomaTheme.softBlue),
              ],
            ),
          ],
        )),
        const SizedBox(height: 20),
        _sectionTitle('Achievements', Icons.star),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (ctx, i) {
              final b = badges[i];
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: SomaTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (b['unlocked'] as bool) ? SomaTheme.tealBright : SomaTheme.textMuted.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(opacity: (b['unlocked'] as bool) ? 1 : 0.3, child: Text(b['icon'] as String, style: const TextStyle(fontSize: 28))),
                    const SizedBox(height: 4),
                    Text(b['name'] as String, style: TextStyle(fontSize: 10, color: (b['unlocked'] as bool) ? SomaTheme.text : SomaTheme.textMuted)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Progress 7 Hari', Icons.trending_up),
        _card(
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = (_weekly[i] / maxV) * 140;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${_weekly[i]}', style: TextStyle(color: SomaTheme.textMuted, fontSize: 9)),
                        const SizedBox(height: 2),
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

  Widget _miniScore(String label, int score, Color c) {
    return Column(
      children: [
        Text('$score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: SomaTheme.textMuted)),
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