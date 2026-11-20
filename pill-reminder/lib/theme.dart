import 'package:material_ui/material_ui.dart';

/// Colours and sizes chosen for older eyes: large type, strong contrast,
/// big touch targets.
class AppColors {
  static const background = Color(0xFFFFF8EC);
  static const ink = Color(0xFF1B1B1B);
  static const muted = Color(0xFF55524B);
  static const card = Colors.white;
  static const primary = Color(0xFF0B6E69);
  static const taken = Color(0xFF1E7B34);
  static const due = Color(0xFFC25100);
  static const danger = Color(0xFFB3261E);
  static const alert = Color(0xFFFFD54F);
}

ThemeData buildTheme() {
  const font = 'Vazirmatn';
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: font,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .copyWith(
          displayLarge: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, height: 1.3),
          headlineLarge: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, height: 1.35),
          headlineMedium: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, height: 1.4),
          titleLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.4),
          bodyLarge: const TextStyle(fontSize: 24, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 22, height: 1.5),
          labelLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        )
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink, fontFamily: font),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      centerTitle: true,
      toolbarHeight: 72,
      titleTextStyle: TextStyle(
          fontFamily: font, fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.ink),
      iconTheme: IconThemeData(size: 34),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(76),
        textStyle: const TextStyle(fontFamily: font, fontSize: 26, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(68),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 2),
        textStyle: const TextStyle(fontFamily: font, fontSize: 24, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      labelStyle: const TextStyle(fontSize: 22),
      hintStyle: const TextStyle(fontSize: 22, color: AppColors.muted),
    ),
  );
}
