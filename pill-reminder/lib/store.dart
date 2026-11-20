import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Everything the app remembers, kept on the phone only (no account, no
/// internet). Listeners are told whenever something changes.
class Store extends ChangeNotifier {
  Store(this._prefs) {
    _load();
  }

  static Future<Store> open() async =>
      Store(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  final List<Pill> pills = [];

  /// Keys of the form `pillId@yyyy-mm-dd` for every dose marked as taken.
  final Set<String> _taken = {};

  /// Name the parent is called in the reminder, e.g. «مادر جان».
  String parentTitle = '';

  /// File name of the general family voice message, if recorded.
  String? familyVoiceFile;

  void _load() {
    final raw = _prefs.getString('pills');
    if (raw != null) {
      pills
        ..clear()
        ..addAll((jsonDecode(raw) as List)
            .map((e) => Pill.fromJson(e as Map<String, dynamic>)));
    }
    _taken
      ..clear()
      ..addAll(_prefs.getStringList('taken') ?? const []);
    parentTitle = _prefs.getString('parentTitle') ?? '';
    familyVoiceFile = _prefs.getString('familyVoice');
    _sort();
  }

  Future<void> _save() async {
    await _prefs.setString(
        'pills', jsonEncode(pills.map((p) => p.toJson()).toList()));
    await _prefs.setStringList('taken', _taken.toList());
    await _prefs.setString('parentTitle', parentTitle);
    if (familyVoiceFile == null) {
      await _prefs.remove('familyVoice');
    } else {
      await _prefs.setString('familyVoice', familyVoiceFile!);
    }
    notifyListeners();
  }

  void _sort() => pills.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));

  Pill? pillById(int id) {
    for (final p in pills) {
      if (p.id == id) return p;
    }
    return null;
  }

  int nextPillId() {
    var max = 0;
    for (final p in pills) {
      if (p.id > max) max = p.id;
    }
    return max + 1;
  }

  Future<void> savePill(Pill pill) async {
    final i = pills.indexWhere((p) => p.id == pill.id);
    if (i >= 0) {
      pills[i] = pill;
    } else {
      pills.add(pill);
    }
    _sort();
    await _save();
  }

  Future<void> deletePill(int id) async {
    pills.removeWhere((p) => p.id == id);
    _taken.removeWhere((k) => k.startsWith('$id@'));
    await _save();
  }

  bool isTaken(int pillId, DateTime day) => _taken.contains('$pillId@${dayKey(day)}');

  Future<void> markTaken(int pillId, DateTime day) async {
    _taken.add('$pillId@${dayKey(day)}');
    // Keep only the last few weeks so the list never grows without limit.
    final cutoff = dayKey(day.subtract(const Duration(days: 30)));
    _taken.removeWhere((k) => k.split('@').last.compareTo(cutoff) < 0);
    await _save();
  }

  Future<void> unmarkTaken(int pillId, DateTime day) async {
    _taken.remove('$pillId@${dayKey(day)}');
    await _save();
  }

  Future<void> setParentTitle(String value) async {
    parentTitle = value.trim();
    await _save();
  }

  Future<void> setFamilyVoice(String? file) async {
    familyVoiceFile = file;
    await _save();
  }

  /// The voice file to play for [pill]: its own recording, else the family one.
  String? voiceFor(Pill pill) => pill.voiceFile ?? familyVoiceFile;
}
