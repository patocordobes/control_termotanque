import 'dart:async';
import 'dart:convert';
import 'package:control_termotanque/models/auth/user_model.dart';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:magnifier/magnifier.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:provider/provider.dart';

WifiConfiguration ? wifiConfiguration4;

class DevicePage extends StatefulWidget {
  const DevicePage({Key? key}) : super(key: key);
  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {

  bool isLoaded = false;
  ModelsRepository modelsRepository = ModelsRepository();
  User user = User();
  bool magnifier = false;
  double magnifierSize = 100;
  late Timer timerTemp;
  late Timer timerAll;

  late Timer timer;
  late MessageManager messageManager;
  late Device device;
  
  @override
  void initState() {
    
    super.initState();
    modelsRepository.getUser.then((user) {
      setState(() {
        this.user = user;
      });
    });
    refresh();
    timerTemp = Timer.periodic(Duration(seconds:10), (timer) {
      Map <String, dynamic> map = {
        "t":"devices/" + device.mac.toUpperCase().substring(3),
        "a":"gett",
      };
      if (device.connectionStatus == ConnectionStatus.local) {
        messageManager.send(jsonEncode(map),true);
      }else{
        messageManager.send(jsonEncode(map),false);
      }
    });
    timerAll = Timer.periodic(Duration(seconds:10), (timer) {
      if (!isLoaded) {
        Map <String, dynamic> map = {
          "t":"devices/" + device.mac.toUpperCase().substring(3),
          "a":"get",
        };
        if (device.connectionStatus == ConnectionStatus.local) {
          messageManager.send(jsonEncode(map),true);
        }else{
          messageManager.send(jsonEncode(map),false);
        }
      }
    });
    timer = Timer.periodic(Duration(seconds:1), (timer) async  {
      if (device.connectionStatus == ConnectionStatus.disconnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Se há perdido la coñexión con el dispositivo!!!.'),backgroundColor:Theme.of(context).errorColor),
        );
        Navigator.of(context).pop();
      }
    });
  }
  void refresh() async {

    await Future.delayed(Duration(seconds:2));

    Map <String, dynamic> map = {
      "t":"devices/" + device.mac.toUpperCase().substring(3),
      "a":"gett",
    };
    if (device.connectionStatus == ConnectionStatus.local) {
      messageManager.send(jsonEncode(map),true);
    }else{
      messageManager.send(jsonEncode(map),false);
    }

    map = {
      "t":"devices/" + device.mac.toUpperCase().substring(3),
      "a":"get",
    };
    if (device.connectionStatus == ConnectionStatus.local) {
      messageManager.send(jsonEncode(map),true);
    }else{
      messageManager.send(jsonEncode(map),false);
    }
  }
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }
  @override
  void dispose(){

    timerAll.cancel();
    timerTemp.cancel();
    timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    messageManager = context.watch<MessageManager>();
    device = messageManager.selectedDevice;

    if(device.deviceStatus == DeviceStatus.updating) {
      isLoaded = false;
    }else{
      isLoaded = true;
    }

    String temperatureString= "";
    int temperature = 0;
    double min =  0;
    double max = 0;
    double interval = 0;
    double minorTicksPerInterval = 0;
    if (user.celsius){
      min = -20;
      max = 100;
      interval = 10;
      minorTicksPerInterval = 5;
      temperature = device.temperature;
      temperatureString = "${(temperature > 120 )? "120": (temperature < -20 )? "-20": temperature} °C";
    }else{
      min = -10;
      max = 220;
      interval = 20;
      minorTicksPerInterval = 5;
      temperature = (device.temperature * 1.8 + 32).toInt() ;
      temperatureString = "${(temperature > 248 )? "248": (temperature < -4 )? "-4": temperature} °F";
    }



    return Magnifier(
      enabled: magnifier,
      scale: 1.5,
      size: Size(magnifierSize, magnifierSize),
      painter: CrosshairMagnifierPainter(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text('"${device.name }" '),
              (isLoaded)?Container():CircularProgressIndicator()
            ],
          ),
          actions: [
            IconButton(icon: Icon(Icons.settings), onPressed: (){
              Navigator.of(context).pushNamed("/settings");
            }),
          ],
        ),
        body:  SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                (isLoaded)?Container():LinearProgressIndicator(),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 4.0,
                        child: Column(
                          children: [
                            ListTile(
                                title:Text("Estado de la resistencia: "),
                                trailing: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(color:(device.resistance)?Colors.blue.shade400:Colors.transparent,blurRadius: 10,spreadRadius: 10)
                                    ],
                                    shape: BoxShape.circle,
                                      color: (device.resistance)?Colors.blue.shade500:Colors.blue.shade900,
                                  ),
                                )
                            ),
                            ListTile(
                                title:Text("Temperatura: "),
                                trailing: Text(temperatureString,style: Theme.of(context).textTheme.headline3)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [

                    Container(
                      width: MediaQuery.of(context).size.width *0.5,
                      height: MediaQuery.of(context).size.width *0.5,
                      child: Stack(
                        children: [
                          SfRadialGauge(
                            axes: <RadialAxis>[
                              RadialAxis(
                                radiusFactor: 0.90,
                                ticksPosition: ElementsPosition.outside,
                                labelsPosition: ElementsPosition.outside,
                                minorTicksPerInterval: minorTicksPerInterval,
                                axisLineStyle: AxisLineStyle(
                                  thicknessUnit: GaugeSizeUnit.factor,
                                  thickness: 0.1,
                                ),

                                majorTickStyle: MajorTickStyle(
                                    length: 0.1, thickness: 2, lengthUnit: GaugeSizeUnit.factor),
                                minorTickStyle: MinorTickStyle(
                                    length: 0.05, thickness: 1.5, lengthUnit: GaugeSizeUnit.factor),
                                minimum: min,
                                maximum: max,
                                interval: interval,
                                startAngle: 115,
                                endAngle: 65,
                                ranges: <GaugeRange>[
                                  GaugeRange(
                                      startValue: min,
                                      endValue: max,
                                      startWidth: 0.1,
                                      sizeUnit: GaugeSizeUnit.factor,
                                      endWidth: 0.1,
                                      gradient: SweepGradient(
                                        stops: <double>[0.142857142, 0.28571428, 0.75],
                                        colors: <Color>[Colors.green, Colors.yellow, Colors.red])
                                  )
                                ],
                                pointers: <GaugePointer>[
                                  NeedlePointer(
                                  value: temperature.toDouble(),
                                      needleColor: Theme.of(context).textTheme.bodyText1!.color,
                                      tailStyle: TailStyle(
                                          length: 0.18,
                                          width: 4,
                                          color: Theme.of(context).textTheme.bodyText1!.color ,
                                          lengthUnit: GaugeSizeUnit.factor,
                                      ),

                                      needleLength: 0.68,
                                      needleStartWidth: 1,
                                      needleEndWidth: 4,
                                      knobStyle: KnobStyle(
                                          knobRadius: 0.07,
                                          color: Theme.of(context).dialogBackgroundColor,
                                          borderWidth: 0.05,
                                          borderColor: Theme.of(context).textTheme.bodyText1!.color),
                                      lengthUnit: GaugeSizeUnit.factor
                                  )
                                ],
                                annotations: <GaugeAnnotation>[
                                  GaugeAnnotation(
                                      widget: Text(temperatureString,),
                                      positionFactor: 0.4,
                                      angle: 90)
                                ],
                              ),

                            ],


                          ),
                          Align(
                            alignment: Alignment.topRight,
                              child:IconButton(
                                onPressed: () {
                                  showDialog(context: context, builder: (_){
                                    return AlertDialog(
                                      title: Text("Informacion de la temperatura"),
                                      content: Text("Si la temperatura esta al maximo podria ser porque el medidor esta fallando o esta deconectado del dispositivo.")
                                    );
                                  });
                                },
                                icon: Icon(Icons.info_outline),
                              )
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child:Card(
                        elevation: 4.0,
                        child: Column(
                          children: [
                            ListTile(
                              title:Text("Temperatura instantanea"),
                              trailing: Switch(
                                value: device.prog0,
                                onChanged: (value) {
                                  setState(() {
                                    updateDevice({"p0":(value ?"1":"0")});
                                    isLoaded = false;
                                  });
                                },
                              ),
                            ),
                            NumericStepButton(
                              initialValue: device.temp0,
                              minValue: 0,
                              maxValue: 100,
                              onChanged: (value) {
                                device.temp0 = value;
                              },
                              updateValue: (){
                                updateDevice({"t0":device.temp0});
                                isLoaded = false;
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child:Column(
                        children: [
                          Card(
                            elevation: 4.0,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Text("Programa 1"),
                                  trailing: Switch(
                                    value: device.prog1,
                                    onChanged: (value) {
                                      setState(() {
                                        updateDevice({"p1":(value ?"1":"0")});
                                        isLoaded = false;
                                      });
                                    },
                                  ),
                                ),
                                ListTile(
                                  leading: OutlinedButton(
                                    child: Text("${device.time1}"),
                                    onPressed: () async {
                                      final TimeOfDay? result = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                      setState(() {
                                        if (result != null) {
                                          updateDevice({"h1":result.format(context)});
                                          isLoaded = false;
                                        }
                                      });
                                    },
                                  ),
                                  title: NumericStepButton(
                                    initialValue: device.temp1,
                                    minValue: 0,
                                    maxValue: 100,
                                    onChanged: (value) {
                                      setState(() {
                                        device.temp1 = value;
                                      });
                                    },
                                    updateValue: (){
                                      updateDevice({"t1":device.temp1});
                                      isLoaded = false;
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          Card(
                            elevation: 4.0,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Text("Programa 2"),
                                  trailing: Switch(
                                    value: device.prog2,
                                    onChanged: (value) {
                                      setState(() {
                                        updateDevice({"p2":(value ?"1":"0")});
                                        isLoaded = false;
                                      });
                                    },
                                  ),
                                ),
                                ListTile(
                                  leading: OutlinedButton(
                                    child: Text("${device.time2}"),
                                    onPressed: () async {
                                      final TimeOfDay? result = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                      setState(() {
                                        if (result != null) {
                                          updateDevice({"h2":result.format(context)});
                                          isLoaded = false;
                                        }
                                      });
                                    },
                                  ),
                                  title: NumericStepButton(
                                    initialValue: device.temp2,
                                    minValue: 0,
                                    maxValue: 100,
                                    onChanged: (value) {
                                      setState(() {
                                        device.temp2 = value;
                                      });
                                    },
                                    updateValue: (){
                                      updateDevice({"t2":device.temp2});
                                      isLoaded = false;
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          Card(
                            elevation: 4.0,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Text("Programa 3"),
                                  trailing: Switch(
                                    value: device.prog3,
                                    onChanged: (value) {
                                      setState(() {
                                        updateDevice({"p3":(value ?"1":"0")});
                                        isLoaded = false;
                                      });
                                    },
                                  ),
                                ),
                                ListTile(
                                  leading: OutlinedButton(
                                    child: Text("${device.time3}"),
                                    onPressed: () async {
                                      final TimeOfDay? result = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                      setState(() {
                                        if (result != null) {
                                          updateDevice({"h3":result.format(context)});
                                          isLoaded = false;
                                        }
                                      });
                                    },
                                  ),
                                  title: NumericStepButton(
                                    initialValue:device.temp3,
                                    minValue: 0,
                                    maxValue: 100,
                                    onChanged: (value) {
                                      setState(() {
                                        device.temp3 = value;
                                      });
                                    },
                                    updateValue: (){
                                      updateDevice({"t3":device.temp3});
                                      isLoaded = false;
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          //TextButton.icon(onPressed: (){
                          //  Navigator.of(context).pushNamed("/historical");
                          //},icon: Icon(Icons.bar_chart), label: Text("Historial de temperaturas y tiempos")),
                          //Container(
                          //  width: MediaQuery.of(context).size.width,
                          //  height: MediaQuery.of(context).size.width
                          //)

                        ],
                      ),
                    )
                  ]
                )
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: (){

          },
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          tooltip:"Lupa",
          icon: Row(
            children: [
              Icon(Icons.search),
              Text("Lupa"),
              Switch(
                value: magnifier,
                onChanged: (value){
                  setState(() {
                    magnifier = value;
                  });
                },
              )
            ],
          ),
          label: Container(
            width:MediaQuery.of(context).size.width *0.3,
            child: Slider(
              activeColor: Theme.of(context).accentColor,
              inactiveColor: Theme.of(context).accentColor.withOpacity(0.7),
              value: magnifierSize,
              divisions: 10,
              min: 20,
              max: 300,
              label: "Tamaño",
              onChanged: (value){
                setState(() {
                  magnifierSize = value;
                });
              },
            ),
          ),

        ),
      ),
    );
  }

  void updateDevice(Map <String, dynamic> data) async {
    device.deviceStatus = DeviceStatus.updating;
    Map <String, dynamic> map = {
      "t":"devices/" + device.mac.toUpperCase().substring(3),
      "a":"set",
      "d": data
    };
    if (device.connectionStatus == ConnectionStatus.local) {
      messageManager.send(jsonEncode(map),true);
    }else{
      messageManager.send(jsonEncode(map),false);
    }
  }
}
class NumericStepButton extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialValue;


  final ValueChanged<int> onChanged;
  final void Function() updateValue;

  NumericStepButton(
      {Key? key, this.minValue = 0, this.maxValue = 10, required this.onChanged, required this.updateValue, required this.initialValue})
      : super(key: key);

  @override
  State<NumericStepButton> createState() {
    return _NumericStepButtonState();
  }
}

class _NumericStepButtonState extends State<NumericStepButton> {
  late Timer timer;
  int counter = 0;
  bool change = false;
  @override
  void initState(){
    counter = widget.initialValue;
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onLongPress: () {
            timer = Timer.periodic(Duration(milliseconds: 50), (t) {
              setState((){
                rest();
              });
            });
          },
          onLongPressUp: () {
            widget.updateValue();
            timer.cancel();
          },
          child: IconButton(

            onPressed: () {
              setState(() {
                rest();
                widget.updateValue();
              });
            },
            icon: Icon(Icons.remove),
          ),
        ),
        Text(
          '$counter ° C',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
        GestureDetector(
          onLongPress: () {

            timer = Timer.periodic(Duration(milliseconds: 50), (t) {
              setState(() {
                sum();
              });
            });
          },
          onLongPressUp: () {
            widget.updateValue();
            timer.cancel();
          },
          child: IconButton(
            onPressed: () {
              setState(() {
                sum();
                widget.updateValue();
              });
            },
            icon: Icon(Icons.add),
          ),
        ),
      ],
    );
  }
  void sum(){
    if (counter < widget.maxValue) {
      counter++;
    }
    widget.onChanged(counter);
  }
  void rest(){
    if (counter > widget.minValue) {
      counter--;
    }
    widget.onChanged(counter);
  }
}