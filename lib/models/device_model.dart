import 'dart:convert';
import 'package:control_termotanque/models/models.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'dart:async';

enum ConnectionStatus {
  local,
  mqtt,
  updating,
  connecting,
  disconnected
}
enum DeviceStatus{
  updating,
  updated
}
enum SoftwareStatus{
  upgrading,
  upgraded,
  outdated
}
enum WifiStatus{
  connected,
  connecting,
  disconnecting,
  disconnected,
  scanning,
  getting
}
enum HistoricalStatus{
  done,
  updating,
}
class Device {
  int? id;
  String version = "1.1.1";
  String mac;
  bool resistance = false;
  int temperature = 0;
  String name = "";
  bool connectedToWiFi = false;
  String ssid = "";
  String brand = "";
  int capacity = 0;
  bool prog0 = false;
  int temp0 = 0;
  bool prog1 = false;
  int temp1 = 0;
  String time1 = "00:00";
  bool prog2 = false;
  int temp2 = 0;
  String time2 = "00:00";
  bool prog3 = false;
  int temp3 = 0;
  String time3 = "00:00";
  int amountTubes = 0;
  double watts = 0;
  String address;
  
  
  bool serverConnected = false;
  ModelsRepository modelsRepository = ModelsRepository();
  SoftwareStatus softwareStatus = SoftwareStatus.upgraded;
  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;
  DeviceStatus deviceStatus = DeviceStatus.updated;
  WifiStatus wifiStatus = WifiStatus.disconnected;
  HistoricalStatus historicalStatus = HistoricalStatus.done;
  late Timer updateDeviceConnection;
  int numberOfDisconnections = 3;
  WifiNetwork? currentWifiNetwork;
  List<WifiNetwork> wifiNetworkList = [];
  List<Point> points = [];

  String temps = "";

  Device({
    this.id,
    this.version = "1.1.1",
    required this.mac,
    this.address = "",
    this.name = "",
    this.connectedToWiFi = false,
    this.ssid = "",
    this.brand = "",
    this.capacity = 0,
    this.amountTubes = 0,
    this.watts = 0,
    this.prog0 = false,
    this.temp0 = 0,
    this.prog1 = false,
    this.temp1 = 0,
    this.time1 = "00:00",
    this.prog2 = false,
    this.temp2 = 0,
    this.time2 = "00:00",
    this.prog3 = false,
    this.temp3 = 0,
    this.time3 = "00:00",

  }){
    if (version != "1.1.9") {
      softwareStatus = SoftwareStatus.outdated;
    }else{
      softwareStatus = SoftwareStatus.upgraded;
    }
    if (connectedToWiFi){
      wifiStatus =WifiStatus.connected;
    }else{
      wifiStatus =WifiStatus.disconnected;
    }
    for(int i = 0; i < 24; i++){
      DateTime now = DateTime.now();
      points.add(Point(
          dateTime: now,
          device: this));
    }
  }

  Future<bool> isConnectedLocally() async {
    bool connected = false;
    WifiConfiguration wifiConfiguration = WifiConfiguration();
    bool selfConnected = await wifiConfiguration.isConnectedToWifi(
        "Dinamico${this.mac.substring(3).toUpperCase()}");
    if (!selfConnected) {
      if (this.ssid != "") {
        bool localConnected = await wifiConfiguration.isConnectedToWifi(
            this.ssid);
        if (localConnected) {
          connected = true;
        }
      }
    } else {
      connected = true;
    }
    return connected;
  }

  void listen(String message, {String address= "",required bool local}) async {

    try {
      Map <String, dynamic> map = json.decode(message);
      if (map["t"] == "devices/${mac.toUpperCase().substring(3)}") {
        deviceStatus = DeviceStatus.updated;
        print("json: $map");
        switch (map["a"]) {
          case "connectwifi":
            if (map["status"] != "error"){
              print("no se conecto");
            }
            break;
          case "switch":
            resistance = (map["d"]["o"] == 1)? true : false;
            break;
          case "geth":
            //historicalStatus = HistoricalStatus.done;
            break;
          case "getip":
            print("Ip: ${map["d"]["ip"]}");
            this.address = map["d"]["ip"] ;
            break;
          case "getmqtt":
            print("Mqtt: ${map["d"]["m"]}");
            serverConnected = (map["d"]["m"] == 1)? true : false;
            break;
          case "getv":
            print("Version: ${map["d"]["v"]}");
            this.version = map["d"]["v"];
            if (version != "1.1.9") {
              softwareStatus = SoftwareStatus.outdated;
            }else{
              softwareStatus = SoftwareStatus.upgraded;
            }
            break;
          case "sets":
            brand = map["d"]["m"];
            capacity = map["d"]["c"];
            amountTubes = map["d"]["tb"];
            watts = double.parse("${map["d"]["w"]}");
            break;
          case "setota":
            softwareStatus = SoftwareStatus.upgrading;
            break;
          case "gets":
            brand = map["d"]["m"];
            capacity = map["d"]["c"];
            amountTubes = map["d"]["tb"];
            print("wats: ${map["d"]["w"]}");
            watts = double.parse("${map["d"]["w"]}");

            break;
          case "get":
            fromArduinoJson(map);
            break;
          case "set":
            fromArduinoJson(map);
            break;
          case "gett":
            resistance = (map["d"]["r"] == 1) ? true : false;
            temperature = map["d"]["t"];
            break;
          case "getcw":
            if (map["d"]["s"] != "") {
              int dBm = int.parse(map["d"]["r"].toString());
              double quality = 0;
              if (dBm <= -100)
                quality = 0;
              else if (dBm >= -50)
                quality = 100;
              else
                quality = 2 * (dBm + 100);
              quality = quality * 4 / 100;
              currentWifiNetwork = WifiNetwork(
                  signalLevel: quality.toInt().toString(),
                  ssid: map["d"]["s"].toString());
              connectedToWiFi = true;
              ssid = currentWifiNetwork!.ssid!;
              wifiStatus = WifiStatus.connected;
            } else {
              currentWifiNetwork = null;
              connectedToWiFi = false;
              wifiStatus = WifiStatus.disconnected;
            }
            break;
          case "deletew":
            ssid = "";
            connectedToWiFi = false;
            currentWifiNetwork = null;
            wifiStatus = WifiStatus.disconnected;
            break;
          default:
            break;
        }


        if (connectionStatus == ConnectionStatus.updating || connectionStatus == ConnectionStatus.connecting) {
          if (!local) {
            connectionStatus = ConnectionStatus.mqtt;
          } else {
            connectionStatus = ConnectionStatus.local;
          }
        }
        if (!local){
          serverConnected = true;
        }
        if (this.id != null){
          modelsRepository.updateDevice(device:this);
        }

      }
    } catch (e) {
      try {
        print("json: $message");
        if (historicalStatus == HistoricalStatus.updating) {

          if (message.substring(2, 3) == "t") {
            temps = message;
            for(int i = 0; i < 24; i++){
              DateTime now = DateTime.now();
              points.add(Point(
                  dateTime: now,
                  device: this));
            }
          }
          if (message.substring(2, 3) == "r") {
            int day = int.parse(message.split("r")[1].split('":')[0]);
            temps = temps.split('{"t$day":[')[1];
            try {
              temps = temps.split(',]}')[0];
            } catch (e) {
              temps = temps.split(',]')[0];
            }
            print("Actualizando temperaturas y tiempos del dia: $day");
            DateTime now = DateTime.now();
            int month = now.month;
            if (now.day < day) {
              month --;
            }
            for (int i = 0; i < 24; i++) {
              DateTime timeDay = DateTime(
                  now.year,
                  month,
                  day,
                  i,
                  0,
                  0,
                  0,
                  0);
              print("timeDay: $timeDay");
              int temp = 0;
              try {
                temp = int.parse(temps.split(",")[i]);
              }catch (e) {}
              int rest = 0;
              try {
                rest = int.parse(message.split(",")[i]);
              }catch (e) {}
              points[i] = Point(
                  temperature: temp,
                  resistanceTime: rest,
                  dateTime: timeDay,
                  device: this);

              points[i].id = await modelsRepository.createPoint(point: points[i]);
            }
            historicalStatus = HistoricalStatus.done;
          }
        }
      }catch (e) {
        print(e);
      }
    }

    try {
      Map <String, dynamic> map = json.decode(message);
      List<dynamic> listWiFi = map["d"] as List<dynamic>;
      wifiNetworkList = [];
      deviceStatus = DeviceStatus.updated;
      print(map);
      listWiFi.forEach((wifi) {
        Map<String, dynamic> wifiMap = wifi;
        try{
          int dBm = int.parse(wifiMap["r"].toString());
          double quality = 0;
          if (dBm <= -100)
            quality = 0;
          else if (dBm >= -50)
            quality = 100;
          else
            quality = 2 * (dBm + 100);
          quality = quality * 4 / 100;
          wifiNetworkList.add(WifiNetwork(

              signalLevel: quality.toInt().toString(),
              ssid: wifiMap["s"].toString(),
              security: wifiMap["e"].toString()));
        }catch (e){

        }
      });
      if (connectedToWiFi){
        wifiStatus = WifiStatus.connected;
      }else{
        wifiStatus = WifiStatus.disconnected;
      }
      deviceStatus = DeviceStatus.updated;
      if (connectionStatus == ConnectionStatus.updating || connectionStatus == ConnectionStatus.connecting) {
        if (!local) {
          connectionStatus = ConnectionStatus.mqtt;
        } else {
          connectionStatus = ConnectionStatus.local;
        }
      }
      if (!local){
        serverConnected = true;
      }


      if (this.id != null){
        modelsRepository.updateDevice(device:this);
      }
    } catch (e) {

    }
  }

  factory Device.fromDatabaseJson(Map<String, dynamic> json) {
    return Device(
      id: json["id"],
      version: json["version"],
      mac: json["mac"],
      address: json["address"],
      name: json["name"],
      connectedToWiFi: (json["connected_wifi"] == 1) ? true : false,
      ssid: json["ssid"],
      brand: json["brand"],
      capacity: json["capacity"],
      amountTubes: json["amount_tubes"],
      watts: json["watts"],
      prog0: (json["prog0"] == 1) ? true : false,
      temp0: json["temp0"],
      prog1: (json["prog1"] == 1) ? true : false,
      temp1: json["temp1"],
      time1: json["time1"],
      prog2: (json["prog2"] == 1) ? true : false,
      temp2: json["temp2"],
      time2: json["time2"],
      prog3: (json["prog3"] == 1) ? true : false,
      temp3: json["temp3"],
      time3: json["time3"],
    );
  }

  Map <String, dynamic> toDatabaseJson() =>
      {
        "id": this.id,
        "version": this.version,
        "mac": this.mac,
        "address": this.address,
        "name": this.name,
        "connected_wifi": (this.connectedToWiFi) ? 1 : 0,
        "ssid": this.ssid,
        "brand": this.brand,
        "capacity": this.capacity,
        "amount_tubes": this.amountTubes,
        "watts": this.watts,
        "prog0": (this.prog0) ? 1 : 0,
        "temp0": this.temp0,
        "prog1": (this.prog1) ? 1 : 0,
        "temp1": this.temp1,
        "time1": this.time1,
        "prog2": (this.prog2) ? 1 : 0,
        "temp2": this.temp2,
        "time2": this.time2,
        "prog3": (this.prog3) ? 1 : 0,
        "temp3": this.temp3,
        "time3": this.time3,
      };

  Map <String, dynamic> toCreateDatabaseJson() =>
      {
        "version": this.version,
        "mac": this.mac,
        "address": this.address,
        "name": this.name,
        "connected_wifi": (this.connectedToWiFi) ? 1 : 0,
        "ssid": this.ssid,
        "brand": this.brand,
        "capacity": this.capacity,
        "amount_tubes": this.amountTubes,
        "watts": this.watts,
        "prog0": (this.prog0) ? 1 : 0,
        "temp0": this.temp0,
        "prog1": (this.prog1) ? 1 : 0,
        "temp1": this.temp1,
        "time1": this.time1,
        "prog2": (this.prog2) ? 1 : 0,
        "temp2": this.temp2,
        "time2": this.time2,
        "prog3": (this.prog3) ? 1 : 0,
        "temp3": this.temp3,
        "time3": this.time3,
      };

  Map <String, dynamic> toArduinoJson() =>
      {
        "p0": (this.prog0) ? 1 : 0,
        "t0": this.temp0,
        "p1": (this.prog1) ? 1 : 0,
        "t1": this.temp1,
        "h1": this.time1,
        "p2": (this.prog2) ? 1 : 0,
        "t2": this.temp2,
        "h2": this.time2,
        "p3": (this.prog3) ? 1 : 0,
        "t3": this.temp3,
        "h3": this.time3
      };

  Map <String, dynamic> toArduinoSetJson() =>
      {
        "m": this.brand,
        "tb": this.amountTubes,
        "c": this.capacity,
        "w": this.watts,
        "n": this.name,

      };

  void fromArduinoJson(Map<String, dynamic> json) {
    try {
      this.prog0 = (json["d"]["p0"] == 1) ? true : false;
      this.temp0 = json["d"]["t0"];
      this.prog1 = (json["d"]["p1"] == 1) ? true : false;
      this.temp1 = json["d"]["t1"];
      this.time1 = json["d"]["h1"];
      this.prog2 = (json["d"]["p2"] == 1) ? true : false;
      this.temp2 = json["d"]["t2"];
      this.time2 = json["d"]["h2"];
      this.prog3 = (json["d"]["p3"] == 1) ? true : false;
      this.temp3 = json["d"]["t3"];
      this.time3 = json["d"]["h3"];
      this.name = json["d"]["n"];
    } catch (e) {
      print(e);
    }
  }


}
