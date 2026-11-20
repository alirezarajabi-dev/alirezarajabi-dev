import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records and plays the family's own voice messages.
///
/// Recordings are saved as WAV (16-bit PCM) because iPhone can then use the
/// same file as the notification sound. iOS only plays custom notification
/// sounds that sit in `Library/Sounds` and last under 30 seconds, so the
/// recording is capped at [maxSeconds].
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  static const maxSeconds = 25;

  /// Turned off in tests, where there is no microphone or speaker.
  bool enabled = true;

  late final _recorder = AudioRecorder();
  late final _player = AudioPlayer();

  Future<Directory> _dir() async {
    final Directory base = Platform.isIOS
        ? Directory('${(await getLibraryDirectory()).path}/Sounds')
        : await getApplicationDocumentsDirectory();
    if (!await base.exists()) await base.create(recursive: true);
    return base;
  }

  Future<String> pathOf(String file) async => '${(await _dir()).path}/$file';

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording; returns the new file name, or null without permission.
  Future<String?> start(String prefix) async {
    if (!await _recorder.hasPermission()) return null;
    await stopPlaying();
    final file = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 22050,
        numChannels: 1,
      ),
      path: await pathOf(file),
    );
    return file;
  }

  Future<void> stop() async {
    await _recorder.stop();
  }

  Future<void> cancel() async {
    await _recorder.cancel();
  }

  Future<void> delete(String? file) async {
    if (!enabled || file == null) return;
    final f = File(await pathOf(file));
    if (await f.exists()) await f.delete();
  }

  /// Plays [file] loudly through the speaker, even if the phone is on silent.
  Future<void> play(String? file) async {
    if (!enabled || file == null) return;
    final path = await pathOf(file);
    if (!await File(path).exists()) return;
    await _player.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.duckOthers},
      ),
      android: const AudioContextAndroid(
        usageType: AndroidUsageType.alarm,
        contentType: AndroidContentType.speech,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlaying() async {
    if (enabled) await _player.stop();
  }
}
