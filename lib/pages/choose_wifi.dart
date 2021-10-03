import 'dart:convert';

import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
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
  List<WifiNetwork> wifiNetworkList = [];
  bool isLoaded = false;
  bool connectingToWiFi = false;
  WifiNetwork? currentWifiNetwork ;
  ModelsRepository modelsRepository = ModelsRepository();
  bool connected = false;

  @override
  void initState() {
    
    super.initState();
    wifiConfiguration2 = WifiConfiguration();
    getArduinoWifiList().then((data) async{
      List<WifiNetwork> list = data as List<WifiNetwork>;
      wifiNetworkList = list;
    
      await Future.delayed(Duration(seconds: 2));
      try{
        setState(() {
          isLoaded = true;
        });
      }catch(Exception){
                  
                }
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
          IconButton(icon: Icon(Icons.autorenew), onPressed: (){
            setState((){
              connectingToWiFi = false;
              isLoaded = false;
              wifiConfiguration2 = WifiConfiguration();
              getArduinoWifiList().then((data) async{
                List<WifiNetwork> list = data as List<WifiNetwork>;
                wifiNetworkList = list;
              
                await Future.delayed(Duration(seconds: 2));
                try{
                  setState(() {
                    isLoaded = true;
                  });
                }catch(Exception){

                }
                
              });
            });
          })
        ],
      ),
      body: Column(
        children: [
          loading(),
          (connected)? ListTile(
            leading: Icon(
                IconData(59648 + (int.parse(currentWifiNetwork!.signalLevel)), fontFamily: 'signal_wifi'),size: 30,),
            title: Text('${currentWifiNetwork!.ssid!}'),
            
            trailing: IconButton(icon: Icon(Icons.settings,color: Theme.of(context).accentColor,),onPressed: (){}),
            selected: true,
            
            
          ): Text("Red del dispositivo desconectada"),
          Divider(),
          Expanded(child:getWiFiWidget()),
          Divider(),
          Align(
            child: Container(
              margin: EdgeInsets.only(right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                      "SALTAR"
                    ),
                    onPressed: (){
                      widget.device.connectedToWiFi = false;
                      widget.device.name = "pato";
                      Navigator.of(context).pushNamed("/device_configuration", arguments: {"device": widget.device.toDatabaseJson()});
                    }
                  ),
                  ElevatedButton(
                    child: Text(
                      "SIGUIENTE"
                    ),
                    onPressed: (){
                      if (connected){
                        widget.device.connectedToWiFi = connected;
                        widget.device.name = "pato";
                        Navigator.of(context).pushNamed("/device_configuration", arguments: {"device": widget.device.toDatabaseJson()});
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Debe conectar el dispositivo a una red para continuar. ')),
                        );
                      }
                    }
                  ),
                ],
              ),
            ),
            
          )
        ],
      ),
    );
  }
  Widget loading() {
    if (!isLoaded || connectingToWiFi){
      
      return Center(child: CircularProgressIndicator());
        
    }
    return Text("");
  }

  Widget getWiFiWidget() {
    
    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (context, index) {
        WifiNetwork wifiNetwork = wifiNetworkList[index];
        int signal = 59648 +
            (int.parse(wifiNetwork.signalLevel));
        return ListTile(
          leading: Icon(
              IconData(signal, fontFamily: 'signal_wifi'),size: 30,),
          title: Text('${wifiNetwork.ssid!}'),
          trailing: (wifiNetwork.security != "")? Icon(Icons.lock,size: 16) : Text(""),
          selected: false,
          onTap: () async {
            String? password = await showDialog(context: context, builder: (builder) =>EnterPasswordDialog(title: wifiNetwork.ssid));
            if (password != null) {
              setState(() {
                currentWifiNetwork = wifiNetwork;
                connectingToWiFi = true;
                connectToWiFi(wifiNetwork,password).then((value){
                  setState(() {
                    connectingToWiFi = false;
                  });
                  
                });
              });
            }
            
            
          },
        );
      },
      itemCount: wifiNetworkList.length,
    );
  }
  
  Future<List<dynamic>> getArduinoWifiList() async {
    
    var sender = await UDP.bind(Endpoint.broadcast(port: Port(8888)));
    // send a simple string to a broadcast endpoint on port 65001.
    
    Map <String, dynamic> map = {
      "t":"devices/" + widget.device.mac.toUpperCase().substring(3),
      "a":"getw"
    };
    
    var dataLength = await sender.send(
        jsonEncode(map).codeUnits, Endpoint.broadcast(port: Port(8888)));

    print("${dataLength} bytes sent.");

    // creates a new UDP instance and binds it to the local address and the port
    // 65002.
    var receiver = await UDP.bind(Endpoint.any(port: Port(8890)));
    List<WifiNetwork> wifiNetworkList = [];
    // receiving\listening
    bool listen = await receiver.listen((datagram) {
      try{
        var str = String.fromCharCodes(datagram.data);
        print(str);
        Map <String, dynamic> map2 = json.decode(str);
        List<dynamic> listWiFi = map2["d"] as List<dynamic>;
        print(map2);
        listWiFi.forEach((wifi){
          Map<String, dynamic> wifiMap = wifi;
          int dBm = int.parse(wifiMap["r"].toString());
          double quality = 0;
          if(dBm <= -100)
              quality = 0;
          else if(dBm >= -50)
              quality = 100;
          else
              quality = 2 * (dBm + 100);
          quality = quality * 5 /100;
          wifiNetworkList.add(WifiNetwork(signalLevel: quality.toInt().toString(), ssid: wifiMap["s"].toString(),security: wifiMap["e"].toString()));
          
        });
       
        receiver.close();
      }catch(e){
        print(e);
      }      
    }, timeout: Duration(seconds: 5));
    if (listen){
      wifiConfiguration2!.isConnectedToWifi("${widget.device.ssid}").then((status){
        if (!status){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Se há perdido la coñexión con el dispositivo!!!.')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil("/devices", (Route<dynamic> route) => false);
        }
      });
    }
    // close the UDP instances and their sockets.
    sender.close();
    receiver.close();
    return wifiNetworkList;
  }

  Future<bool> connectToWiFi(WifiNetwork network, String password) async {
    
    var sender = await UDP.bind(Endpoint.broadcast(port: Port(8888)));
    // send a simple string to a broadcast endpoint on port 65001.
    
    Map <String, dynamic> map = {
      "t":"devices/" + widget.device.mac.toUpperCase().substring(3),
      "a":"connectwifi",
      "d":{
        "ssid":"${network.ssid.toString()}",
        "pass": password
      }
    };
    print(map.toString());
    var dataLength = await sender.send(
        jsonEncode(map).codeUnits, Endpoint.broadcast(port: Port(8888)));
    print("${dataLength} bytes sent.");

    // creates a new UDP instance and binds it to the local address and the port
    // 65002.
    var receiver = await UDP.bind(Endpoint.any(port: Port(8890)));
    // receiving\listening
    bool result = false;
    bool listen = await receiver.listen((datagram) {
      try{
        var str = String.fromCharCodes(datagram.data);
        print(str);
        Map <String, dynamic> map2 = json.decode(str);
        result = true;
        
        if (map2["d"] != "error"){
          result = true;
          receiver.close();
        }else{
          result = false;
          receiver.close();
        }
        
    
      }catch (except){
        print(except);
      }
    }, timeout: Duration(seconds: 15));
    
    if (listen){
      wifiConfiguration2!.isConnectedToWifi("${widget.device.ssid}").then((status){
        if (!status){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Se há perdido la coñexión con el dispositivo!!!.')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil("/devices", (Route<dynamic> route) => false);
        }
      });
    }
    print(result);
    // close the UDP instances and their sockets.
    sender.close();
    receiver.close();

    if (result){
                            
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Red "${currentWifiNetwork!.ssid}" conectada al dispositivo correctamente!')),
      );
      setState(() {
        connected = true;
        connectingToWiFi = false;
        isLoaded = false;
        wifiConfiguration2 = WifiConfiguration();
        getArduinoWifiList().then((data) async{
          List<WifiNetwork> list = data as List<WifiNetwork>;
          wifiNetworkList = list;
        
          await Future.delayed(Duration(seconds: 2));
          setState(() {
            isLoaded = true;
          });
        });
      });
      //modelsRepository.createDevice(device: widget.device).then((value) {
      //  ScaffoldMessenger.of(context).showSnackBar(
      //    SnackBar(content: Text('Dispositivo creado correctamente')),
      //  );
      //  Navigator.of(context).pushNamedAndRemoveUntil("/devices", (Route<dynamic> route) => false);
      //});
      
      widget.device.connectedToWiFi = true;
      
    }else{
      setState(() {
        connected = false;
        
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ssid o contraseña incorrecta. ')),
      );

    }
    return result;
  }
}

class EnterPasswordDialog extends StatefulWidget{
  EnterPasswordDialog({required this.title});
  String title;
  @override
  _EnterPasswordDialogState createState() => _EnterPasswordDialogState();
}

class _EnterPasswordDialogState extends State<EnterPasswordDialog> {
  TextEditingController _textFieldController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              //not sure if i need this
              
              controller: _textFieldController,
              decoration: InputDecoration(hintText: 'Contraseña'),
              maxLength: 20,
              obscureText: !_obscureText,
              validator: (value) {
                if (value == null) {
                  return 'Ingresa una contrasña ';
                }
                if (value.isEmpty) {
                  return ' Ingresa una contrasña';
                }
                return null;
              },
              onSaved: (value) {
              },
            ),
            GestureDetector(
              onTap: (){
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
              child: Row(
                children: [
                  Checkbox(value: _obscureText, onChanged: (value){
                  }),
                  Text("Mostrar contraseña")

              ],),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('CANCELAR'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        //this needs to validate if the typed value was the same as the
        //hardcoded password, it would run the _getImage() function
        //the same as the validator in the TextFormField
        TextButton(
          child: Text('CONECTAR'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              print("intentando");
              Navigator.of(context).pop(_textFieldController.text);
            }
            
          },
        ),
      ],
    );
  }
}
