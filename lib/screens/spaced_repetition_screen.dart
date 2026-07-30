import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/soma_theme.dart';

/// SPACED REPETITION PRO
/// Flashcard manager with SM-2-like review schedule, daily due counter,
/// statistics, and import/export via clipboard.
class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  static const _storageKey = 'soma_flashcards_pro';
  static const _streakKey = 'soma_flashcards_streak';
  static const _historyKey = 'soma_flashcards_history';

  static const _categories = [
    'Quran',
    'Bahasa',
    'Sains',
    'Sejarah',
    'Nama',
    'Angka',
    'Lainnya',
  ];

  // Spaced repetition intervals (days) for "Tahu"
  static const _tahuIntervals = [1, 3, 7, 21, 90];

  final List<_Flashcard> _cards = [];
  int _reviewIdx = 0;
  bool _showBack = false;
  int _reviewedToday = 0;
  int _streak = 0;
  String _lastReviewDate = '';
  final List<int> _weeklyHistory = [0, 0, 0, 0, 0, 0, 0]; // oldest→newest

  // Add card form
  final _titleCtrl = TextEditingController();
  final _frontCtrl = TextEditingController();
  final _backCtrl = TextEditingController();
  String _category = 'Quran';

  // Import / Export
  final _importCtrl = TextEditingController();

  bool _isReviewing = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _frontCtrl.dispose();
    _backCtrl.dispose();
    _importCtrl.dispose();
    super.dispose();
  }

  // ============ Persistence ============

  Future<void> _loadAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _cards.clear();
        for (final e in list) {
          _cards.add(_Flashcard.fromJson(e as Map<String, dynamic>));
        }
      });
    }
    _streak = sp.getInt(_streakKey) ?? 0;
    _lastReviewDate = sp.getString('${_streakKey}_date') ?? '';
    final histRaw = sp.getString(_historyKey);
    if (histRaw != null) {
      final h = jsonDecode(histRaw) as List;
      for (int i = 0; i < 7 && i < h.length; i++) {
        _weeklyHistory[i] = (h[i] as num).toInt();
      }
      setState(() {});
    }
  }

  Future<void> _persistCards() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _storageKey, jsonEncode(_cards.map((c) => c.toJson()).toList()));
  }

  Future<void> _persistStreak() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_streakKey, _streak);
    await sp.setString('${_streakKey}_date', _lastReviewDate);
  }

  Future<void> _persistHistory() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_historyKey, jsonEncode(_weeklyHistory));
  }

  // ============ Card management ============

  void _addCard() {
    if (_frontCtrl.text.trim().isEmpty || _backCtrl.text.trim().isEmpty) return;
    setState(() {
      _cards.add(_Flashcard(
        title: _titleCtrl.text.trim().isEmpty
            ? _frontCtrl.text.trim()
            : _titleCtrl.text.trim(),
        front: _frontCtrl.text.trim(),
        back: _backCtrl.text.trim(),
        category: _category,
        dueDate: _dateOnly(DateTime.now()),
        intervalIdx: -1,
      ));
      _titleCtrl.clear();
      _frontCtrl.clear();
      _backCtrl.clear();
    });
    _persistCards();
  }

  void _deleteCard(int idx) {
    setState(() => _cards.removeAt(idx));
    _persistCards();
  }

  // ============ Review ============

  List<_Flashcard> get _dueCards => _cards
      .where((c) =>
          !c.dueDate.isAfter(_dateOnly(DateTime.now().add(const Duration(days: 1)))) &&
          c.intervalIdx < _tahuIntervals.length - 1)
      .toList();

  void _startReview() {
    if (_dueCards.isEmpty) return;
    setState(() {
      _isReviewing = true;
      _reviewIdx = 0;
      _showBack = false;
      _reviewedToday = 0;
    });
  }

  void _answer(bool tahu) {
    if (_dueCards.isEmpty) return;
    final card = _dueCards[_reviewIdx];
    setState(() {
      if (tahu) {
        card.intervalIdx =
            (card.intervalIdx + 1).clamp(0, _tahuIntervals.length - 1);
        final days = _tahuIntervals[card.intervalIdx];
        card.dueDate = _dateOnly(DateTime.now().add(Duration(days: days)));
      } else {
        card.intervalIdx = 0;
        card.dueDate =
            _dateOnly(DateTime.now().add(const Duration(days: 1)));
      }
      _reviewedToday++;
      _showBack = false;
      if (_reviewIdx < _dueCards.length - 1) {
        _reviewIdx++;
      } else {
        _finishReview();
      }
    });
    _persistCards();
  }

  void _finishReview() {
    final today = _dateOnly(DateTime.now());
    final todayStr = today.toIso8601String().substring(0, 10);
    // Update streak
    if (_lastReviewDate != todayStr) {
      final yesterday =
          today.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (_lastReviewDate == yesterday) {
        _streak++;
      } else {
        _streak = 1;
      }
      _lastReviewDate = todayStr;
      _persistStreak();
    }
    // Update weekly history (shift left, add today's count)
    setState(() {
      _weeklyHistory.removeAt(0);
      _weeklyHistory.add(_reviewedToday);
      _isReviewing = false;
    });
    _persistHistory();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // ============ Import / Export ============

  void _importFromText() {
    final text = _importCtrl.text.trim();
    if (text.isEmpty) return;
    final lines = text.split('\n');
    int added = 0;
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length >= 2) {
        final front = parts[0].trim();
        final back = parts[1].trim();
        final cat = parts.length >= 3 ? parts[2].trim() : 'Lainnya';
        if (front.isEmpty || back.isEmpty) continue;
        _cards.add(_Flashcard(
          title: front,
          front: front,
          back: back,
          category: _categories.contains(cat) ? cat : 'Lainnya',
          dueDate: _dateOnly(DateTime.now()),
          intervalIdx: -1,
        ));
        added++;
      }
    }
    setState(() {});
    _importCtrl.clear();
    _persistCards();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$added kartu diimport')),
      );
    }
  }

  void _exportToClipboard() {
    final buf = StringBuffer();
    for (final c in _cards) {
      buf.writeln('${c.front}|${c.back}|${c.category}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kartu disalin ke clipboard')),
      );
    }
  }

  // ============ Statistics ============

  int get _totalCards => _cards.length;
  int get _hafalCards =>
      _cards.where((c) => c.intervalIdx >= _tahuIntervals.length - 1).length;
  int get _pendingCards => _totalCards - _hafalCards;

  Map<String, int> _categoryCount(String cat) {
    final all = _cards.where((c) => c.category == cat).length;
    final hafal = _cards
        .where((c) => c.category == cat && c.intervalIdx >= _tahuIntervals.length - 1)
        .length;
    return {'all': all, 'hafal': hafal};
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: SomaTheme.bgDeep,
        appBar: AppBar(
          title: const Text('Spaced Repetition Pro',
              style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kartu'),
              Tab(text: 'Review'),
              Tab(text: 'Statistik'),
              Tab(text: 'Import/Export'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCardManager(),
            _buildReviewTab(),
            _buildStatistics(),
            _buildImportExport(),
          ],
        ),
      ),
    );
  }

  // ---- Card Manager ----
  Widget _buildCardManager() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Tambah Flashcard', Icons.add_card),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul (opsional)'),
                style: const TextStyle(color: SomaTheme.text),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _frontCtrl,
                decoration: const InputDecoration(labelText: 'Depan (Pertanyaan)'),
                style: const TextStyle(color: SomaTheme.text),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _backCtrl,
                decoration: const InputDecoration(labelText: 'Belakang (Jawaban)'),
                style: const TextStyle(color: SomaTheme.text),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                dropdownColor: SomaTheme.bgCard,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Quran'),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _addCard,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kartu'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Daftar Kartu (${_cards.length})', Icons.style),
        if (_cards.isEmpty)
          _emptyHint('Belum ada kartu. Tambahkan atau import di tab Import/Export.')
        else
          ..._cards.asMap().entries.map((e) => _buildCardItem(e.key, e.value)),
      ],
    );
  }

  Widget _buildCardItem(int idx, _Flashcard c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SomaTheme.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c.category,
                          style: TextStyle(
                              color: SomaTheme.lavender, fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(c.title,
                          style: TextStyle(
                              color: SomaTheme.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Q: ${c.front}',
                    style: TextStyle(color: SomaTheme.text, fontSize: 12)),
                Text('A: ${c.back}',
                    style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  c.intervalIdx >= _tahuIntervals.length - 1
                      ? '✓ Hafal'
                      : 'Due: ${c.dueDate.toIso8601String().substring(0, 10)}',
                  style: TextStyle(
                      color: c.intervalIdx >= _tahuIntervals.length - 1
                          ? SomaTheme.tealBright
                          : SomaTheme.textMuted,
                      fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteCard(idx),
          ),
        ],
      ),
    );
  }

  // ---- Review ----
  Widget _buildReviewTab() {
    if (_isReviewing) return _buildReviewSession();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Due Today', Icons.today),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$_dueCardsCount',
                      style: TextStyle(
                          color: SomaTheme.tealBright,
                          fontSize: 36,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Text('kartu due hari ini',
                      style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Text('$_reviewedToday sudah direview',
                  style: TextStyle(color: SomaTheme.lavender, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department,
                      color: SomaTheme.tealBright, size: 18),
                  const SizedBox(width: 4),
                  Text('Streak: $_streak hari',
                      style: TextStyle(
                          color: SomaTheme.white, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _dueCardsCount > 0 ? _startReview : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Review'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int get _dueCardsCount => _dueCards.length;

  Widget _buildReviewSession() {
    if (_dueCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: SomaTheme.tealBright, size: 64),
            const SizedBox(height: 16),
            Text('Review selesai!',
                style: TextStyle(
                    color: SomaTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('$_reviewedToday kartu direview',
                style: TextStyle(color: SomaTheme.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isReviewing = false),
              icon: const Icon(Icons.check),
              label: const Text('Selesai'),
            ),
          ],
        ),
      );
    }
    final card = _dueCards[_reviewIdx];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Kartu ${_reviewIdx + 1} dari ${_dueCards.length}',
          textAlign: TextAlign.center,
          style: TextStyle(color: SomaTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) {
            final turn = child.key == const ValueKey('back')
                ? Tween(begin: 0.5, end: 1.0).animate(anim)
                : Tween(begin: 1.0, end: 0.5).animate(anim);
            return RotationTransition(turns: turn, child: child);
          },
          child: _showBack
              ? Container(
                  key: const ValueKey('back'),
                  height: 260,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: SomaTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SomaTheme.tealBright, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Jawaban',
                          style: TextStyle(
                              color: SomaTheme.tealBright, fontSize: 12)),
                      const SizedBox(height: 12),
                      Text(card.back,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: SomaTheme.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              : Container(
                  key: const ValueKey('front'),
                  height: 260,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: SomaTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SomaTheme.lavender, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(card.category,
                          style: TextStyle(
                              color: SomaTheme.lavender, fontSize: 12)),
                      const SizedBox(height: 12),
                      Text(card.front,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: SomaTheme.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Text('Tap untuk lihat jawaban',
                          style: TextStyle(
                              color: SomaTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 20),
        if (!_showBack)
          ElevatedButton.icon(
            onPressed: () => setState(() => _showBack = true),
            icon: const Icon(Icons.flip),
            label: const Text('Lihat Jawaban'),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _answer(false),
                icon: const Icon(Icons.close),
                label: const Text('Tidak Tahu'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _answer(true),
                icon: const Icon(Icons.check),
                label: const Text('Tahu'),
              ),
            ],
          ),
      ],
    );
  }

  // ---- Statistics ----
  Widget _buildStatistics() {
    final maxHist = _weeklyHistory.fold<int>(1, (a, b) => a > b ? a : b);
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Statistik', Icons.bar_chart),
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
                  _statBox('Total', _totalCards, SomaTheme.softBlue),
                  _statBox('Hafal', _hafalCards, SomaTheme.tealBright),
                  _statBox('Pending', _pendingCards, SomaTheme.lavender),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _totalCards == 0 ? 0 : _hafalCards / _totalCards,
                backgroundColor: SomaTheme.bgDeep,
                color: SomaTheme.tealBright,
                minHeight: 8,
              ),
              const SizedBox(height: 6),
              Text(
                  'Progres hafal: ${_totalCards == 0 ? 0 : ((_hafalCards / _totalCards) * 100).round()}%',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Per Kategori', Icons.category),
        ..._categories.map((c) {
          final counts = _categoryCount(c);
          if (counts['all'] == 0) return const SizedBox.shrink();
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
                Text(c, style: TextStyle(color: SomaTheme.white, fontSize: 13)),
                const Spacer(),
                Text('${counts['hafal']}/${counts['all']} hafal',
                    style: TextStyle(color: SomaTheme.tealBright, fontSize: 12)),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        _sectionTitle('Review 7 Hari', Icons.trending_up),
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
                final h = (_weeklyHistory[i] / maxHist) * 120;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${_weeklyHistory[i]}',
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

  Widget _statBox(String label, int value, Color c) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
      ],
    );
  }

  // ---- Import / Export ----
  Widget _buildImportExport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Import Kartu', Icons.download),
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
                'Format: depan|belakang|kategori (satu kartu per baris)',
                style: TextStyle(color: SomaTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _importCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'contoh:\nApa ibukota Indonesia?|Jakarta|Sains\n5 x 5 = ?|25|Angka',
                ),
                style: const TextStyle(color: SomaTheme.text),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _importFromText,
                icon: const Icon(Icons.download),
                label: const Text('Import'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Export Kartu', Icons.upload),
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
              Text('${_cards.length} kartu siap diexport.',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _exportToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy ke Clipboard'),
              ),
            ],
          ),
        ),
      ],
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

  Widget _emptyHint(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
    );
  }
}

class _Flashcard {
  final String title;
  final String front;
  final String back;
  final String category;
  DateTime dueDate;
  int intervalIdx;

  _Flashcard({
    required this.title,
    required this.front,
    required this.back,
    required this.category,
    required this.dueDate,
    required this.intervalIdx,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'front': front,
        'back': back,
        'category': category,
        'dueDate': dueDate.toIso8601String(),
        'intervalIdx': intervalIdx,
      };

  factory _Flashcard.fromJson(Map<String, dynamic> j) => _Flashcard(
        title: j['title'] as String? ?? '',
        front: j['front'] as String? ?? '',
        back: j['back'] as String? ?? '',
        category: j['category'] as String? ?? 'Lainnya',
        dueDate: DateTime.tryParse(j['dueDate'] as String? ?? '') ??
            DateTime.now(),
        intervalIdx: (j['intervalIdx'] as num?)?.toInt() ?? -1,
      );
}