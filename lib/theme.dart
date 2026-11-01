// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Colours from DESIGN.md. The dark values are our own additions.
class EventColors {
  static const red = Color(0xFFB71920);
  static const maroon = Color(0xFF7F0C11);
  static const gold = Color(0xFFE6B662);
  static const cream = Color(0xFFFFF9F3);
  static const ink = Color(0xFF301B1A);
  static const muted = Color(0xFF77615B);
  static const border = Color(0xFFE8D9CF);
  static const paleRose = Color(0xFFF1D1CD);
  static const placeholder = Color(0xFF9F8E86);

  // Dark mode counterparts.
  static const darkBackground = Color(0xFF15100F);
  static const darkSurface = Color(0xFF221917);
  static const darkElevated = Color(0xFF2E2320);
  static const darkBorder = Color(0xFF4A3733);
  static const darkMuted = Color(0xFFB9A49D);
  static const darkPrimary = Color(0xFFE2454B);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: EventColors.red).copyWith(
      primary: EventColors.red,
      onPrimary: Colors.white,
      secondary: EventColors.gold,
      onSecondary: EventColors.ink,
      surface: EventColors.cream,
      onSurface: EventColors.ink,
      outline: EventColors.border,
      surfaceContainerHighest: EventColors.paleRose,
    );

    return _build(
      scheme: scheme,
      background: EventColors.cream,
      surface: Colors.white,
      fieldFill: Colors.white,
      fieldBorder: EventColors.border,
      appBarColor: EventColors.maroon,
      appBarText: Colors.white,
      linkColor: EventColors.maroon,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: EventColors.red,
      brightness: Brightness.dark,
    ).copyWith(
      primary: EventColors.darkPrimary,
      onPrimary: EventColors.ink,
      secondary: EventColors.gold,
      onSecondary: EventColors.ink,
      surface: EventColors.darkSurface,
      onSurface: EventColors.cream,
      outline: EventColors.darkBorder,
      surfaceContainerHighest: EventColors.darkElevated,
    );

    return _build(
      scheme: scheme,
      background: EventColors.darkBackground,
      surface: EventColors.darkSurface,
      fieldFill: EventColors.darkElevated,
      fieldBorder: EventColors.darkBorder,
      appBarColor: EventColors.maroon,
      appBarText: EventColors.cream,
      linkColor: EventColors.gold,
    );
  }

  // Shared builder so light and dark stay in sync.
  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color surface,
    required Color fieldFill,
    required Color fieldBorder,
    required Color appBarColor,
    required Color appBarText,
    required Color linkColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: appBarText,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Fixed height only: Size.fromHeight would force infinite width
          // and break dialog buttons.
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: linkColor),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.primary,
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
        side: BorderSide(color: fieldBorder),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: fieldBorder),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.7)),
      switchTheme: SwitchThemeData(
        // Explicit colours: the defaults pick a pale track that disappears
        // on the light drawer.
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.onSurface.withValues(alpha: 0.6);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(fieldBorder),
      ),
      dividerTheme: DividerThemeData(color: fieldBorder),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      drawerTheme: DrawerThemeData(backgroundColor: surface),
    );
  }
}

// Lives outside MainApp so any screen can read or change the theme.
final ValueNotifier<ThemeMode> themeController = ValueNotifier(
  ThemeMode.system,
);

const _themePrefsKey = 'themeMode';

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_themePrefsKey);

  if (saved == 'dark') {
    themeController.value = ThemeMode.dark;
  } else if (saved == 'light') {
    themeController.value = ThemeMode.light;
  }
}

Future<void> setThemeMode(ThemeMode mode) async {
  themeController.value = mode;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themePrefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
}
