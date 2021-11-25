import 'dart:async';
import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/pages/pages.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
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

  @override
  void initState() {
    super.initState();
    messageManager = context.read<MessageManager>();
    device = messageManager.selectedDevice;
    refresh();
  }
  void refresh() {
    Future.delayed(Duration(seconds: 1),() async {
      if (device.connectionStatus == ConnectionStatus.local || device.connectionStatus == ConnectionStatus.mqtt) {
        device.deviceStatus = DeviceStatus.updating;
        Map <String, dynamic> map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "getmqtt",
        };
        if (await device.isConnectedLocally()) {
          messageManager.send(jsonEncode(map), true);
        }else{
          messageManager.send(jsonEncode(map), false);
        }
        await Future.delayed(Duration(milliseconds:200));
        device.deviceStatus = DeviceStatus.updating;
        map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "getip",
        };
        if (await device.isConnectedLocally()) {
          messageManager.send(jsonEncode(map), true);
        }else{
          messageManager.send(jsonEncode(map), false);
        }
      }
      await Future.delayed(Duration(seconds: 1));
      if (device.connectionStatus == ConnectionStatus.local) {
        device.deviceStatus = DeviceStatus.updating;
        device.wifiStatus = WifiStatus.scanning;
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
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    messageManager = context.watch<MessageManager>();
    messageManager = context.watch<MessageManager>();
    device = messageManager.selectedDevice;
    late Widget deviceWidget;
    Widget deviceStatus = ListTile(
      leading: Icon(
        IconData(59653, fontFamily: 'signal_wifi'), size: 30,),
      title: Text('${device.name}'),
      subtitle: Text(
          (device.connectionStatus == ConnectionStatus.connecting)
              ? "Conectando..."
              : (device.connectionStatus ==
              ConnectionStatus.disconnected)
              ? "Desconectado"
              : (device.connectionStatus == ConnectionStatus.local)
              ? "Conectado localmente"
              : (device.connectionStatus == ConnectionStatus.updating)?"Sincronizando...":"Conectado a traves del servidor"),
    );
    if (device.connectionStatus == ConnectionStatus.disconnected || device.connectionStatus == ConnectionStatus.connecting){
      deviceWidget = Container(
        color:Theme.of(context).primaryColor,
        child: ListTile(
            leading: (device.connectionStatus == ConnectionStatus.updating || device.connectionStatus == ConnectionStatus.connecting )?CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
            ):Text(""),
            title: deviceStatus
        ),
      );
    }else {
      if (device.softwareStatus == SoftwareStatus.outdated) {
        deviceWidget = Container(
          color: Theme.of(context).primaryColor,
          child: ListTile(

              leading: Column(
                children: [
                  Icon(Icons.new_releases,
                    size: 30,
                  ),
                  Text("${device.version}")
                ],
              ),
              title: deviceStatus,
              subtitle: Column(
                children: [
                  Text(
                    (device.connectionStatus == ConnectionStatus.local)?"Actualización disponible":"Actualización disponible, debes estar conectado localmente para poder actualizar",
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Theme.of(context).accentColor),
                    child: Text("ACTUALIZAR SOFTWARE"),
                    onPressed: () {
                      if (device.connectionStatus == ConnectionStatus.local) {
                        Navigator.of(context).pushNamed("/update_device");
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Debes estar conectado localmente al dispositivo para poder actualizarlo')),
                        );
                      }
                    }
                  )
                ],
              )
          ),
        );
      } else if (device.softwareStatus == SoftwareStatus.upgrading) {
        deviceWidget = Container(
          color: Theme
              .of(context)
              .primaryColor,
          child: ListTile(
              leading: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
              ),
              title: deviceStatus,
              subtitle: Text("Actualizando software...")
          ),
        );
      } else {
        deviceWidget = Container(
          color: Theme
              .of(context)
              .primaryColor,
          child: ListTile(
              leading: Column(
                children: [
                  Icon(Icons.cloud_done_rounded, size: 30),
                  Text("${device.version}")
                ],
              ),
              title: deviceStatus,
              subtitle: Text("Software en la ultima version")
          ),
        );
      }
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Opciones del dispositivo"),
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: (){
            Navigator.of(context).pushNamed("/settings");
          }),
          IconButton(icon: Icon(Icons.refresh),
            onPressed: (){
              refresh();
            }
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            deviceWidget,
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
                              content: Text("Una vez olvidado el dispositivo que ha agregado en su móvil desaparecerá, y tendrá que agregarlo nuevamente. ¿Estás seguro de que quieres olvidarlo?"),
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
                      child: Text((device.connectionStatus == ConnectionStatus.disconnected)?"CONECTAR" : (device.connectionStatus == ConnectionStatus.connecting)?"CANCELAR":"DESCONECTAR"),
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
              leading: Text(""),
              title: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only( right:10),
                      child: OutlinedButton(
                          child: Text("REINICIAR"),
                          onPressed: (device.connectionStatus ==
                              ConnectionStatus.local || device
                              .connectionStatus == ConnectionStatus.mqtt)?() async {
                            bool? result = await showDialog(
                              context: context, builder: (_) {
                            return AlertDialog(
                              title: Text("¿Reiniciar Dispositivo?"),
                              content: Text(
                                  "Esto apagara el dispositivo y luego volvera a encender. ¿Estás seguro de que quieres reiniciarlo?"),
                              actions: [
                                TextButton(
                                  child: Text("CANCELAR"),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: Text("REINICIAR ESTE DISPOSITIVO"),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                )
                              ],

                            );
                          });
                          if (result != null) {
                            if (result) {
                              device.deviceStatus = DeviceStatus.updating;
                              device.connectionStatus =
                                  ConnectionStatus.updating;
                              Map <String, dynamic> map = {
                                "t": "devices/" +
                                    device.mac.toUpperCase().substring(3),
                                "a": "reset",
                              };
                              if (await device.isConnectedLocally()) {
                                messageManager.send(jsonEncode(map), true);
                              } else {
                                messageManager.send(jsonEncode(map), false);
                              }
                            }
                          }
                        } : null
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(

                        child: Text((device.resistance)?"APAGAR RESISTENCIA" : "PRENDER RESISTENCIA"),
                        onPressed: (device.connectionStatus ==
                            ConnectionStatus.local || device
                            .connectionStatus == ConnectionStatus.mqtt)?() async {
                          device.deviceStatus = DeviceStatus.updating;
                          Map <String, dynamic> map = {
                            "t": "devices/" +
                                device.mac.toUpperCase().substring(3),
                            "a": "switch",
                            "d":{"o":(!device.resistance)? 1 : 0 }
                          };
                          if (await device.isConnectedLocally()) {
                            messageManager.send(jsonEncode(map), true);
                          } else {
                            messageManager.send(jsonEncode(map), false);
                          }
                        }:null
                    ),
                  ),
                ],
              ),
            ),
            OpenContainer(
              openBuilder: (_, closeContainer) => ChooseWifiPage(create:false),
              tappable: false,
              closedColor: Theme.of(context).dialogBackgroundColor,
              openColor: Colors.transparent,
              closedBuilder: (_, openContainer) => ListTile(
                  enabled: (device.connectionStatus == ConnectionStatus.local)? true:false,
                  leading: Icon(Icons.network_wifi),
                  title: Text("Editar red del dispositivo"),
                  subtitle: Text("Para cambiar a que red estará conectado el dispositivo."),
                  onTap: (){
                    openContainer();
                  }
              ),
            ),
            OpenContainer(
              openBuilder: (_, closeContainer) => DeviceSettingsPage(create:false),
              tappable: false,
              closedColor: Theme.of(context).dialogBackgroundColor,
              openColor: Colors.transparent,
              closedBuilder: (_, openContainer) => ListTile(
                  enabled: (device.connectionStatus == ConnectionStatus.local)? true:false,
                  leading: Icon(
                    IconData(59653, fontFamily: 'signal_wifi'),),
                  title: Text("Editar nombre y termotanque"),
                  subtitle: Text("Para cambiar el nombre y los atributos del termotanque."),
                  onTap: (){
                    openContainer();
                  }
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.info_outline),
              subtitle: Text("Version del sofware: ${device.version}\n"),

            ),
            ListTile(
                leading: Text(""),
                subtitle: Text('Dirección Mac del dispositivo: "${device.mac}"'),
            ),
            ListTile(
              leading: Text(""),
              subtitle: Text("Estado del servidor: ${(device.serverConnected)? "Conectado": "Desconectado"}"),
            ),
            ListTile(
              leading: Text(""),
              subtitle: Text("Red del dispositivo ${(device.connectedToWiFi)?'Conectada a "${device.ssid}"': "Desconectada"}\n"),
            ),
            ListTile(
              leading: Text(""),
              subtitle: Text("Dirección IP: ${(device.connectedToWiFi)?'"${device.address}"': "No tiene"}\n"),
            ),
            getWifiList()
          ],
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
        leading: (device.wifiStatus == WifiStatus.scanning)? Container(height:14,width:14,child: CircularProgressIndicator(strokeWidth: 2,),):Text(""),
        subtitle: Text(ssids),
      );

    }else{
      listTile = ListTile(
        leading: (device.wifiStatus == WifiStatus.scanning)? Container(height:14,width:14,child: CircularProgressIndicator(strokeWidth: 2,),):Text(""),
        subtitle: Text("El dispositivo no encontro redes"),
      );
    }

    return listTile;
  }
}