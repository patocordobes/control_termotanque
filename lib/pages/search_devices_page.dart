import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:system_settings/system_settings.dart';
import 'package:provider/provider.dart';

WifiConfiguration ? wifiConfiguration;
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
  bool isLoaded = false;
  bool connectingToWiFi = false;
  List<WifiNetwork> wifiNetworkList = [];
  WifiNetwork? currentWifiNetwork ;
  late MessageManager messageManager;

  @override
  void initState() {
    super.initState();
    messageManager = context.read<MessageManager>();
    isLoaded = false;
    connectingToWiFi = false;
    wifiConfiguration = WifiConfiguration();
    enableWifiWithAlarm();
    wifiConfiguration!.connectToWifi("","","").then((_){
      getWifiList();
      checkConnection();
    });
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
    print("is resumed $_isInForeground");
    if (_isInForeground ){
      if ( connectingToWiFi){
        connectingToWiFi= false;
        wifiConfiguration!.isConnectedToWifi("${currentWifiNetwork!.ssid}").then((connected) async {
          if (connected){
            messageManager.listenForNew();
            messageManager.newDevice.mac = currentWifiNetwork!.bssid;
            messageManager.newDevice.name = "Nuevo Dispositivo";
            messageManager.updateDeviceConnection(messageManager.newDevice);
            if (messageManager.newDevice.connectionStatus == ConnectionStatus.updating && messageManager.newDevice.connectionStatus == ConnectionStatus.local) {
              await Future.delayed(Duration(seconds: 4));
            }
            if(mounted && messageManager.newDevice.connectionStatus != ConnectionStatus.disconnected && messageManager.newDevice.connectionStatus != ConnectionStatus.mqtt) {
              Navigator.of(context).pushNamed(
                  "/choose_wifi", arguments: {"create": true});
            }else{
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No se pudo conectar al dispositivo')),
              );
            }
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Debe seleccionar la red correcta.')),
            );
          }
        });
      }
    }
  }
  void refresh(){
    setState(() {
      isLoaded = false;
      connectingToWiFi = false;
      wifiConfiguration = WifiConfiguration();
      wifiConfiguration!.connectToWifi("","","").then((_){
        getWifiList();
        checkConnection();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
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
      body: backdropFilter(
        Stack(
          children: [
            (wifiNetworkList.isEmpty )?
            Align(
                alignment: Alignment.center,
                child:Text("No se encontraron dispositivos",textAlign: TextAlign.center,)
            )
                :
            getWiFiWidget(),

          ],
        )
      )
    );
  }
  Widget backdropFilter( Widget child) {
    if (isLoaded){
      return child;
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(),
          ),
        )
      ],
    );
  }
  Widget getWiFiWidget() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        WifiNetwork wifiNetwork = wifiNetworkList[index];
        print(wifiNetwork.frequency);
        print(wifiNetwork.level);
        print(wifiNetwork.signalLevel);
        return ListTile(
          leading: Icon(
            IconData(59653, fontFamily: 'signal_wifi'),size: 30,),
          title: Text('${wifiNetwork.ssid!} '),
          selected: false,
          onTap: (){
            setState(() {
              connectingToWiFi = true;
              currentWifiNetwork = wifiNetwork;
            });
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
                        title: Text('Debes seleccionar la red "${wifiNetwork.ssid}" y ingresar como contraseña "Dinamico"'),
                      ),
                      ListTile(
                        leading: MyBullet(),
                        title: Text("Luego revisa tus notificaciones y deberia aparecerte algo como este mensaje (el mensaje puede tardar unos segundos en aparecer en la barra de notificaciones):"),
                      ),
                      Text("Esta red no tiene acceso a Internet.\n¿Deseas mantener la conexión?",style: Theme.of(context).textTheme.caption),
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
                  TextButton( // Diseña el boton
                    child: Text("ACEPTAR"),
                    onPressed: () async {
                      SystemSettings.wifi();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
          },

        );
      },
      itemCount: wifiNetworkList.length,
    );
  }

  Future<void> getWifiList() async {
    List<WifiNetwork> list = await wifiConfiguration!.getWifiList() as List<WifiNetwork>;
    wifiNetworkList = [];
    List<Device> devices = await modelsRepository.getDevices();
    List macs = [];
    devices.forEach((device) {
      macs.add(device.mac);
    });
    list.forEach((wifiNetwork) {
      if (devices.isNotEmpty) {
        if (!macs.contains(wifiNetwork.bssid)) {
          if (wifiNetwork.ssid == "Dinamico${wifiNetwork.bssid.toUpperCase().substring(3)}") {
            wifiNetworkList.add(wifiNetwork);
          }
        }
      }else{
        if (wifiNetwork.ssid == "Dinamico${wifiNetwork.bssid.toUpperCase().substring(3)}") {
          wifiNetworkList.add(wifiNetwork);
        }
      }
    });
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> checkConnection() async {
    bool value = await wifiConfiguration!.isWifiEnabled();
    if (!value) {
      await enableWifi();
    }
    wifiConfiguration!.checkConnection().then((value) {
      print('Value: ${value.toString()}');
    });
  }

  void enableWifiWithAlarm(){
    wifiConfiguration!.enableWifiWithAlarm().then((value){
      print('Wifi with alarm value: ${value.toString()}');
    });
  }
}


