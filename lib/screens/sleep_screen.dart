import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 5, minute: 0);
  double _quality = 7;

  String get _duration {
    int sleepMin = _sleepTime.hour * 60 + _sleepTime.minute;
    int wakeMin = _wakeTime.hour * 60 + _wakeTime.minute;
    int diff = wakeMin > sleepMin ? wakeMin - sleepMin : (24 * 60 - sleepMin) + wakeMin;
    int hours = diff ~/ 60;
    int mins = diff % 60;
    return '$hours j $mins m';
  }

  String get _qualityLabel {
    if (_quality <= 3) return '😴 Buruk';
    if (_quality <= 6) return '😐 Biasa';
    if (_quality <= 8) return '😊 Baik';
    return '🌟 Excellent';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Sleep Therapy', style: TextStyle(color: SomaTheme.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Terapi tidur untuk istirahat otak yang optimal', style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 24),
        // Sleep Tracker
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
              Text('Sleep Tracker', style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimePicker('Jam Tidur', _sleepTime, (t) => setState(() => _sleepTime = t))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimePicker('Jam Bangun', _wakeTime, (t) => setState(() => _wakeTime = t))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SomaTheme.bgDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bedtime, color: SomaTheme.teal, size: 20),
                    const SizedBox(width: 8),
                    Text('Durasi: $_duration', style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Skor Kualitas Tidur: $_qualityLabel', style: TextStyle(color: SomaTheme.text, fontSize: 14)),
              const SizedBox(height: 8),
              Slider(value: _quality, min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => _quality = v)),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Berapa kali terbangun? Ada mimpi? Bangun terasa gimana?',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Tidur Malam Ini'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Doa Sebelum Tidur
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SomaTheme.lavender.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text('🤲 Doa Sebelum Tidur', style: TextStyle(color: SomaTheme.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text('بِاسْمِكَ اللَّهُمَّ أَحْيَا وَأَمُوتُ', style: TextStyle(color: SomaTheme.white, fontSize: 24), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Bismika Allahumma ahyaa wa amuut', style: TextStyle(color: SomaTheme.lavender, fontSize: 14, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Dengan nama-Mu ya Allah, aku hidup dan aku mati.', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check),
                label: const Text('Sudah Baca'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: time);
            if (t != null) onChanged(t);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SomaTheme.bgDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: SomaTheme.teal, size: 20),
                const SizedBox(width: 8),
                Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: SomaTheme.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}