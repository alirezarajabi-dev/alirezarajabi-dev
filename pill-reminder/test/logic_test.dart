import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder/models.dart';
import 'package:pill_reminder/persian.dart';
import 'package:pill_reminder/reminders.dart';
import 'package:pill_reminder/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Persian digits and friendly times', () {
    expect(faDigits('08:30'), '۰۸:۳۰');
    expect(timeLabel(8, 0), '۸ صبح');
    expect(timeLabel(13, 0), '۱ ظهر');
    expect(timeLabel(17, 30), '۵:۳۰ عصر');
    expect(timeLabel(21, 0), '۹ شب');
    expect(timeLabel(0, 15), '۱۲:۱۵ شب');
  });

  test('a dose opened after midnight belongs to the evening before', () {
    final pill = Pill(id: 1, name: 'x', hour: 22, minute: 0);
    expect(doseDayFor(pill, DateTime(2026, 5, 2, 0, 30)), DateTime(2026, 5, 1));
    expect(doseDayFor(pill, DateTime(2026, 5, 2, 22, 10)), DateTime(2026, 5, 2));
    // Slightly early still counts as today.
    expect(doseDayFor(pill, DateTime(2026, 5, 2, 21, 30)), DateTime(2026, 5, 2));
  });

  test('notification payloads round-trip', () {
    final t = ReminderTap.parse('3|2026-05-01')!;
    expect(t.pillId, 3);
    expect(t.day, DateTime(2026, 5, 1));
    expect(ReminderTap.parse('7')!.day, isNull);
    expect(ReminderTap.parse(''), isNull);
  });

  test('store saves pills sorted by time and remembers doses', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await Store.open();
    await store.savePill(Pill(id: store.nextPillId(), name: 'شب', hour: 21, minute: 0));
    await store.savePill(Pill(id: store.nextPillId(), name: 'صبح', hour: 8, minute: 0));
    expect(store.pills.map((p) => p.name), ['صبح', 'شب']);

    final day = DateTime.now();
    await store.markTaken(1, day);
    expect(store.isTaken(1, day), isTrue);
    expect(store.isTaken(2, day), isFalse);

    final reopened = await Store.open();
    expect(reopened.pills.length, 2);
    expect(reopened.isTaken(1, day), isTrue);

    await reopened.deletePill(1);
    expect(reopened.isTaken(1, day), isFalse);
  });

  test('per-pill voice wins over the family voice', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await Store.open();
    await store.setFamilyVoice('family.wav');
    final a = Pill(id: 1, name: 'a', hour: 8, minute: 0);
    final b = Pill(id: 2, name: 'b', hour: 9, minute: 0, voiceFile: 'b.wav');
    expect(store.voiceFor(a), 'family.wav');
    expect(store.voiceFor(b), 'b.wav');
  });
}
