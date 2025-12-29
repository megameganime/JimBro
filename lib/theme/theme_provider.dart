import 'package:flutter/material.dart';
import 'package:jim_bro/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = darkMode;

  ThemeProvider() {
    _getStoredTheme();
  }

  Future<void> _getStoredTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeData = prefs.getBool("isDarkMode") ?? true ? darkMode : lightMode;
    notifyListeners();
  }

  ThemeData get changeThemeDataTo => _themeData;

  set changeThemeDataTo(ThemeData chosenTheme) {
    _themeData = chosenTheme;
    notifyListeners();
  }

  bool isDarkMode() {
    return _themeData == darkMode;
  }

  Future<void> setDarkMode(bool makeDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", makeDark);
  }

  void toggleTheme(bool makeDark) {
    if (makeDark) {
      changeThemeDataTo = darkMode;
      _themeData = darkMode;
      setDarkMode(true);
    } else {
      changeThemeDataTo = lightMode;
      _themeData = lightMode;
      setDarkMode(false);
    }
  } 
}
