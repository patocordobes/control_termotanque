 import 'package:flutter/material.dart';
import 'package:theme_mode_handler/theme_mode_manager_interface.dart';

CustomTheme currentTheme = CustomTheme();

class CustomTheme extends ChangeNotifier{
  static ThemeData get lightTheme {
    return ThemeData(
      appBarTheme: AppBarTheme(

      ),
      primaryColor: Color(0xFF37B5E8),
      accentColor: Colors.green,
      brightness: Brightness.light,

    );
  }
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Color(0xFF0084B5),
      accentColor: Colors.green[800],
      brightness: Brightness.dark,

    );
  }
}
class MyManager implements IThemeModeManager {
  @override
  Future<String> loadThemeMode() async {

    return "ThemeMode.system";
  }

  @override
  Future<bool> saveThemeMode(String value) async {

    return true;
  }
}
