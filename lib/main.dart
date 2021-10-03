

import 'package:control_termotanque/routes/route_generator.dart';
import 'package:control_termotanque/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theme_mode_handler/theme_mode_handler.dart';

void main()  {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyApp createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ThemeModeHandler(
      manager: MyManager(),
      placeholderWidget: Center(
        child: CircularProgressIndicator()
      ),
      builder: (ThemeMode themeMode){
        return MaterialApp(
          title: 'Control termotanque',
          theme: CustomTheme.lightTheme,
          highContrastTheme: CustomTheme.lightTheme,
          darkTheme: CustomTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: "/devices",
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }


}