import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'Quran';
  final _categories = ['Quran', 'Bahasa', 'Sains', 'Sejarah', 'Lainnya'];

  // Dummy data
  List<Map<String, dynamic>> _materials = [
    {'title': 'Al-Fatihah', 'category': 'Quran', 'progress': 75},
    {'title': 'Irregular Verbs', 'category': 'Bahasa', 'progress': 40},
    {'title': 'Sistem Pencernaan', 'category': 'Sains', 'progress': 60},
    {'title': 'Majapahit', 'category': 'Sejarah', 'progress': 20},
    {'title': 'Hippocampus', 'category': 'Sains', 'progress': 100},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Learning Assistant', style: TextStyle(color: SomaTheme.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Belajar & hafal materi dengan spaced repetition', style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 24),
        // Input materi
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Materi Baru', style: TextStyle(color: SomaTheme.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Materi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Isi Materi'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  final active = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? SomaTheme.teal.withOpacity(0.2) : SomaTheme.bgDeep,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? SomaTheme.teal : SomaTheme.teal.withOpacity(0.2)),
                      ),
                      child: Text(cat, style: TextStyle(color: active ? SomaTheme.tealBright : SomaTheme.textMuted, fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_titleController.text.isNotEmpty) {
                      setState(() {
                        _materials.insert(0, {'title': _titleController.text, 'category': _category, 'progress': 0});
                        _titleController.clear();
                        _contentController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Materi'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Progress overview
        Row(
          children: [
            _buildProgressCard('${_materials.length}', 'Total Materi'),
            const SizedBox(width: 12),
            _buildProgressCard('${_materials.where((m) => m['progress'] == 100).length}', 'Selesai Hafal'),
            const SizedBox(width: 12),
            _buildProgressCard('${_materials.where((m) => m['progress'] < 100).length}', 'Pending'),
          ],
        ),
        const SizedBox(height: 16),
        // Materi list
        Text('Daftar Materi', style: TextStyle(color: SomaTheme.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._materials.map((m) => _buildMaterialCard(m)),
        const SizedBox(height: 16),
        // Learning tips
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SomaTheme.lavender.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.lightbulb, color: SomaTheme.lavender, size: 24),
              const SizedBox(height: 12),
              Text('"Otak belajar paling efektif 25-30 menit, lalu istirahat 5 menit."', 
                style: TextStyle(color: SomaTheme.text, fontSize: 13, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SomaTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: SomaTheme.tealBright, fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> m) {
    final progress = (m['progress'] as int).toDouble();
    Color catColor;
    switch (m['category'] as String) {
      case 'Quran': catColor = SomaTheme.lavender; break;
      case 'Bahasa': catColor = SomaTheme.softBlue; break;
      case 'Sains': catColor = SomaTheme.teal; break;
      case 'Sejarah': catColor = SomaTheme.purple; break;
      default: catColor = Colors.orange;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: catColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(m['title'] as String, style: TextStyle(color: SomaTheme.text, fontSize: 15, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(m['category'] as String, style: TextStyle(color: catColor, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 6,
                    backgroundColor: SomaTheme.bgDeep,
                    valueColor: AlwaysStoppedAnimation<Color>(catColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${progress.round()}', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}