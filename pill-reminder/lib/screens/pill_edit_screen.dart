import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../persian.dart';
import '../reminders.dart';
import '../store.dart';
import '../theme.dart';
import '../voice.dart';
import 'voice_recorder.dart';

/// Add or change one pill: its name, its time and (optionally) its own voice.
class PillEditScreen extends StatefulWidget {
  const PillEditScreen({super.key, required this.store, this.pill});

  final Store store;
  final Pill? pill;

  @override
  State<PillEditScreen> createState() => _PillEditScreenState();
}

class _PillEditScreenState extends State<PillEditScreen> {
  late final TextEditingController _name;
  late int _hour;
  late int _minute;
  String? _voice;

  static const _quick = [(8, 0), (14, 0), (21, 0)];

  @override
  void initState() {
    super.initState();
    final p = widget.pill;
    _name = TextEditingController(text: p?.name ?? '');
    _hour = p?.hour ?? 8;
    _minute = p?.minute ?? 0;
    _voice = p?.voiceFile;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addMinutes(int delta) {
    final total = (_hour * 60 + _minute + delta) % (24 * 60);
    setState(() {
      _hour = total ~/ 60;
      _minute = total % 60;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('لطفاً اسم قرص را بنویسید', style: TextStyle(fontSize: 22)),
      ));
      return;
    }
    final pill = Pill(
      id: widget.pill?.id ?? widget.store.nextPillId(),
      name: name,
      hour: _hour,
      minute: _minute,
      voiceFile: _voice,
    );
    final old = widget.pill?.voiceFile;
    if (old != null && old != _voice) await Voice.instance.delete(old);
    await widget.store.savePill(pill);
    await Reminders.instance.rescheduleAll(widget.store);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final p = widget.pill;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('قرص «${p.name}» پاک شود؟', style: const TextStyle(fontSize: 26)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('نه', style: TextStyle(fontSize: 24))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('بله، پاک کن',
                  style: TextStyle(fontSize: 24, color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    await Voice.instance.delete(p.voiceFile);
    await widget.store.deletePill(p.id);
    await Reminders.instance.rescheduleAll(widget.store);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _stepButton(String label, VoidCallback onTap) => Expanded(
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(68),
              padding: const EdgeInsets.symmetric(horizontal: 4)),
          child: Text(label,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.pill == null ? 'قرص تازه' : 'تغییر قرص')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('۱. اسم قرص', style: t.titleLarge),
            const SizedBox(height: 8),
            TextField(
              key: const Key('pill-name'),
              controller: _name,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'مثلاً: قرص فشار'),
            ),
            const SizedBox(height: 28),
            Text('۲. ساعت خوردن', style: t.titleLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Column(children: [
                Text(timeLabel(_hour, _minute),
                    key: const Key('pill-time'),
                    style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
                Text(clockLabel(_hour, _minute),
                    style: const TextStyle(fontSize: 22, color: AppColors.muted)),
                const SizedBox(height: 12),
                Row(children: [
                  _stepButton('+ ۱ ساعت', () => _addMinutes(60)),
                  const SizedBox(width: 10),
                  _stepButton('+ ۱۵ دقیقه', () => _addMinutes(15)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _stepButton('− ۱ ساعت', () => _addMinutes(-60)),
                  const SizedBox(width: 10),
                  _stepButton('− ۱۵ دقیقه', () => _addMinutes(-15)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final (h, m) in _quick)
                  ActionChip(
                    label: Text(timeLabel(h, m), style: const TextStyle(fontSize: 22)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: () => setState(() {
                      _hour = h;
                      _minute = m;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text('۳. صدای مخصوص این قرص (دلخواه)', style: t.titleLarge),
            const SizedBox(height: 8),
            VoiceRecorder(
              file: _voice,
              prefix: 'pill',
              hint: _voice == null && widget.store.familyVoiceFile != null
                  ? 'اگر ضبط نکنید، همان صدای عمومی خانواده پخش می‌شود.'
                  : 'مثلاً: «مادر جان، وقت قرص فشارتونه، با یک لیوان آب»',
              onChanged: (f) => setState(() => _voice = f),
            ),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('btn-save'),
              onPressed: _save,
              child: const Text('ذخیره'),
            ),
            if (widget.pill != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _delete,
                child: const Text('پاک کردن این قرص',
                    style: TextStyle(fontSize: 22, color: AppColors.danger)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
