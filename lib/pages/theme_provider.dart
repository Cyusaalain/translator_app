import 'package:flutter/material.dart';

enum AppTheme { light, dark, blue }

class ThemeProvider with ChangeNotifier {
  AppTheme _theme = AppTheme.light;

  ThemeData get themeData {
    switch (_theme) {
      case AppTheme.dark:
        return ThemeData.dark();
      case AppTheme.blue:
        return ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.blue.shade50,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );
      default:
        return ThemeData.light();
    }
  }

  AppTheme get currentTheme => _theme;

  void setTheme(AppTheme theme) {
    _theme = theme;
    notifyListeners();
  }
}
