import 'package:control_termotanque/models/auth/user_model.dart';
import 'package:control_termotanque/repository/models_repository.dart';
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
  ModelsRepository modelsRepository = ModelsRepository();
  late User user;
  late List<DropdownMenuItem<String>> _dropDownMenuItems = buildAndGetDropDownMenuItems(_options);
  bool celsius = true;
  List _options = ["Fahrenheit", "Celsius"];
  @override
  initState() {
    super.initState();
    modelsRepository.getUser.then((user) {
      setState(() {
        this.user = user;
        celsius = user.celsius;
      });

    });

  }
  List<DropdownMenuItem<String>> buildAndGetDropDownMenuItems(List fruits) {
    List<DropdownMenuItem<String>> items = [];
    for (String fruit in fruits) {
      items.add(new DropdownMenuItem(value: fruit, child: new Text(fruit)));
    }
    return items;
  }
  void changedDropDownItem(String? selectedUnity) {
    setState(() {
      celsius = (selectedUnity == "Celsius")? true:false;
      user.celsius = celsius;
      modelsRepository.createUser(user: user);
    });
  }
  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeModeHandler.of(context)?.themeMode;
    return Scaffold(
      body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool isscrolled){
            return <Widget>[
              SliverAppBar(
                  title: Text(widget.title),
                  pinned:false,
                  floating: true,
                  forceElevated: isscrolled,
              ),
            ];
          },
          body:Center(
            child: Column(
              children: [
                ListTile(
                  title: Text("Tema"),
                  subtitle: Text("Actual: ${themeMode.toString().replaceFirst(RegExp(r'ThemeMode.'), "")}, Toca para cambiar"),
                  leading: Icon(Icons.brightness_4_rounded),
                  onTap: () {
                    _selectThemeMode(context).then((theme){
                      setState(() {
                      });
                    });
                  },
                ),
                ListTile(
                  title: Text("Ayuda"),
                  subtitle: Text("Centro de ayuda, Reportar bugs"),
                  leading: Icon(Icons.help_outline),
                ),
                ListTile(
                  title: Text("Unidad de temperatura"),
                  subtitle: DropdownButton(
                    value: (celsius)? "Celsius":"Fahrenheit" ,
                    items: _dropDownMenuItems,
                    onChanged: changedDropDownItem,
                  ),
                  leading: Icon(Icons.thermostat_outlined),
                ),
                ListTile(
                  title: Text("Informacion de la aplicacion"),
                  leading: Icon(Icons.info_outline),
                  onTap: (){
                    showDialog<void>(
                      context: context,

                      // false = user must tap button, true = tap outside dialog
                      builder: (BuildContext dialogContext) {
                        return AboutDialog();
                      },
                    );
                  },
                ),

              ],
            )
        ),
      ),
    );
  }
  Future<dynamic> _selectThemeMode(BuildContext context) async {
    Future<dynamic> newThemeMode = showThemePickerDialog(context: context);
    return newThemeMode;
  }
}