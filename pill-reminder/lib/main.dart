import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'reminders.dart';
import 'screens/home_screen.dart';
import 'screens/reminder_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.open();
  final launchTap = await Reminders.instance.init();
  runApp(PillApp(store: store, launchTap: launchTap, scheduling: true));
}

class PillApp extends StatefulWidget {
  const PillApp({
    super.key,
    required this.store,
    this.launchTap,
    this.scheduling = false,
    this.clock = DateTime.now,
  });

  final Store store;
  final ReminderTap? launchTap;

  /// False in tests, where there is no phone to schedule reminders on.
  final bool scheduling;
  final DateTime Function() clock;

  @override
  State<PillApp> createState() => _PillAppState();
}

class _PillAppState extends State<PillApp> with WidgetsBindingObserver {
  final _nav = GlobalKey<NavigatorState>();
  Timer? _tick;

  /// `pillId@day` of reminder screens already opened, so each one opens once.
  final _opened = <String>{};
  bool _showing = false;

  Store get store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.scheduling) {
      Reminders.instance.taps.addListener(_onTap);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Reminders.instance.requestPermissions();
        await Reminders.instance.rescheduleAll(store);
      });
    }
    if (widget.launchTap != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(widget.launchTap!));
    }
    // While the app is open, show the reminder page by itself at dose time.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => _checkDue());
  }

  @override
  void dispose() {
    _tick?.cancel();
    Reminders.instance.taps.removeListener(_onTap);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {}); // refresh "now" on the home screen
      if (widget.scheduling) Reminders.instance.rescheduleAll(store);
      _checkDue();
    }
  }

  void _onTap() {
    final tap = Reminders.instance.taps.value;
    if (tap != null) _open(tap);
  }

  void _checkDue() {
    final now = widget.clock();
    final nowMin = now.hour * 60 + now.minute;
    final today = DateTime(now.year, now.month, now.day);
    for (final p in store.pills) {
      final late = nowMin - p.minutesOfDay;
      if (late >= 0 && late <= 30 && !store.isTaken(p.id, today)) {
        _open(ReminderTap(p.id, today), auto: true);
        return;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _open(ReminderTap tap, {bool auto = false}) async {
    final pill = store.pillById(tap.pillId);
    if (pill == null || _showing) return;
    final day = tap.day ?? doseDayFor(pill, widget.clock());
    if (store.isTaken(pill.id, day)) return;
    final key = '${pill.id}@${dayKey(day)}';
    // The automatic check opens each dose once; a tapped reminder always opens.
    if (auto && _opened.contains(key)) return;
    _opened.add(key);
    final nav = _nav.currentState;
    if (nav == null) return;
    _showing = true;
    await nav.push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ReminderScreen(store: store, pill: pill, day: day),
    ));
    _showing = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _nav,
      title: 'یادآور قرص',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        // Respect the phone's own text size, but never make it smaller.
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.6),
        ),
        child: child!,
      ),
      home: HomeScreen(store: store, now: widget.clock),
    );
  }
}
