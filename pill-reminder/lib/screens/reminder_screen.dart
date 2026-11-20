import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../persian.dart';
import '../reminders.dart';
import '../store.dart';
import '../theme.dart';
import '../voice.dart';

/// The full-screen «موقع قرص» page. Plays the family's voice as soon as it
/// opens and offers just two large choices.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key, required this.store, required this.pill, required this.day});

  final Store store;
  final Pill pill;
  final DateTime day;

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    Voice.instance.stopPlaying();
    super.dispose();
  }

  Future<void> _play() => Voice.instance.play(widget.store.voiceFor(widget.pill));

  Future<void> _taken() async {
    await Voice.instance.stopPlaying();
    await widget.store.markTaken(widget.pill.id, widget.day);
    await Reminders.instance.doseTaken(widget.store, widget.pill);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('آفرین! ثبت شد ✓', style: TextStyle(fontSize: 26)),
      backgroundColor: AppColors.taken,
    ));
  }

  Future<void> _later() async {
    await Voice.instance.stopPlaying();
    await Reminders.instance.snooze(widget.store, widget.pill, widget.day);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${faDigits(snoozeMinutes)} دقیقهٔ دیگر دوباره یادآوری می‌کنم',
          style: const TextStyle(fontSize: 24)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final who = widget.store.parentTitle;
    final hasVoice = widget.store.voiceFor(widget.pill) != null;
    return Scaffold(
      backgroundColor: AppColors.alert,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.medication_rounded, size: 110, color: AppColors.ink),
              if (who.isNotEmpty)
                Text(who, textAlign: TextAlign.center, style: t.headlineMedium),
              Text('موقع خوردن قرص است', textAlign: TextAlign.center, style: t.headlineLarge),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.ink, width: 3),
                ),
                child: Column(children: [
                  Text(widget.pill.name,
                      key: const Key('reminder-pill-name'),
                      textAlign: TextAlign.center,
                      style: t.displayLarge),
                  Text('ساعت ${timeLabel(widget.pill.hour, widget.pill.minute)}',
                      textAlign: TextAlign.center, style: t.titleLarge),
                ]),
              ),
              const Spacer(),
              if (hasVoice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: _play,
                    icon: const Icon(Icons.volume_up_rounded, size: 34),
                    label: const Text('دوباره گوش بده'),
                  ),
                ),
              FilledButton.icon(
                key: const Key('btn-taken'),
                onPressed: _taken,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.taken,
                  minimumSize: const Size.fromHeight(110),
                  textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 36, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 48),
                label: const Text('خوردم'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _later,
                child: Text('بعداً یادم بنداز (${faDigits(snoozeMinutes)} دقیقه)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
