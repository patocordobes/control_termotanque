import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  ModelsRepository modelsRepository = ModelsRepository();
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
      body: Center(
        child: FutureBuilder<List<Device>>(
          future: modelsRepository.getDevices(),
          builder: (_,snapshot){
            if (snapshot.hasData){
              if (snapshot.data!.length != 0) {
                List<Device> devices = snapshot.data!;
                return ListView.builder(
                  itemBuilder: (context, index) {
                    Device device = devices[index];


                    return ListTile(
                      leading: Icon(
                        IconData(59653, fontFamily: 'signal_wifi'),size: 30,),
                      title: Text('${device.name!}'),
                      subtitle: Text("MAC: ${device.mac}"),
                      trailing: Icon(Icons.edit) ,
                      selected: false,
                      onTap: (){

                      },

                    );
                  },
                  itemCount: devices.length,
                );
              }else{
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Toca el "),
                    const Icon(Icons.add),
                    Text(" para añadir dispositivos.")
                  ],
                );
              }
            }else if (snapshot.hasError){
              return Text("error ${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
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
