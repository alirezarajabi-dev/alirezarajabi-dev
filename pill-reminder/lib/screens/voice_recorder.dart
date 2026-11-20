import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../persian.dart';
import '../theme.dart';
import '../voice.dart';

/// Record / play / delete one voice message. Reports the new file name (or
/// null when deleted) through [onChanged].
class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({
    super.key,
    required this.file,
    required this.prefix,
    required this.onChanged,
    this.hint,
  });

  final String? file;
  final String prefix;
  final String? hint;
  final ValueChanged<String?> onChanged;

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  String? _recording;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    if (_recording != null) Voice.instance.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final file = await Voice.instance.start(widget.prefix);
    if (file == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('برای ضبط صدا، اجازهٔ میکروفون را در تنظیمات گوشی بدهید.',
            style: TextStyle(fontSize: 20)),
      ));
      return;
    }
    setState(() {
      _recording = file;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= Voice.maxSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final file = _recording;
    if (file == null) return;
    await Voice.instance.stop();
    setState(() => _recording = null);
    final old = widget.file;
    widget.onChanged(file);
    if (old != null && old != file) await Voice.instance.delete(old);
  }

  Future<void> _delete() async {
    final old = widget.file;
    widget.onChanged(null);
    await Voice.instance.delete(old);
  }

  @override
  Widget build(BuildContext context) {
    final recording = _recording != null;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.hint != null) ...[
              Text(widget.hint!, style: const TextStyle(fontSize: 20, color: AppColors.muted)),
              const SizedBox(height: 12),
            ],
            if (recording) ...[
              Text(
                'در حال ضبط… ${faDigits(Voice.maxSeconds - _seconds)} ثانیه',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _stop,
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                icon: const Icon(Icons.stop_rounded, size: 36),
                label: const Text('پایان ضبط'),
              ),
            ] else ...[
              if (widget.file != null) ...[
                const Text('✓ صدا ضبط شده است',
                    style: TextStyle(fontSize: 22, color: AppColors.taken, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Voice.instance.play(widget.file),
                      icon: const Icon(Icons.play_arrow_rounded, size: 34),
                      label: const Text('پخش'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 30),
                      label: const Text('حذف'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.mic_rounded, size: 36),
                label: Text(widget.file == null ? 'ضبط صدا' : 'ضبط دوباره'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
