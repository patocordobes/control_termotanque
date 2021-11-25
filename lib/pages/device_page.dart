import 'dart:async';
import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:control_termotanque/models/auth/user_model.dart';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/pages/historial_page.dart';
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
    timerAll = Timer.periodic(Duration(seconds:30), (timer) {
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
              content: Text('Se ha perdido la conexión con el dispositivo!'),backgroundColor:Theme.of(context).errorColor),
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
    int temperature = device.temperature;
    double min =  -20;
    double max = 100;

    if (!user.celsius){
      min = -10;
      max = 212;
    }
    if (temperature >= max || temperature <= min) {
      showDialog(context: context, builder: (_) {
        return AlertDialog(
            title: Text(
                "Advertencia del sensor de temperatura"),
            content: Text(
                "El sensonr esta fallando. \n - Podria ser porque esta desconectado del dispositivo.\n - Porque el sensor esta fallado.\n - O el dispositivo no puede leer correctamente el sensor")
        );
      });
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


    int temperature = device.temperature;
    double min =  -20;
    double max = 100;
    double interval = 10;
    double minorTicksPerInterval = 5;
    int minValue = 20;
    int maxValue = 85;

    int temp0 = (device.temp0 > maxValue )? maxValue: (device.temp0 < minValue )? minValue : device.temp0;
    int temp1 = (device.temp1 > maxValue )? maxValue: (device.temp1 < minValue )? minValue : device.temp1;
    int temp2 = (device.temp2 > maxValue )? maxValue: (device.temp2 < minValue )? minValue : device.temp2;
    int temp3 = (device.temp3 > maxValue )? maxValue: (device.temp3 < minValue )? minValue : device.temp3;
    String temperatureString = "${(temperature > max )? "$max": (temperature < min )? "$min": temperature} °C";
    if (!user.celsius){
      minValue = 68;
      maxValue = 185;
      min = -10;
      max = 212;
      interval = 20;
      minorTicksPerInterval = 5;
      temperature = (device.temperature * 1.8 + 32).toInt() ;
      temperatureString = "${(temperature > max )? "$max": (temperature < min )? "$min": temperature} °F";
      temp0 = (temp0 * 1.8 + 32).toInt() ;
      temp1 = (temp1 * 1.8 + 32).toInt() ;
      temp2 = (temp2 * 1.8 + 32).toInt() ;
      temp3 = (temp3 * 1.8 + 32).toInt() ;
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
            (temperature >= max || temperature <= min)?IconButton(
              onPressed: () {
                showDialog(context: context, builder: (_){
                  if (temperature >= max || temperature <= min){
                    return AlertDialog(
                        title: Text(
                            "Advertencia del sensor de temperatura"),
                        content: Text(
                            "El sensonr esta fallando. \n - Podria ser porque esta desconectado del dispositivo.\n - Porque el sensor esta fallado.\n - O el dispositivo no puede leer correctamente el sensor")
                    );
                  }else{
                    return AlertDialog(
                        title: Text(
                            "Informacion del sensor de temperatura"),
                        content: Text(
                            "El sensor esta funcionando correctamente")
                    );
                  }
                });
              },
              icon: Icon(Icons.warning),
            ): Container(),
            IconButton(icon: Icon(Icons.settings), onPressed: (){
              Navigator.of(context).pushNamed("/settings");
            }),
          ],
        ),
        body:  SafeArea(
          child: SingleChildScrollView(
            child: Column(

              children: [
                Container(
                  color: Theme.of(context).primaryColor,

                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color:(device.resistance)?Colors.red.shade400:Colors.transparent,blurRadius: 10,spreadRadius: 10)
                            ],
                            shape: BoxShape.circle,
                            color: (device.resistance)?Colors.red.shade500:Colors.red.shade900,
                          ),
                        ),
                          title:Text("Estado de la resistencia: "),
                          trailing: Text("${(device.resistance)?"Encendida":"Apagada"}")
                      ),
                      ListTile(
                          leading: Icon(Icons.thermostat_outlined),
                          title:Text("Temperatura: "),
                          trailing: Text(temperatureString,style: Theme.of(context).textTheme.headline3)
                      ),
                    ],
                  ),
                ),
                (isLoaded)?Container():LinearProgressIndicator(),
                Card(
                  elevation: 4.0,
                  child: Column(
                    children: [
                      ListTile(
                        title:Text("Temperatura instantánea"),
                        trailing: Switch(
                          value: device.prog0,
                          onChanged: (value) {
                            setState(() {
                              updateDevice({"p0":(value ?"1":"0")});
                              isLoaded = false;
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
                          },
                        ),
                      ),
                      NumericStepButton(
                        initialValue: temp0,
                        minValue: minValue,
                        maxValue: maxValue,
                        onChanged: (value) {
                          setState(() {
                            if (!user.celsius){
                              device.temp0 = ((value-32)*5/9).toInt();
                            }else{
                              device.temp0 = value;
                            }
                          });
                        },
                        updateValue: (){
                          int temp =  device.temp0;

                          updateDevice({"t0":temp});
                          isLoaded = false;
                        },
                      ),
                    ],
                  ),
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                    leading: Icon(Icons.speed,size: 40),
                    title: Text("Calibre radial de temperatura"),

                    children: [Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width ,
                          height: MediaQuery.of(context).size.width ,
                          child: Stack(
                            children: [
                              SfRadialGauge(
                                axes: <RadialAxis>[
                                  RadialAxis(
                                    axisLabelStyle: GaugeTextStyle(fontSize: 20),
                                    radiusFactor: 0.90,
                                    ticksPosition: ElementsPosition.outside,
                                    labelsPosition: ElementsPosition.outside,
                                    minorTicksPerInterval: minorTicksPerInterval,
                                    axisLineStyle: AxisLineStyle(
                                      thicknessUnit: GaugeSizeUnit.factor,
                                      thickness: 0.1,
                                    ),

                                    majorTickStyle: MajorTickStyle(
                                        length: 0.1, thickness: 3, lengthUnit: GaugeSizeUnit.factor),
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
                                            width: 6,
                                            color: Theme.of(context).textTheme.bodyText1!.color ,
                                            lengthUnit: GaugeSizeUnit.factor,
                                          ),

                                          needleLength: 0.70,
                                          needleStartWidth: 2,
                                          needleEndWidth: 6,
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
                                        if (temperature >= max || temperature <= min){
                                          return AlertDialog(
                                              title: Text(
                                                  "Advertencia del sensor de temperatura"),
                                              content: Text(
                                                  "El sensonr esta fallando. \n - Podria ser porque esta desconectado del dispositivo.\n - Porque el sensor esta fallado.\n - O el dispositivo no puede leer correctamente el sensor")
                                          );
                                        }else{
                                          return AlertDialog(
                                              title: Text(
                                                  "Informacion del sensor de temperatura"),
                                              content: Text(
                                                  "El sensor esta funcionando correctamente")
                                          );
                                        }
                                      });
                                    },
                                    icon: Icon(Icons.info_outline),
                                  )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ]
                ),
                ExpansionTile(
                    leading: Icon(Icons.alarm,size: 40),
                    title: Text("Objetivos"),
                    subtitle: Text("Se pueden establecer 3 objetivos"),
                    children: [
                      Card(
                        elevation: 4.0,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text("Objetivo 1"),
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
                            Padding(
                              padding: const EdgeInsets.only(left:16, bottom:10,right: 16),
                              child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Hora objetivo",style:Theme.of(context).textTheme.caption),
                                        OutlinedButton(
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
                                      ],
                                    ),
                                    Expanded(
                                      child: NumericStepButton(
                                        initialValue: temp1,
                                        minValue: minValue,
                                        maxValue: maxValue,
                                        onChanged: (value) {
                                          setState(() {
                                            if (!user.celsius){
                                              device.temp1 = ((value-32)*5~/9).toInt();
                                            }else{
                                              device.temp1 = value;
                                            }
                                          });
                                        },
                                        updateValue: (){
                                          int temp =  device.temp1;
                                          updateDevice({"t1":temp});
                                          isLoaded = false;
                                        },
                                      ),
                                    ),
                                  ]
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
                              title: Text("Objetivo 2"),
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
                            Padding(
                              padding: const EdgeInsets.only(left:16, bottom:10,right: 16),
                              child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Hora objetivo",style:Theme.of(context).textTheme.caption),
                                        OutlinedButton(
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
                                      ],
                                    ),
                                    Expanded(
                                      child: NumericStepButton(
                                        initialValue: temp2,
                                        minValue: minValue,
                                        maxValue: maxValue,
                                        onChanged: (value) {
                                          setState(() {
                                            if (!user.celsius){
                                              device.temp2 = ((value-32)*5~/9).toInt();
                                            }else{
                                              device.temp2 = value;
                                            }
                                          });
                                        },
                                        updateValue: (){
                                          int temp =  device.temp2;
                                          updateDevice({"t2":temp});
                                          isLoaded = false;
                                        },
                                      ),
                                    ),
                                  ]
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
                              title: Text("Objetivo 3"),
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
                            Padding(
                              padding: const EdgeInsets.only(left:16, bottom:10,right: 16),
                              child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Hora objetivo",style:Theme.of(context).textTheme.caption),
                                        OutlinedButton(
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
                                      ],
                                    ),
                                    Expanded(
                                      child: NumericStepButton(
                                        initialValue: temp3,
                                        minValue: minValue,
                                        maxValue: maxValue,
                                        onChanged: (value) {
                                          setState(() {
                                            if (!user.celsius){
                                              device.temp3 = ((value-32)*5~/9).toInt();
                                            }else{
                                              device.temp3 = value;
                                            }
                                          });
                                        },
                                        updateValue: (){
                                          int temp =  device.temp3;
                                          updateDevice({"t3":temp});
                                          isLoaded = false;
                                        },
                                      ),
                                    ),
                                  ]
                              ),
                            )
                          ],
                        ),
                      ),
                    ]
                ),
                OpenContainer(
                  openBuilder: (_, closeContainer) => OrdinalComboBarLineChart(title: 'Historial', animate: true),
                  onClosed: (Never? never){
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
                    timerAll = Timer.periodic(Duration(seconds:30), (timer) {
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

                  },
                  tappable: false,
                  closedColor: Theme.of(context).dialogBackgroundColor,
                  openColor: Colors.transparent,
                  closedBuilder: (_, openContainer) => TextButton.icon(onPressed: (){

                    timerAll.cancel();
                    timerTemp.cancel();
                    openContainer();
                  },icon: Icon(Icons.bar_chart), label: Text("Historial de temperaturas y tiempos")),

                ),

                Container(
                    width: MediaQuery.of(context).size.width,
                    height: 100
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
              Text("Lupa",style:Theme.of(context).textTheme.button),
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
    return Column(

      children: [
        Text("Temperatura deseada",style:Theme.of(context).textTheme.caption),
        Row(
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
              '$counter ° ',
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