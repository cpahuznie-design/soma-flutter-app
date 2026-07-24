import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = 'Pak Husni';
  String _email = 'pakhusni@soma.app';

  double _targetSleep = 7.5;
  int _targetFocus = 4;
  int _targetMemory = 2;
  int _targetLearn = 30;

  bool _notifSleep = true;
  bool _notifFocus = true;
  bool _notifMemory = true;
  bool _notifLearn = true;
  bool _notifBreathing = true;
  bool _notifSound = true;
  bool _darkMode = true;
  bool _animations = true;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService.init();
  }

  Future<void> _toggleSleep(bool v) async {
    setState(() => _notifSleep = v);
    if (v) {
      await NotificationService.scheduleDaily(
        id: NotificationService.idSleep,
        hour: 21,
        minute: 30,
        title: 'SOMA',
        body: 'Saatnya persiapan tidur 😴',
      );
    } else {
      await NotificationService.cancel(NotificationService.idSleep);
    }
  }

  Future<void> _toggleFocus(bool v) async {
    setState(() => _notifFocus = v);
    if (v) {
      await NotificationService.scheduleDaily(
        id: NotificationService.idFocus,
        hour: 8,
        minute: 0,
        title: 'SOMA',
        body: 'Waktunya sesi fokus 🎯',
      );
    } else {
      await NotificationService.cancel(NotificationService.idFocus);
    }
  }

  Future<void> _toggleMemory(bool v) async {
    setState(() => _notifMemory = v);
    if (v) {
      await NotificationService.scheduleDaily(
        id: NotificationService.idMemory,
        hour: 15,
        minute: 0,
        title: 'SOMA',
        body: 'Latihan memory 🧩',
      );
    } else {
      await NotificationService.cancel(NotificationService.idMemory);
    }
  }

  Future<void> _toggleLearn(bool v) async {
    setState(() => _notifLearn = v);
    if (v) {
      await NotificationService.scheduleDaily(
        id: NotificationService.idLearn,
        hour: 20,
        minute: 0,
        title: 'SOMA',
        body: 'Waktu belajar 📖',
      );
    } else {
      await NotificationService.cancel(NotificationService.idLearn);
    }
  }

  Future<void> _toggleBreathing(bool v) async {
    setState(() => _notifBreathing = v);
    if (v) {
      await NotificationService.scheduleDaily(
        id: NotificationService.idBreathing,
        hour: 6,
        minute: 0,
        title: 'SOMA',
        body: 'Breathing exercise pagi 🌬️',
      );
    } else {
      await NotificationService.cancel(NotificationService.idBreathing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings',
            style: TextStyle(
                color: SomaTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        // Profile
        _buildSection('Profil', [
          _buildProfileRow('Nama', _name, Icons.person),
          _buildProfileRow('Email', _email, Icons.email),
        ]),
        const SizedBox(height: 16),
        // Target Personal
        _buildSection('Target Personal', [
          _buildSliderRow('Target Jam Tidur', _targetSleep, 4, 12,
              '${_targetSleep.toStringAsFixed(1)} jam'),
          _buildSliderRow('Target Sesi Fokus', _targetFocus.toDouble(), 1, 10,
              '$_targetFocus sesi/hari',
              intValue: true),
          _buildSliderRow('Target Memory Game', _targetMemory.toDouble(), 1, 10,
              '$_targetMemory game/hari',
              intValue: true),
          _buildSliderRow('Target Belajar', _targetLearn.toDouble(), 10, 120,
              '$_targetLearn min/hari',
              intValue: true),
        ]),
        const SizedBox(height: 16),
        // Notifications
        _buildSection('Notifikasi', [
          _buildToggleRow('Pengingat Tidur (21:30)', _notifSleep, _toggleSleep),
          _buildToggleRow('Pengingat Fokus (08:00)', _notifFocus, _toggleFocus),
          _buildToggleRow(
              'Pengingat Memory (15:00)', _notifMemory, _toggleMemory),
          _buildToggleRow(
              'Pengingat Belajar (20:00)', _notifLearn, _toggleLearn),
          _buildToggleRow('Pengingat Breathing (06:00)', _notifBreathing,
              _toggleBreathing),
          _buildToggleRow(
              'Suara Notifikasi', _notifSound, (v) => setState(() => _notifSound = v)),
        ]),
        const SizedBox(height: 16),
        // Preferences
        _buildSection('Preferensi', [
          _buildToggleRow(
              'Dark Mode', _darkMode, (v) => setState(() => _darkMode = v)),
          _buildToggleRow(
              'Animasi', _animations, (v) => setState(() => _animations = v)),
        ]),
        const SizedBox(height: 16),
        // Danger Zone
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SomaTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Danger Zone',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text('Reset semua progress dan data SOMA',
                  style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: SomaTheme.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: SomaTheme.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                Text(value, style: TextStyle(color: SomaTheme.text, fontSize: 15)),
              ],
            ),
          ),
          Icon(Icons.edit, color: SomaTheme.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max,
      String display,
      {bool intValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: SomaTheme.text, fontSize: 14)),
              Text(display,
                  style: TextStyle(
                      color: SomaTheme.tealBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: intValue ? (max - min).toInt() : ((max - min) * 2).toInt(),
            onChanged: (v) {
              setState(() {
                if (label.contains('Jam Tidur'))
                  _targetSleep = v;
                else if (label.contains('Fokus'))
                  _targetFocus = v.round();
                else if (label.contains('Memory'))
                  _targetMemory = v.round();
                else if (label.contains('Belajar')) _targetLearn = v.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: SomaTheme.text, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: SomaTheme.teal,
            inactiveTrackColor: SomaTheme.bgDeep,
          ),
        ],
      ),
    );
  }
}