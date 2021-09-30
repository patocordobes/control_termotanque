import 'package:flutter/material.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: (){
              Navigator.of(context).pushNamed("/settings");
            }
          )
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text("Dispositivo 'fede' "),
            subtitle: Text("40°"),
            leading: const Icon(Icons.devices),
          ),
          Divider(),
          ListTile(
            title: Text("Dispositivo 'pato' "),
            subtitle: Text("50°"),
            leading: const Icon(Icons.devices),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Toca el ',
                  ),
                  const Icon(Icons.add),
                  const Text(
                    ' para agregar un dispositivo',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.of(context).pushNamed("/search_devices");
        },
        tooltip: 'Añadir Dispositivo',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
