import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:control_termotanque/routes/route_generator.dart';
import 'package:control_termotanque/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:theme_mode_handler/theme_mode_handler.dart';

import 'models/auth/user_model.dart';

void main() async {
  //WidgetsFlutterBinding.ensureInitialized();
  //SystemChrome.setPreferredOrientations(
 //     [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageManager()),

      ],
      child: MyApp(),
    )
  );
  ModelsRepository modelsRepository = ModelsRepository();
  try {
    await modelsRepository.getUser;
  }catch (e){
    modelsRepository.createUser(user: User());
  }
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
          debugShowCheckedModeBanner: false,
          title: 'Control termotanque',
          theme: CustomTheme.lightTheme,
          highContrastTheme: CustomTheme.lightTheme,
          darkTheme: CustomTheme.darkTheme,
          themeMode: themeMode,
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }


}