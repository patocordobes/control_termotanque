import 'dart:async';
import 'dart:convert';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:udp/udp.dart';
import 'package:provider/provider.dart';

class ChooseWifiPage extends StatefulWidget {
  const ChooseWifiPage({Key? key, this.create = true}) : super(key: key);
  final bool create;

  @override
  State<ChooseWifiPage> createState() => _ChooseWifiPageState();
}

class _ChooseWifiPageState extends State<ChooseWifiPage> {
  bool isLoaded = false;
  bool connectingToWiFi = false;
  late Device device;
  late MessageManager messageManager;
  late Timer timer;
  ModelsRepository modelsRepository = ModelsRepository();

  @override
  void initState() {
    super.initState();
    messageManager = context.read<MessageManager>();
    if (widget.create){
      device = messageManager.newDevice;
    }else {
      device = messageManager.selectedDevice;
    }
    refresh();
    timer = Timer.periodic(Duration(seconds:5), (timer) async  {
      if (device.connectionStatus != ConnectionStatus.disconnected) {
        if (device.connectionStatus != ConnectionStatus.local && device.connectionStatus != ConnectionStatus.updating) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Solo puedes editar esto en local'),backgroundColor:Theme.of(context).errorColor),
          );
          Navigator.of(context).pop();
        }
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Se há perdido la coñexión con el dispositivo!!!.'),backgroundColor:Theme.of(context).errorColor),
        );
        Navigator.of(context).pop();
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
    timer.cancel();
    super.dispose();

  }
  void refresh() async {
    await Future.delayed(Duration(seconds:1));
    if (device.connectionStatus != ConnectionStatus.disconnected) {
      if (device.connectionStatus != ConnectionStatus.local && device.connectionStatus != ConnectionStatus.updating) {


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Solo puedes editar esto en local'),backgroundColor:Theme.of(context).errorColor),
        );
        Navigator.of(context).pop();
      }else{
        device.deviceStatus = DeviceStatus.updating;
        Map <String, dynamic> map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "getw",
        };
        if (widget.create){
          messageManager.sendForNew(jsonEncode(map));
        }else {
          if (device.connectionStatus == ConnectionStatus.local) {
            messageManager.send(jsonEncode(map), true);
          } else {
            messageManager.send(jsonEncode(map), false);
          }
        }
        await Future.delayed(Duration(seconds: 5));
        map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "getcw",
        };
        if (widget.create){
          messageManager.sendForNew(jsonEncode(map));
        }else {
          if (device.connectionStatus == ConnectionStatus.local) {
            messageManager.send(jsonEncode(map), true);
          } else {
            messageManager.send(jsonEncode(map), false);
          }
        }
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Se há perdido la coñexión con el dispositivo!!!.'),backgroundColor:Theme.of(context).errorColor),
      );
      Navigator.of(context).pop();
    }
  }
  @override
  Widget build(BuildContext context) {
    messageManager = context.watch<MessageManager>();
    if (widget.create){
      device = messageManager.newDevice;
    }else {
      device = messageManager.selectedDevice;
    }
    if(device.deviceStatus == DeviceStatus.updating) {
      isLoaded = false;
    }else{
      isLoaded = true;
    }
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isscrolled){
          return <Widget>[
            SliverAppBar(
              title: Text('Red de "${device.name }" '),
              pinned:false,
              floating: true,
              forceElevated: isscrolled,
              actions: [
                IconButton(icon: Icon(Icons.settings), onPressed: (){
                  Navigator.of(context).pushNamed("/settings");
                }),
                IconButton(icon: Icon(Icons.refresh), onPressed: (){
                  refresh();
                })
              ],
            ),
          ];
        },
        body: backdropFilter(Container(
          child: SingleChildScrollView(
            child: Column(
              children: getList()
            ),
          ),
        ),)
      ),
    );
  }
  List<Widget> getList(){
    List<Widget> list = [];
    if (device.deviceStatus == DeviceStatus.updating){
      list.add(LinearProgressIndicator());
    }else if (device.connectedToWiFi && device.currentWifiNetwork != null){
      list.add(
        ListTile(
          leading: Icon(
            IconData(59648 + (int.parse(device.currentWifiNetwork!.signalLevel)), fontFamily: 'signal_wifi'),size: 30,),
          title: Text('${device.currentWifiNetwork!.ssid!}'),
          subtitle: Text('Conectada'),
          trailing: IconButton(icon: Icon(Icons.settings,color: Theme.of(context).accentColor,),onPressed: (){}),

        )
      );
      list.add(Divider());
    }
    if (device.wifiNetworkList.isNotEmpty) {
      device.wifiNetworkList.forEach((wifiNetwork) {
        if (device.ssid != wifiNetwork.ssid) {
          int signal = 59648 +
              (int.parse(wifiNetwork.signalLevel));
          ListTile listTile = ListTile(
            leading: Icon(
              IconData(signal, fontFamily: 'signal_wifi'), size: 30,),
            title: Text('${wifiNetwork.ssid!}'),
            trailing: (wifiNetwork.security != "")
                ? Icon(Icons.lock, size: 16)
                : Text(""),
            selected: false,
            onTap: () async {
              String? password = await showDialog(context: context,
                  builder: (builder) =>
                      EnterPasswordDialog(title: wifiNetwork.ssid));
              if (password != null) {
                connectToWiFi(wifiNetwork, password);
                refresh();
              }
            },
          );
          list.add(listTile);
        }
      });

    }else{
      list.add(Text('No se encontraron redes'));
    }
    list.add(Divider());
    list.add(getButtons());
    return list;
  }
  Widget getButtons() {
    if (widget.create) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  child: Text(
                      "SALTAR"
                  ),
                  onPressed: () {
                    device.connectedToWiFi = false;
                    device.ssid = "";
                    Navigator.of(context).pushNamed("/device_configuration",
                        arguments: {"device": device.toDatabaseJson()});
                  }
              ),
              ElevatedButton(
                  child: Text(
                      "SIGUIENTE"
                  ),
                  onPressed: () {
                    if (device.connectedToWiFi) {
                      device.ssid = device.currentWifiNetwork!.ssid;
                      Navigator.of(context).pushNamed("/device_configuration",
                          arguments: {
                            "device": device.toDatabaseJson()
                          });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(
                            'Debe conectar el dispositivo a una red para continuar. ')),
                      );
                    }
                  }
              ),
            ],
          ),
        ),

      );
    }else{
      return Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: EdgeInsets.only(right: 16),
          child: TextButton(
            child: Text(
                "LISTO"
            ),
            onPressed: () {
              Navigator.of(context).pop();
            }
          ),
        ),
      );
    }
  }

  Widget backdropFilter( Widget child) {
    if (isLoaded && !connectingToWiFi){
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

  Future<void> connectToWiFi(WifiNetwork network, String password) async {
    device.deviceStatus = DeviceStatus.updating;
    Map <String, dynamic> map = {
      "t":"devices/" + device.mac.toUpperCase().substring(3),
      "a":"connectwifi",
      "d":{
        "ssid":"${network.ssid.toString()}",
        "pass": password
      }
    };
    if (widget.create){
      messageManager.sendForNew(jsonEncode(map));
    }else {
      if (device.connectionStatus == ConnectionStatus.local) {
        messageManager.send(jsonEncode(map), true);
      } else {
        messageManager.send(jsonEncode(map), false);
      }
    }
  }

  Future<void> deleteWiFi() async {
    Map <String, dynamic> map = {
      "t":"devices/" + device.mac.toUpperCase().substring(3),
      "a":"deletew"
    };
    if (widget.create){
      messageManager.sendForNew(jsonEncode(map));
    }else {
      if (device.connectionStatus == ConnectionStatus.local) {
        messageManager.send(jsonEncode(map), true);
      } else {
        messageManager.send(jsonEncode(map), false);
      }
    }
  }
}

class EnterPasswordDialog extends StatefulWidget{
  EnterPasswordDialog({required this.title});
  final String title;
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
                    setState(() {
                      _obscureText = value!;
                    });

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
