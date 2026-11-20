import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../persian.dart';
import '../reminders.dart';
import '../store.dart';
import '../theme.dart';
import 'settings_screen.dart';

const _weekdays = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه', 'یکشنبه'];

/// What the parent sees every day: today's pills, each clearly marked as
/// taken, due now, or later today.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.now});

  final Store store;

  /// Injected so the screen can be tested at any time of day.
  final DateTime Function() now;

  void _openSettings(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => SettingsScreen(store: store)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final n = now();
        final who = store.parentTitle;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              children: [
                Text(who.isEmpty ? 'سلام' : 'سلام $who', style: t.headlineLarge),
                Text('امروز ${_weekdays[n.weekday - 1]} · ساعت ${clockLabel(n.hour, n.minute)}',
                    style: t.bodyLarge?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 20),
                if (store.pills.isEmpty) ...[
                  Text('هنوز قرصی ثبت نشده است.', style: t.titleLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('btn-first-setup'),
                    onPressed: () => _openSettings(context),
                    child: const Text('ثبت قرص‌ها'),
                  ),
                ] else
                  for (final p in store.pills) _PillCard(store: store, pill: p, now: n),
                const SizedBox(height: 32),
                if (store.pills.isNotEmpty)
                  Center(
                    child: GestureDetector(
                      key: const Key('settings-hold'),
                      onLongPress: () => _openSettings(context),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('تنظیمات (برای فرزند: انگشت را نگه دارید)',
                            style: TextStyle(fontSize: 17, color: AppColors.muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PillCard extends StatelessWidget {
  const _PillCard({required this.store, required this.pill, required this.now});

  final Store store;
  final Pill pill;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final taken = store.isTaken(pill.id, today);
    final nowMin = now.hour * 60 + now.minute;
    final due = !taken && nowMin >= pill.minutesOfDay;
    // Up to an hour early the parent may still mark it; otherwise no button,
    // so a later pill cannot be ticked off by mistake.
    final canMark = !taken && nowMin >= pill.minutesOfDay - 60;
    final color = taken ? AppColors.taken : (due ? AppColors.due : AppColors.muted);
    final status = taken ? '✓ خورده شد' : (due ? 'وقتش است — هنوز نخورده‌اید' : 'هنوز وقتش نشده');

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: color, width: due ? 4 : 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(pill.name,
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              ),
              Text(timeLabel(pill.hour, pill.minute),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 6),
            Text(status,
                style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
            if (canMark) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await store.markTaken(pill.id, today);
                  await Reminders.instance.doseTaken(store, pill);
                },
                style: FilledButton.styleFrom(
                    backgroundColor: due ? AppColors.taken : AppColors.primary),
                icon: const Icon(Icons.check_rounded, size: 34),
                label: const Text('خوردم'),
              ),
            ] else if (taken)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => store.unmarkTaken(pill.id, today),
                  child: const Text('اشتباه زدم', style: TextStyle(fontSize: 19)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
