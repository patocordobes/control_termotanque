import 'dart:async';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  ModelsRepository modelsRepository = ModelsRepository();
  List<Device> devicesConnected = [];
  List<Device> devicesDisconnected = [];
  bool isLoaded = false;
  late MessageManager messageManager;
  late Timer updateDevicesConnection;
  late Timer updateMqtt;

  @override
  void initState(){
    super.initState();
    messageManager = context.read<MessageManager>();
    messageManager.start();
    updateDevicesConnection = Timer.periodic(Duration(seconds: 20), (t) {
      messageManager.updateDevicesConnection();
    });
    updateMqtt = Timer.periodic(Duration(seconds:10),(t){
      if (messageManager.mqttClient.connectionStatus!.state != MqttConnectionState.connected){
        messageManager.update();
      }
    });
  }
  void refresh(){
    messageManager.updateDevicesConnection();
  }
  @override
  void dispose() {
    super.dispose();
    updateDevicesConnection.cancel();
    messageManager.stop();
  }
  @override
  Widget build(BuildContext context) {

    messageManager = context.watch<MessageManager>();
    if(messageManager.status == ManagerStatus.starting || messageManager.status == ManagerStatus.updating) {
      isLoaded = false;
    }else{
      isLoaded = true;
    }
    devicesConnected = [];
    devicesDisconnected = [];
    messageManager.getDevices.forEach((device){
      if (device.connectionStatus != ConnectionStatus.disconnected && device.connectionStatus != ConnectionStatus.updating){
        devicesConnected.add(device);
      }else{
        devicesDisconnected.add(device);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: (){
                refresh();
              }
          ),
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: (){
                Navigator.of(context).pushNamed("/settings");
              }
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(

          mainAxisSize: MainAxisSize.min,
          children: getList(),
        ),
      ),
    );
  }
  List<Widget> getList(){
    List<Widget> list = [];
    if (!isLoaded){
      list.add(LinearProgressIndicator());
    }
    if (devicesConnected.isNotEmpty){
      list.add(
          ListTile(
            leading: Text(""),
            title: Text('Conectados Actualmente',style: TextStyle(color: Theme.of(context).primaryColor),),
          )
      );
    }
    devicesConnected.forEach((device){

      var listTile = ListTile(
        leading: Icon(
          IconData(59653, fontFamily: 'signal_wifi'),size: 30,),
        title: Text('${device.name}'),
        subtitle: Text("Conectado (mac: ${device.mac})"),
        selected: false,
        onTap: (){
          messageManager.selectDevice(device);
          Navigator.of(context).pushNamed("/device");
        },
        trailing: IconButton(
            icon: Icon(Icons.settings),
            onPressed: (){
              messageManager.selectDevice(device);
              Navigator.of(context).pushNamed("/edit_device");
            }
        ),
      );
      list.add(listTile);
    });
    if (devicesConnected.isNotEmpty){
      list.add(Padding(child: Divider(height: 0,),padding: EdgeInsets.only(top:8),));
    }
    list.add(
        ListTile(
            leading: Icon(Icons.add),
            title: Text('Sincronizar dispositivo nuevo'),
          onTap: (){
            Navigator.of(context).pushNamed("/search_devices");
          },
        )
    );

    if (devicesDisconnected.isNotEmpty){
      list.add(Divider(height: 0));
      list.add(
        ListTile(
          leading:Text(""),
          title: Text('Dispositivos conectados previamente',style: TextStyle(color: Theme.of(context).primaryColor),)
        )
      );
    }
    devicesDisconnected.forEach((device){
      var listTile = ListTile(
        enabled: (device.connectionStatus == ConnectionStatus.updating)? false:true,
        leading: Icon(
          IconData(59653, fontFamily: 'signal_wifi'),size: 30,),
        title: Text('${device.name}'),
        subtitle: Text((device.connectionStatus == ConnectionStatus.updating)?"Conectando...":"Desconectado"),
        selected: false,
        onTap: () async {
          messageManager.updateDeviceConnection(device);
          await Future.delayed(Duration(milliseconds:1000));
          if (device.connectionStatus != ConnectionStatus.disconnected){
            messageManager.selectDevice(device);
            Navigator.of(context).pushNamed("/device");
          }
        },
        trailing: IconButton(
            icon: Icon(Icons.settings),
            onPressed: (){
              messageManager.selectDevice(device);
              Navigator.of(context).pushNamed("/edit_device");
            }
        ),
      );
      list.add(listTile);
    });
    list.add(Divider());
    list.add(
        ListTile(
            leading:Icon(Icons.info_outline),
            subtitle: Text('Toca un dispositivo para conectarte')
        )
    );
    return list;
  }

}
