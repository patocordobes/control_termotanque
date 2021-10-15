import 'package:flutter/material.dart';
import 'package:theme_mode_handler/theme_mode_manager_interface.dart';

CustomTheme currentTheme = CustomTheme();

class CustomTheme extends ChangeNotifier{
  static ThemeData get lightTheme {
    return ThemeData(
      appBarTheme: AppBarTheme(

      ),
      primaryColor: Color(0xFF37B5E8),
      accentColor: Color(0xFF8BBA1E),
      brightness: Brightness.light,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        showUnselectedLabels: false,
        showSelectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFFFFFFF),
        unselectedItemColor: Color(0xFFFFFFFF).withOpacity(0.38),
        backgroundColor: Color(0xFF4CAE50),
      ),
    );
  }
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Color(0xFF0084B5),
      accentColor: Color(0xFF598901),
      brightness: Brightness.dark,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        showUnselectedLabels: false,
        showSelectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFFFFFFF),
        unselectedItemColor: Color(0xFFFFFFFF).withOpacity(0.38),
        backgroundColor: Color(0xFF087E23),
      ),
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
