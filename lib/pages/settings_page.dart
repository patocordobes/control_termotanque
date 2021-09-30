import 'package:flutter/material.dart';
import 'package:theme_mode_handler/theme_mode_handler.dart';
import 'package:theme_mode_handler/theme_picker_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeModeHandler.of(context)?.themeMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
        ],
      ),

      body: Center(
        child: Column(
          children: [
            ListTile(
              title: Text("Tema"),
              subtitle: Text("Actual: ${themeMode.toString().replaceFirst(RegExp(r'ThemeMode.'), "")}, Toca para cambiar"), // TODO hacer manejo de cuenta
              leading: Icon(Icons.brightness_4_rounded),
              onTap: () {
                _selectThemeMode(context).then((theme){
                  setState(() {
                  });
                });
              },
            ),
            ListTile(
              title: Text("Notificaciones"),
              subtitle: Text("Tonos de mensajes, Cuando mostrar notificacion"),// TODO hacer manejo de notificaciones
              leading: Icon(Icons.notifications_rounded),
            ),
            ListTile(
              title: Text("Ayuda"),
              subtitle: Text("Centro de ayuda, Reportar bugs"),// TODO hacer manejo de notificaciones
              leading: Icon(Icons.help_outline),
            ),
          ],
        )
      ),
    );
  }
  Future<dynamic> _selectThemeMode(BuildContext context) async {
    Future<dynamic> newThemeMode = showThemePickerDialog(context: context);
    return newThemeMode;
  }
}