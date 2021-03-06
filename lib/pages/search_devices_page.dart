import 'dart:async';

import 'package:animations/animations.dart';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/pages/pages.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:system_settings/system_settings.dart';
import 'package:provider/provider.dart';

Future<void> enableWifi() async {
  WifiConfiguration wifi = WifiConfiguration();
  await wifi.enableWifi();
}
Future<void> disableWifi() async {
  WifiConfiguration wifi = WifiConfiguration();
  await wifi.disableWifi();
}

class SearchDevicesPage extends StatefulWidget {
  const SearchDevicesPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<SearchDevicesPage> createState() => _SearchDevicesPageState();
}

class MyBullet extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 10.0,
      width: 10.0,
      decoration: new BoxDecoration(
        color: Theme.of(context).hintColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SearchDevicesPageState extends State<SearchDevicesPage> with WidgetsBindingObserver {
  ModelsRepository modelsRepository = ModelsRepository();
  bool _isInForeground = true;
  bool loading = false;
  late Timer timerRedirect;
  late MessageManager messageManager;
  late WifiConfiguration wifiConfiguration;

  @override
  void initState() {
    super.initState();
    wifiConfiguration = WifiConfiguration();
    enableWifiWithAlarm();
    messageManager = context.read<MessageManager>();
    timerRedirect = Timer.periodic(Duration(milliseconds:1), (timer) {});
    refresh();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    timerRedirect.cancel();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setState(() {
      _isInForeground = state == AppLifecycleState.resumed;
    });
    print("is resumed $_isInForeground");
    if (_isInForeground) {
      messageManager.updateNewDeviceConnection();
    }
  }

  void refresh() async {
    await Future.delayed(Duration(seconds:1),);

    messageManager.scannedDevices = [];
    messageManager.notifyListeners();
    wifiConfiguration = WifiConfiguration();
    messageManager.udpReceiver.close();
    messageManager.udpReceiver2.close();
    messageManager.update(updateWifi: true);

    messageManager.status = ManagerStatus.updating ;
    messageManager.notifyListeners();
    wifiConfiguration.connectToWifi("", "", ""); //TODO descomennatar esto para la release

  }
  @override
  Widget build(BuildContext context) {
    messageManager = context.watch<MessageManager>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: (){
            Navigator.of(context).pushNamed("/settings");
          }),
          IconButton(icon: Icon(Icons.refresh), onPressed: (){
            refresh();
          })
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: getDevicesScanned()
        ),
      )
    );
  }

  List<Widget> getDevicesScanned() {
    List<Widget> list = [];
    if (messageManager.status == ManagerStatus.updating){
      list.add(LinearProgressIndicator());
    }
    list.add(
        ListTile(
            leading:(messageManager.status == ManagerStatus.updating)? Container(child: CircularProgressIndicator(),height:16,width: 16,):Text(""),
            title: Text('Dispositivos escaneados',style: TextStyle(color: Theme.of(context).primaryColor),)
        )
    );

    if (messageManager.scannedDevices.isNotEmpty) {

      messageManager.scannedDevices.forEach((device) {
        list.add(
          OpenContainer(
            openBuilder: (_, closeContainer) => ChooseWifiPage(create:true),
            tappable: false,
            closedColor: Theme.of(context).dialogBackgroundColor,
            closedBuilder: (_, openContainer) => SearchedDeviceWidget(device: device,onTap: () async {
              if (device.connectionStatus != ConnectionStatus.local) {

                showDialog(context: context, builder: (context) {
                  return AlertDialog(
                    title: Text('Por favor lea TODO el instructivo'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: MyBullet(),
                            title: Text('Primero debes apretar "ACEPTAR"'),
                          ),
                          ListTile(
                            leading: MyBullet(),
                            title: Text('Debes seleccionar la red "${messageManager.newDevice.name}" y ingresar como contrase??a "Dinamico"'),
                          ),
                          ListTile(
                            leading: MyBullet(),
                            title: Text("Luego revisa tus notificaciones y deberia aparecerte algo como este mensaje (el mensaje puede tardar unos segundos en aparecer en la barra de notificaciones):"),
                          ),
                          Text("Esta red no tiene acceso a Internet.\n??Deseas mantener la conexi??n?",style: Theme.of(context).textTheme.caption),
                          ListTile(
                            leading: MyBullet(),
                            title: Text("Importante!, No debe marcar el mensaje:"),
                          ),

                          Text("No volver a preguntar",style: Theme.of(context).textTheme.caption),
                          Divider()
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton( // Dise??a el boton
                        child: Text("ACEPTAR"),
                        onPressed: () async {
                          SystemSettings.wifi();
                          Navigator.of(context).pop();
                          messageManager.selectNewDevice(device);

                          timerRedirect.cancel();
                          timerRedirect = Timer.periodic(Duration(milliseconds:1), (timer) {

                            if (_isInForeground ){


                              if (messageManager.newDevice.connectionStatus == ConnectionStatus.connecting) {
                                timerRedirect.cancel();
                                print("siuuu");

                                wifiConfiguration.isConnectedToWifi("${messageManager.newDevice.name}").then((connected) async {
                                  if (connected){


                                    messageManager.update(updateWifi: false);
                                    await Future.delayed(Duration(seconds:2));
                                    messageManager.updateDeviceConnection(messageManager.newDevice);
                                    timerRedirect.cancel();
                                    timerRedirect = Timer.periodic(Duration(milliseconds:1), (timer) {
                                      if(mounted && messageManager.newDevice.connectionStatus == ConnectionStatus.local) {
                                        print("siuuu");
                                        timerRedirect.cancel();
                                        openContainer();
                                      }
                                    });
                                    Future.delayed(Duration(milliseconds:3000),(){
                                      timerRedirect.cancel();
                                    });
                                  }else{
                                    messageManager.disconnectDevice(messageManager.newDevice);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Debe seleccionar la red correcta.')),
                                    );
                                  }
                                });
                              }else{
                                print("noooooooooooooooo");
                              }
                            }
                          });
                        },
                      ),
                      TextButton( // Dise??a el boton
                        child: Text("CONECTAR"),
                        onPressed: () async {

                          Navigator.of(context).pop();
                          messageManager.selectNewDevice(device);
                          messageManager.updateNewDeviceConnection();

                          timerRedirect.cancel();
                          timerRedirect = Timer.periodic(Duration(milliseconds:1), (timer) {

                            if (_isInForeground ){


                              if (messageManager.newDevice.connectionStatus == ConnectionStatus.connecting) {
                                timerRedirect.cancel();
                                print("siuuu");

                                wifiConfiguration.isConnectedToWifi("${messageManager.newDevice.name}").then((connected) async {
                                  if (connected){


                                    messageManager.update(updateWifi: false);
                                    await Future.delayed(Duration(seconds:2));
                                    messageManager.updateDeviceConnection(messageManager.newDevice);
                                    timerRedirect.cancel();
                                    timerRedirect = Timer.periodic(Duration(milliseconds:1), (timer) {
                                      if(mounted && messageManager.newDevice.connectionStatus == ConnectionStatus.local) {
                                        print("siuuu");
                                        timerRedirect.cancel();
                                        openContainer();
                                      }
                                    });
                                    Future.delayed(Duration(milliseconds:3000),(){
                                      timerRedirect.cancel();
                                    });
                                  }else{
                                    messageManager.disconnectDevice(messageManager.newDevice);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Debe seleccionar la red correcta.')),
                                    );
                                  }
                                });
                              }else{
                                print("noooooooooooooooo");
                              }

                            }
                          });
                          Future.delayed(Duration(milliseconds:3000),(){
                            timerRedirect.cancel();
                          });
                        },
                      ),
                    ],
                  );
                });
              }else{
                openContainer();
              }
            },),
          ),
        );
      });
    }else{
      list.add(Text("No se encontraron dispositivos"));
    }
    list.add(Divider());

    list.add(ListTile(
      leading: Icon(Icons.info_outline),
      subtitle: Text("Presiona un dispositivo para configurarlo\n"),
    ));
    return list;
  }


  Future<void> checkConnection() async {
    bool value = await wifiConfiguration.isWifiEnabled();
    if (!value) {
      await enableWifi();
    }
    wifiConfiguration.checkConnection().then((value) {
      print('Value: ${value.toString()}');
    });
  }

  void enableWifiWithAlarm(){
    wifiConfiguration.enableWifiWithAlarm().then((value){
      print('Wifi with alarm value: ${value.toString()}');
    });
  }
}

class SearchedDeviceWidget extends StatelessWidget {
  SearchedDeviceWidget({required this.device, required this.onTap});
  final Device device;
  final void Function() onTap;
  @override
  Widget build(BuildContext context){
    return ListTile(
      leading: (device.softwareStatus == SoftwareStatus.outdated)? Icon(Icons.new_releases,size: 30):Icon(
        IconData(59653, fontFamily: 'signal_wifi'),size: 30,),
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

      onTap: onTap,
    );
  }
}