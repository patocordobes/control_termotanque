import 'package:control_termotanque/models/models.dart';
import 'package:flutter/material.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';

WifiConfiguration ? wifiConfiguration;

class SearchDevicesPage extends StatefulWidget {
  const SearchDevicesPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<SearchDevicesPage> createState() => _SearchDevicesPageState();
}

class _SearchDevicesPageState extends State<SearchDevicesPage> {

  @override
  void initState() {
    wifiConfiguration = WifiConfiguration();
    super.initState();
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
            setState((){
              wifiConfiguration = WifiConfiguration();
            });
          })
        ],
      ),
      body: Center(
        child: FutureBuilder<List<dynamic>>(
          future: getWifiList(),
          builder: (_,snapshot){
            if (snapshot.hasData) {
              List<WifiNetwork> list = snapshot.data! as List<WifiNetwork>;
              List<WifiNetwork> wifiNetworkList = [];
              list.forEach((wifiNetwork) {
                if (wifiNetwork.ssid == "Dinamico"){
                  wifiNetworkList.add(wifiNetwork);
                }
              });
              if (wifiNetworkList.length != 0) {

                return Column(
                  children: <Widget>[


                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          WifiNetwork wifiNetwork = wifiNetworkList[index];

                          print(wifiNetwork.security);

                          return ListTile(
                            leading: Icon(
                                IconData(59653, fontFamily: 'signal_wifi'),size: 30,),
                            title: Text('${wifiNetwork.ssid!} N° ${index + 1}'),
                            selected: false,
                            onTap: (){

                              wifiConfiguration!.connectToWifi(wifiNetwork.ssid, wifiNetwork.bssid, "package:control_termotanque").then((connectionStatus){
                                switch (connectionStatus) {
                                  case WifiConnectionStatus.connected:
                                    print("connected");
                                    Navigator.of(context).pushNamed("/choose_wifi",arguments:{"device": Device(mac:wifiNetwork.bssid).toJson()});
                                    break;

                                  case WifiConnectionStatus.alreadyConnected:
                                    print("alreadyConnected");
                                    break;
                                }
                              });
                            },

                          );
                        },
                        itemCount: wifiNetworkList.length,
                      ),
                    ),
                  ],
                );
              }else{
                return Text("No se encontraron dispositivos.");
              }
            }
            return CircularProgressIndicator();
          },

        )
      ),
    );
  }



  Future<List<dynamic>> getWifiList() async {
    return wifiConfiguration!.getWifiList();
  }
}
