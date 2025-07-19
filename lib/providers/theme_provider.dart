import 'package:flutter/material.dart';
import 'package:yamka/data/application/application_storage.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;

  void initializate() async {
    String? theme = await ApplicationStorage.getTheme;
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    }
  }

  void toogleTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    ApplicationStorage.setTheme(themeMode.name.toString());
    notifyListeners();
  }
}