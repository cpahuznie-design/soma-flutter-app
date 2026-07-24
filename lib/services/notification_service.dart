import 'dart:async';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final Map<String, Timer> _timers = {};
  final Map<String, bool> _enabled = {};

  static final _reminders = {
    'sleep':     {'hour': 21, 'minute': 30, 'title': '😴 Saatnya Persiapan Tidur', 'body': 'Matikan gadget, lakukan breathing exercise, baca doa tidur.'},
    'focus':     {'hour': 8,  'minute': 0,  'title': '🎯 Waktunya Sesi Fokus', 'body': 'Mulai Pomodoro 25 menit. Aktifkan brown noise untuk deep focus.'},
    'memory':    {'hour': 15, 'minute': 0,  'title': '🧩 Latihan Memory', 'body': 'Main memory game 10 menit untuk latih hippocampus.'},
    'learn':     {'hour': 20, 'minute': 0,  'title': '📖 Waktu Belajar', 'body': 'Buka Learning Assistant, pelajari materi baru 25 menit.'},
    'breathing': {'hour': 6,  'minute': 0,  'title': '🌬️ Breathing Exercise Pagi', 'body': 'Mulai hari dengan 4-7-8 breathing. 4 siklus untuk tenangkan pikiran.'},
  };

  static NotificationService get instance => _instance;

  static void init() {
    final inst = _instance;
    _reminders.forEach((key, r) {
      inst._enabled[key] = true;
      _scheduleReminder(key, r['hour'] as int, r['minute'] as int,
        r['title'] as String, r['body'] as String);
    });
  }

  static void _scheduleReminder(String key, int hour, int minute, String title, String body) {
    final inst = _instance;
    inst._timers[key]?.cancel();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final delay = scheduled.difference(now);

    inst._timers[key] = Timer(delay, () {
      if (inst._enabled[key] ?? false) {
        _showReminder(title, body);
      }
      _scheduleReminder(key, hour, minute, title, body);
    });
  }

  static void _showReminder(String title, String body) {
    // In production: use flutter_local_notifications or awesome_notifications
    // For now: log to console (works on all platforms)
    debugPrint('🔔 SOMA Reminder: $title — $body');
  }

  static void toggleReminder(String key, bool enabled) {
    final inst = _instance;
    inst._enabled[key] = enabled;
    if (!enabled) {
      inst._timers[key]?.cancel();
    } else {
      final r = _reminders[key];
      if (r != null) {
        _scheduleReminder(key, r['hour'] as int, r['minute'] as int,
          r['title'] as String, r['body'] as String);
      }
    }
  }

  static bool isEnabled(String key) => _instance._enabled[key] ?? false;

  static void cancelAll() {
    final inst = _instance;
    inst._timers.forEach((_, t) => t.cancel());
    inst._timers.clear();
    inst._enabled.forEach((k, _) => inst._enabled[k] = false);
  }

  static Map<String, Map<String, dynamic>> get reminders => _reminders;
}