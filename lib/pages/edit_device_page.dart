import 'dart:async';
import 'dart:convert';

import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditDevicePage extends StatefulWidget {
  const EditDevicePage({Key? key}) : super(key: key);
  @override
  State<EditDevicePage> createState() => _EditDevicePageState();
}

class _EditDevicePageState extends State<EditDevicePage> {
  ModelsRepository modelsRepository = ModelsRepository();
  late Device device;
  late MessageManager messageManager;
  late Timer timerWiFi ;

  @override
  void initState() {
    super.initState();
    messageManager = context.read<MessageManager>();
    device = messageManager.selectedDevice;
    if (device.connectionStatus != ConnectionStatus.disconnected) {
      Map <String, dynamic> map = {
        "t": "devices/" + device.mac.toUpperCase().substring(3),
        "a": "getw",
      };
      messageManager.send(jsonEncode(map), true);
    }
    timerWiFi = Timer.periodic(Duration(seconds: 30),(t){
      if (device.connectionStatus != ConnectionStatus.disconnected) {
        Map <String, dynamic> map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "getw",
        };
        messageManager.send(jsonEncode(map), true);
      }
    });
  }
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }
  @override
  void dispose() {
    timerWiFi.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    messageManager = context.watch<MessageManager>();
    device = messageManager.selectedDevice;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Opciones del dispositivo"),
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: (){
            Navigator.of(context).pushNamed("/settings");
          }),
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color:Theme.of(context).primaryColor,
                child: ListTile(
                  leading: Text(""),
                  title: ListTile(
                    leading: Icon(
                      IconData(59653, fontFamily: 'signal_wifi'),size: 30,),
                    title: Text('${device.name}'),
                    subtitle: Text((device.connectionStatus == ConnectionStatus.updating)?"Conectando...":(device.connectionStatus == ConnectionStatus.disconnected)?"Desconectado":"Conectado"),
                  ),
                ),
              ),
              ListTile(
                leading: Text(""),
                title: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only( right:10),
                        child: OutlinedButton(
                          child: Text("OLVIDAR"),
                          onPressed: () async {
                            bool? result = await showDialog(context: context, builder: (_){
                              return AlertDialog(
                                title: Text("¿Olvidar este dispositivo?"),
                                content: Text("Una vez eliminado el dispositivo que ha agregado en su movil desaparecera, y tendra que agregarlo nuevamente. Estas segúro de que quieres eliminarlo."),
                                actions: [
                                  TextButton(
                                    child:Text("CANCELAR"),
                                    onPressed: (){
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child:Text("OLVIDAR ESTE DISPOSITIVO"),
                                    onPressed: (){
                                      Navigator.of(context).pop(true);
                                    },
                                  )
                                ],

                              );
                            });
                            if (result != null){
                              if (result){
                                modelsRepository.deleteDevice(device: device).then((_) async {
                                  await messageManager.updateDevices();
                                  Navigator.of(context).pop();
                                });
                              }
                            }
                          }
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        child: Text((device.connectionStatus == ConnectionStatus.disconnected)?"CONECTAR" : "DESCONECTAR"),
                        onPressed: () {
                          if (device.connectionStatus ==
                              ConnectionStatus.disconnected) {
                            messageManager.updateDeviceConnection(device);
                          } else {
                            messageManager.disconnectDevice(device);
                            messageManager.updateDevicesConnection();
                          }

                        }
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                  enabled: (device.connectionStatus == ConnectionStatus.local)? true:false,
                  leading: Icon(Icons.network_wifi),
                  title: Text("Editar red del dispositivo"),
                  subtitle: Text("Para cambiar a que red estara conectado el dispositivo."),
                  onTap: (){
                    Navigator.of(context).pushNamed("/choose_wifi",arguments:{"device": device.toDatabaseJson(),"create":false});
                  }
              ),

              ListTile(
                  enabled: (device.connectionStatus == ConnectionStatus.local)? true:false,
                  leading: Icon(
                    IconData(59653, fontFamily: 'signal_wifi'),),
                  title: Text("Editar nombre y termotanque"),
                  subtitle: Text("Para cambiar el nombre y los atributos del termotanque."),
                  onTap: (){
                    Navigator.of(context).pushNamed("/device_configuration",arguments:{"create":false});
                  }
              ),
              Divider(),
              ListTile(

                  leading: Icon(Icons.info_outline),

                  subtitle: Text("Direccion mac del dispositivo: ${device.mac}"),

              ),
              ListTile(
                leading: Text(""),
                subtitle: Text("Red del dispositivo ${(device.connectedToWiFi)?'Conectada a "${device.ssid}"': "Desconectada"}"),
              ),
              ListTile(
                leading: Text(""),
                subtitle: Text("Direccion IP ${(device.connectedToWiFi)?'"${device.address}"': "No tiene"}"),
              ),
              getWifiList()
            ],
          ),
        ),
      ),
    );
  }
  getWifiList(){
    ListTile listTile = ListTile();
    if (device.wifiNetworkList.isNotEmpty) {
      String ssids = "Redes que ve el dispositivo: \n\n";
      device.wifiNetworkList.forEach((element) {
        ssids += " - ${element.ssid}\n\n";
      });
      listTile = ListTile(
        leading: Text(""),
        subtitle: Text(ssids),
      );

    }else{
      listTile = ListTile(
        leading: Text(""),
        subtitle: Text("El dispositivo no encontor redes"),
      );
    }
    return listTile;
  }
  void deviceConnected() async {
    if (!await device.isConnectedLocally()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Solo puedes editar localmente'),backgroundColor:Colors.amber),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
          "/devices", (Route<dynamic> route) => false);
    }
  }
}