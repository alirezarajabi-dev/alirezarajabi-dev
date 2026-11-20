import 'package:material_ui/material_ui.dart';

import '../persian.dart';
import '../reminders.dart';
import '../store.dart';
import '../theme.dart';
import 'pill_edit_screen.dart';
import 'voice_recorder.dart';

/// Set-up page meant for the son or daughter. Opened with a long press from
/// the home screen so it is not entered by accident.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final Store store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _title =
      TextEditingController(text: widget.store.parentTitle);

  static const _titles = ['مادر جان', 'بابا جان', 'مامان', 'بابا'];

  @override
  void dispose() {
    _title.dispose();
    // The title appears in every reminder, so rebuild them once on leaving.
    Reminders.instance.rescheduleAll(widget.store);
    super.dispose();
  }

  Future<void> _setTitle(String v) => widget.store.setParentTitle(v);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('تنظیمات')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('پدر یا مادر را چه صدا می‌زنید؟', style: t.titleLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                style: const TextStyle(fontSize: 26),
                decoration: const InputDecoration(hintText: 'مثلاً: مادر جان'),
                onChanged: _setTitle,
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in _titles)
                  ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 20)),
                    onPressed: () {
                      _title.text = s;
                      _setTitle(s);
                    },
                  ),
              ]),
              const SizedBox(height: 28),
              Text('صدای شما برای یادآوری', style: t.titleLarge),
              const SizedBox(height: 8),
              VoiceRecorder(
                file: store.familyVoiceFile,
                prefix: 'family',
                hint: 'با صدای خودتان بگویید، مثلاً: «سلام مادر جان، موقع قرصتونه. '
                    'مراقب خودتون باشید و یادتون نره.» (حداکثر ۲۵ ثانیه)',
                onChanged: (f) async {
                  await store.setFamilyVoice(f);
                  await Reminders.instance.rescheduleAll(store);
                },
              ),
              const SizedBox(height: 28),
              Text('قرص‌ها', style: t.titleLarge),
              const SizedBox(height: 8),
              for (final p in store.pills)
                Card(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(p.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${timeLabel(p.hour, p.minute)}${p.voiceFile != null ? ' · صدای مخصوص' : ''}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    trailing: const Icon(Icons.edit_rounded, size: 30),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PillEditScreen(store: store, pill: p))),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('btn-add-pill'),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PillEditScreen(store: store))),
                icon: const Icon(Icons.add_rounded, size: 36),
                label: const Text('افزودن قرص'),
              ),
              const SizedBox(height: 28),
              Text('امتحان و اجازه‌ها', style: t.titleLarge),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await Reminders.instance.requestPermissions();
                  await Reminders.instance.rescheduleAll(store);
                },
                child: const Text('دادن اجازهٔ یادآوری'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: store.pills.isEmpty
                    ? null
                    : () async {
                        await Reminders.instance.test(store, store.pills.first);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('۵ ثانیهٔ دیگر یک یادآوری آزمایشی می‌آید. '
                              'گوشی را قفل کنید تا ببینید.',
                              style: TextStyle(fontSize: 20)),
                        ));
                      },
                child: const Text('یادآوری آزمایشی'),
              ),
              const SizedBox(height: 16),
              const Text(
                'نکته: در آیفون، اگر دکمهٔ بی‌صدا (کنار گوشی) روشن باشد، صدای یادآوری '
                'پخش نمی‌شود. آن را خاموش نگه دارید و صدای زنگ را زیاد کنید.',
                style: TextStyle(fontSize: 19, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
