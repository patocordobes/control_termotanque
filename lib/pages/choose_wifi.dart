import 'package:control_termotanque/models/models.dart';
import 'package:flutter/material.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:udp/udp.dart';

WifiConfiguration ? wifiConfiguration2;

class ChooseWifiPage extends StatefulWidget {
  const ChooseWifiPage({Key? key, required this.title, required this.device}) : super(key: key);
  final Device device;
  final String title;

  @override
  State<ChooseWifiPage> createState() => _ChooseWifiPageState();
}

class _ChooseWifiPageState extends State<ChooseWifiPage> {

  @override
  void initState() {
    wifiConfiguration2 = WifiConfiguration();
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
              wifiConfiguration2 = WifiConfiguration();
            });
          })
        ],
      ),
      body: Center(
        child: FutureBuilder<List<dynamic>>(
          future: getArduinoWifiList(),
          builder: (_,snapshot){
            if (snapshot.hasData) {
              List<WifiNetwork> wifiNetworkList = snapshot.data! as List<WifiNetwork>;
              if (wifiNetworkList.length != 0) {

                return Column(
                  children: <Widget>[


                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          WifiNetwork wifiNetwork = wifiNetworkList[index];

                          int signal = 59648 +
                              (int.parse(wifiNetwork.signalLevel) - 1);

                          return ListTile(
                            leading: Icon(
                                IconData(signal, fontFamily: 'signal_wifi'),size: 30,),
                            title: Text('${wifiNetwork.ssid!}'),
                            trailing: (wifiNetwork.security != "")? Icon(Icons.security) : Text(""),
                            selected: false,
                            onTap: (){

                            },

                          );
                        },
                        itemCount: wifiNetworkList.length,
                      ),
                    ),
                  ],
                );
              }else{
                return Text("No hay redes wifi cerca del dispositivo");
              }
            }
            return CircularProgressIndicator();
          },

        )
      ),
    );
  }



  Future<List<dynamic>> getArduinoWifiList() async {
    var sender = await UDP.bind(Endpoint.broadcast(port: Port(8888)));
    // send a simple string to a broadcast endpoint on port 65001.
    var dataLength = await sender.send(
        "Dinamico;SCANWIFI".codeUnits, Endpoint.broadcast(port: Port(8888)));

    print("${dataLength} bytes sent.");

    // creates a new UDP instance and binds it to the local address and the port
    // 65002.
    var receiver = await UDP.bind(Endpoint.any(port: Port(8890)));
    List<WifiNetwork> wifiNetworkList = [];
    // receiving\listening
    bool listen = await receiver.listen((datagram) {
      var str = String.fromCharCodes(datagram.data);
      print(str);
      wifiNetworkList.add(WifiNetwork(ssid: str.split(";")[1],signalLevel: "5", security: "none"));
    }, timeout: Duration(seconds: 5));
    print(listen);
    // close the UDP instances and their sockets.
    sender.close();
    receiver.close();
    return wifiNetworkList;
  }
}
