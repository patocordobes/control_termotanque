import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:system_settings/system_settings.dart';

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
  bool volvio = false;
  List<WifiNetwork> wifiNetworkList = [];
  bool isLoaded = false;
  bool connectingToWiFi = false;
  WifiNetwork? currentWifiNetwork ;
  @override
  void initState() {
    
    super.initState();
    isLoaded = false;
    connectingToWiFi = false;
    wifiConfiguration = WifiConfiguration();
    wifiConfiguration!.connectToWifi("","","").then((_){
      getWifiList();
      checkConnection();
    });
    WidgetsBinding.instance!.addObserver(this);
    
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
    print("is resumed $_isInForeground");
    if (_isInForeground ){
      if ( connectingToWiFi){
        connectingToWiFi= false;
        wifiConfiguration!.isConnectedToWifi("${currentWifiNetwork!.ssid}").then((connected){
          if (connected){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dispositivo "${currentWifiNetwork!.ssid}" conectado exitosamente.')),
            );
            
            Navigator.of(context).pushNamedAndRemoveUntil("/choose_wifi", (Route<dynamic> route) => false,arguments:{"device": Device(mac:currentWifiNetwork!.bssid,ssid:currentWifiNetwork!.ssid).toDatabaseJson()});
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Debe seleccionar la red correcta.')),
            );
          }
        });
      }
    }
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
          IconButton(icon: Icon(Icons.autorenew), onPressed: (){
            setState(() {
              isLoaded = false;
              connectingToWiFi = false;
              wifiConfiguration = WifiConfiguration();
              wifiConfiguration!.connectToWifi("","","").then((_){
                getWifiList();
                checkConnection();
              });
              
            });
          })
        ],
      ),
      body: Center(
        child: getWiFiWidget(),
      ),
    );
  }
  Widget getWiFiWidget() {
    if (isLoaded){
      
      if (wifiNetworkList.isNotEmpty){
        return ListView.builder(
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
                    title: Text('Como conectar el dispositivo?'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: MyBullet(),
                          title: Text("Debes seleccionar la red '${wifiNetwork.ssid}' y ingresar como contraseña 'Dinamico'"),
                        ),
                        ListTile(
                          leading: MyBullet(),
                          title: Text("Luego revisar tus notificaciones y deberia aparecerte algo como este mensaje."),
                        ),
                        Text("Esta red no tiene acceso a Internet.\n¿Deseas mantener la conexión?",style: Theme.of(context).textTheme.caption),
                        ListTile(
                          leading: MyBullet(),
                          title: Text("IMPORTANTE!, No debe marcar el mensaje",style: TextStyle(color: Theme.of(context).errorColor)),
                        ),

                        Text("No volver a preguntar",style: Theme.of(context).textTheme.caption),
                        Divider()
                      ],
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
      }else{

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Dispositivos no encontrados, toca "),
                const Icon(Icons.autorenew),
                Text(" para recargar,"),
              ]
            ),
            Text("Podriás intentar acercarte mas a el dispositivo."),
          ],
        );
      }
      
    }
    return CircularProgressIndicator();
  }


  getWifiList() async {
    List<WifiNetwork> list = await wifiConfiguration!.getWifiList() as List<WifiNetwork>;
    wifiNetworkList = [];
    List<Device> devices = await modelsRepository.getDevices();
    list.forEach((wifiNetwork) {
      bool inserted = false;
      devices.forEach((device) {
        if (wifiNetwork.bssid != device.mac) {
          if (wifiNetwork.ssid.contains("Dinamico") && !inserted) {
            inserted = true;
            wifiNetworkList.add(wifiNetwork);
          }
        }
      });

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
  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}


