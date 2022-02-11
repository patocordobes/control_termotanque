import 'dart:async';
import 'dart:convert';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';


class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({Key? key,  this.create = true}) : super(key: key);

  final bool create;


  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {

  bool isLoaded = false;
  ModelsRepository modelsRepository = ModelsRepository();
  late Device device;
  late MessageManager messageManager;
  late Timer timer;
  late Timer timerRedirect ;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _termoCapacityController = TextEditingController();
  TextEditingController _termoWattsController = TextEditingController();
  TextEditingController _termoTubesController = TextEditingController();
  TextEditingController _termoMarcaController = TextEditingController();
  TextEditingController _deviceNameController = TextEditingController();
  bool changed = true;

  @override
  void initState() {
    super.initState();
    timerRedirect = Timer.periodic(Duration(seconds:40), (timer) { });
    messageManager = context.read<MessageManager>();
    if (widget.create){
      device = messageManager.newDevice;
    }else {
      device = messageManager.selectedDevice;
    }
    refresh();
    timer = Timer.periodic(Duration(milliseconds:1), (timer) async  {
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
              content: Text('Se ha perdido la conexión con el dispositivo!'),backgroundColor:Theme.of(context).errorColor),
        );
        Navigator.of(context).pop();
      }
    });
  }
  void refresh() async {
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
          "a": "gets",
        };
        messageManager.send(jsonEncode(map), true);
        map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "get",
        };

        messageManager.send(jsonEncode(map), true);
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Se ha perdido la conexión con el dispositivo!'),backgroundColor:Theme.of(context).errorColor),
      );
      Navigator.of(context).pop();
    }
  }
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
  @override
  void dispose() {
    timer.cancel();
    super.dispose();
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
    if (changed) {
      _deviceNameController..text = device.name;
      _termoCapacityController..text = device.capacity.toString();
      _termoWattsController..text = device.watts.toString();
      _termoTubesController..text = device.amountTubes.toString();
      _termoMarcaController..text = device.brand.toString();
      changed = false;
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("Configuración del dispositivo"),
          actions: [
            IconButton(icon: Icon(Icons.settings), onPressed: () {
              Navigator.of(context).pushNamed("/settings");
            }),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  color:Theme.of(context).primaryColor,
                  child: ListTile(
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
                  )
              ),
              (!isLoaded)?LinearProgressIndicator():Container(),
              form(),
              Divider(thickness: 2,),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: EdgeInsets.only(right: 16,left: 16),
                  child: Row(
                    children: [
                      (widget.create)?
                      Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text((widget.create)?"Paso 2 de 2":""),
                          )
                      ) : Expanded(child:Container()),
                      ElevatedButton(
                        child: Text(
                            "GUARDAR DISPOSITIVO"
                        ),
                        onPressed: (device.deviceStatus != DeviceStatus.updated)? null :  () async {
                          if (_formKey.currentState!.validate()) {
                            changed = true;
                            device.brand = _termoMarcaController.text;
                            device.capacity =
                                int.parse(_termoCapacityController.text);
                            device.amountTubes =
                                int.parse(_termoTubesController.text);
                            device.watts =
                                double.parse(_termoWattsController.text);
                            device.name = _deviceNameController.text;
                            print(device.toDatabaseJson());
                            setTermo();
                            setDevice();

                            timerRedirect.cancel();
                            timerRedirect = Timer.periodic(Duration(milliseconds:1), (timer) {
                              if (device.deviceStatus == DeviceStatus.updated){
                                timerRedirect.cancel();
                                if (widget.create) {
                                  modelsRepository.createDevice(
                                      device: device).then((value) {
                                    messageManager.updateDevices();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(content: Text(
                                          'Dispositivo guardado exitosamente'),
                                          backgroundColor: Colors.green),
                                    );

                                    messageManager.udpReceiver.close();
                                    messageManager.udpReceiver2.close();
                                    messageManager.update(updateWifi: true);;
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  });
                                } else {
                                  modelsRepository.updateDevice(
                                      device: device).then((value) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(content: Text(
                                          'Dispositivo editado exitosamente'),
                                          backgroundColor: Colors.green),
                                    );
                                    Navigator.of(context).pop();
                                  });
                                }
                              }
                            });
                            await Future.delayed(Duration(milliseconds: 3000),(){
                              timerRedirect.cancel();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )

    );
  }


  Widget form() {
    return Form(
        key: _formKey,
        child: Column(
            children: [
              ListTile(
                leading: const Text(""),
                title: Text("Termotanque:"),
              ),

              Divider(),
              ListTile(
                leading: const Icon(
                  IconData(0xe906, fontFamily: 'signal_wifi'), size: 30,),

                title: TextFormField(
                    controller: _termoMarcaController,

                    maxLength: 20,
                    validator: (val) {
                      if (val == null || val == "") {
                        return "Debe completar este campo";
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Marca del termotanque*: ",
                      hintText: "Marca del termotanque",
                    )
                ),
              ),
              ListTile(
                leading: const Icon(
                  IconData(0xe908, fontFamily: 'signal_wifi'), size: 30,),

                title: TextFormField(
                    controller: _termoCapacityController,

                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val != null && val != "") {
                        if (double.parse(val) < 1) {
                          return "La capacidad debe ser mayor o igual a 1";
                        }
                        if (double.parse(val) > 2000) {
                          return "La capacidad debe ser menor o igual a 100.";
                        }
                      } else {
                        return "Debe completar este campo.";
                      }
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                    decoration: InputDecoration(
                      labelText: "Capacidad (Litros)*: ",
                      hintText: "Capacidad (Litros) obligatorio",
                    )
                ),
              ),
              ListTile(
                leading: const Icon(
                  IconData(0xe909, fontFamily: 'signal_wifi'), size: 30,),
                title: TextFormField(
                    controller: _termoTubesController,

                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val != null && val != "") {
                        if (int.parse(val) < 1) {
                          return "La cantidad de tubos debe ser mayor o igual a 1";
                        }
                        if (int.parse(val) > 100) {
                          return "La cantidad de tubos debe ser menor o igual a 100.";
                        }
                      } else {
                        return "Debe completar este campo.";
                      }
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                    decoration: InputDecoration(
                      labelText: "Cantidad de tubos*: ",
                      hintText: "Cantidad de tubos obligatorio",
                    )
                ),

              ),
              ListTile(
                leading: const Icon(
                  IconData(0xe910, fontFamily: 'signal_wifi'), size: 30,),
                title: TextFormField(
                    controller: _termoWattsController,

                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val != null && val != "") {
                        if (double.parse(val) < 1) {
                          return "Los vatios deben ser mayor o igual a 1";
                        }
                        if (double.parse(val) > 10000) {
                          return "Los vatios deben ser menor o igual a 1000";
                        }
                      } else {
                        return "Debe completar este campo.";
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Vatios(w)*: ",
                      hintText: "Vatios (w) obligatorio",
                    )
                ),

              ),
              Divider(thickness: 2,),
              ListTile(
                leading: const Text(""),
                title: Text("Dispositivo:"),
              ),

              Divider(),
              ListTile(
                leading: Icon(
                  IconData(59653, fontFamily: 'signal_wifi'), size: 30,),

                title: TextFormField(
                    controller: _deviceNameController,
                    maxLength: 20,
                    validator: (val) {
                      if (val == null || val == "") {
                        return "Debe completar este campo.";
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Nombre del dispositivo*: ",
                      hintText: "Nombre del dispositivo",
                    )
                ),
              ),
            ]
        )
    );
  }

  void setDevice() async {
    device.deviceStatus = DeviceStatus.updating;
    Map <String, dynamic> map = {
      "t": "devices/" + device.mac.toUpperCase().substring(3),
      "a": "set",
      "d": device.toArduinoSetJson()
    };
    messageManager.send(jsonEncode(map), true);
  }

  void setTermo() async {
    device.deviceStatus = DeviceStatus.updating;
    Map <String, dynamic> map = {
      "t": "devices/" + device.mac.toUpperCase().substring(3),
      "a": "sets",
      "d": device.toArduinoSetJson()
    };
    messageManager.send(jsonEncode(map), true);
  }
}