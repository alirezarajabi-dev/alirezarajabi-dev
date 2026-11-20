import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pill_reminder/main.dart';
import 'package:pill_reminder/models.dart';
import 'package:pill_reminder/reminders.dart';
import 'package:pill_reminder/store.dart';
import 'package:pill_reminder/voice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Reminders.instance.enabled = false;
    Voice.instance.enabled = false;
  });

  Future<Store> storeWith(List<Pill> pills, {String title = ''}) async {
    SharedPreferences.setMockInitialValues({});
    final s = await Store.open();
    for (final p in pills) {
      await s.savePill(p);
    }
    await s.setParentTitle(title);
    return s;
  }

  Future<void> pumpApp(WidgetTester tester, Store store, DateTime now) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PillApp(store: store, clock: () => now));
    await tester.pump();
  }

  testWidgets('first run invites the family to add pills, and adding works',
      (tester) async {
    final store = await storeWith([]);
    await pumpApp(tester, store, DateTime(2026, 5, 1, 7, 0));

    expect(find.text('هنوز قرصی ثبت نشده است.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn-first-setup')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(const Key('btn-add-pill')), 200, scrollable: _pageScroll());
    await tester.ensureVisible(find.byKey(const Key('btn-add-pill')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-add-pill')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pill-name')), 'متفورمین');
    await tester.tap(find.text('۹ شب'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('pill-time'))).data, '۹ شب');
    await tester.scrollUntilVisible(find.byKey(const Key('btn-save')), 200, scrollable: _pageScroll());
    await tester.ensureVisible(find.byKey(const Key('btn-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-save')));
    await tester.pumpAndSettle();

    expect(store.pills.single.name, 'متفورمین');
    expect(store.pills.single.hour, 21);
  });

  testWidgets('home shows a due pill and «خوردم» marks it taken', (tester) async {
    final store = await storeWith(
        [Pill(id: 1, name: 'قرص فشار', hour: 8, minute: 0)],
        title: 'مادر جان');
    // 45 minutes late: past the automatic pop-up window, so the home list shows.
    await pumpApp(tester, store, DateTime(2026, 5, 1, 8, 45));

    expect(find.text('سلام مادر جان'), findsOneWidget);
    expect(find.text('وقتش است — هنوز نخورده‌اید'), findsOneWidget);
    await tester.tap(find.text('خوردم'));
    await tester.pumpAndSettle();
    expect(find.text('✓ خورده شد'), findsOneWidget);
    expect(store.isTaken(1, DateTime(2026, 5, 1)), isTrue);
  });

  testWidgets('a tapped reminder opens the big reminder page', (tester) async {
    final store = await storeWith([Pill(id: 4, name: 'آسپرین', hour: 21, minute: 0)],
        title: 'بابا جان');
    final now = DateTime(2026, 5, 1, 21, 2);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PillApp(
        store: store, clock: () => now, launchTap: ReminderTap.parse('4|2026-05-01')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-pill-name')), findsOneWidget);
    expect(find.text('بابا جان'), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn-taken')));
    await tester.pumpAndSettle();
    expect(store.isTaken(4, DateTime(2026, 5, 1)), isTrue);
    expect(find.byKey(const Key('reminder-pill-name')), findsNothing);
  });
}

/// The scroll view of the page on top (not the one underneath, nor a text field's).
Finder _pageScroll() => find
    .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
    .first;
