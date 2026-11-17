import 'package:material_ui/material_ui.dart';

const _darkBlue = Color(0xFF123B66);
const _lightBlue = Color(0xFF82C7F5);

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

ThemeData get lightBlueTheme => ThemeData(
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: _darkBlue,
        brightness: Brightness.light,
      ).copyWith(
        primary: _darkBlue,
        onPrimary: Colors.white,
        secondary: _lightBlue,
        onSecondary: _darkBlue,
        surface: const Color(0xFFF2F8FF),
      ),
  scaffoldBackgroundColor: const Color(0xFFF5FAFF),
  appBarTheme: const AppBarTheme(
    backgroundColor: _darkBlue,
    foregroundColor: Colors.white,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0x1F123B66)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFCAD9E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _darkBlue, width: 1.8),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: _darkBlue,
    contentTextStyle: const TextStyle(color: Colors.white),
    actionTextColor: _lightBlue,
    showCloseIcon: true,
    closeIconColor: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFD9EDFF),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
);

ThemeData get darkBlueTheme => ThemeData(
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: _lightBlue,
        brightness: Brightness.dark,
      ).copyWith(
        primary: _lightBlue,
        onPrimary: const Color(0xFF08233E),
        secondary: _darkBlue,
        onSecondary: _lightBlue,
        surface: const Color(0xFF10243A),
      ),
  scaffoldBackgroundColor: const Color(0xFF081827),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF10243A),
    foregroundColor: Colors.white,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0x334F7194)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF10243A),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF36516C)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _lightBlue, width: 1.8),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF1E3550),
    contentTextStyle: const TextStyle(color: Colors.white),
    actionTextColor: _lightBlue,
    showCloseIcon: true,
    closeIconColor: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF10243A),
    indicatorColor: const Color(0xFF234A70),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
);
