import 'dart:async';
import 'dart:convert';
import 'package:control_termotanque/models/device_model.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:udp/udp.dart';


enum ManagerStatus{
  started,
  starting,
  updating,
  updated,
  stopped
}
class MessageManager with ChangeNotifier {
  late MqttServerClient mqttClient;
  late UDP udpReceiver;
  late UDP udpReceiver2;
  late UDP udpReceiverForNew;
  late UDP udpSenderForNew;
  late UDP udpSender;
  ManagerStatus status = ManagerStatus.stopped;
  List<Device> devices = [];
  late Device selectedDevice;
  Device newDevice = Device(mac: "");
  Future<void> updateDevices() async {
    ModelsRepository modelsRepository = ModelsRepository();
    devices = await modelsRepository.getDevices();
    notifyListeners();
  }
  void update() async {
    if (status == ManagerStatus.started || status == ManagerStatus.updated) {
      status = ManagerStatus.updating ;
      notifyListeners();
      udpSender = await UDP.bind(Endpoint.broadcast(port: Port(8888)));
      udpReceiver = await UDP.bind(Endpoint.any(port: Port(8890)));
      udpReceiver2 = await UDP.bind(Endpoint.any(port: Port(8891)));
      if (mqttClient.connectionStatus!.state != MqttConnectionState.connected) {
        mqttClient = await connectToMQTT();
        if (mqttClient.connectionStatus!.state == MqttConnectionState.connected) {
          listenMqtt();
        }
      }else{
        listenMqtt();
      }
      listenUDP();
      updateDevicesConnection();
      status = ManagerStatus.updated;
    }
  }
  void start() async {

    if (status == ManagerStatus.stopped) {

      status = ManagerStatus.starting;
      udpSender = await UDP.bind(Endpoint.broadcast(port: Port(8888)));
      udpReceiver = await UDP.bind(Endpoint.any(port: Port(8890)));
      udpReceiver2 = await UDP.bind(Endpoint.any(port: Port(8891)));
      mqttClient = await connectToMQTT();
      ModelsRepository modelsRepository = ModelsRepository();
      devices = await modelsRepository.getDevices();
      try {
        listenMqtt();
      }catch (e){
      }
      listenUDP();
      updateDevicesConnection();
      status = ManagerStatus.started;

    }

  }
  Future<void> stop() async {
    if (status != ManagerStatus.stopped || status == ManagerStatus.started) {
      udpSender.close();
      udpReceiver.close();
      udpReceiver2.close();
      mqttClient.disconnect();
      status = ManagerStatus.stopped;
    }
  }
  void addDevice(Device device){
    this.devices.add(device);
    notifyListeners();
  }
  void removerDevice(Device device){
    this.devices.remove(device);
    notifyListeners();
  }
  void disconnectDevice(Device device){
    device.connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }
  Future<void> updateDeviceConnection(Device device) async {
    device.connectionStatus = ConnectionStatus.updating;
    updateDevicesConnection();
  }
  Future<void> updateDevicesConnection() async {
    status = ManagerStatus.updating;
    for (int i = 0;i < getDevices.length;i++) {

      Device device = getDevices[i];
      if (device.connectionStatus != ConnectionStatus.disconnected) {
        device.deviceStatus = DeviceStatus.updating;
        device.connectionStatus = ConnectionStatus.updating;
        notifyListeners();
        Map <String, dynamic> map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "getv"
        };
        bool local = true;
        if (await device.isConnectedLocally()) {
          this.send(jsonEncode(map), true);
        } else {
          local = false;
          try {
            this.send(jsonEncode(map), false);
          } catch (e) {

          }
        }
        try {
          if (device.updateDeviceConnection.isActive){
            device.updateDeviceConnection.cancel();
          }
        }catch (e){

        }

        device.updateDeviceConnection =
        Timer.periodic(Duration(seconds: 3), (timer) {
          if (device.connectionStatus == ConnectionStatus.updating){
            device.numberOfDisconnections ++;

          }else{
            if (local){
              device.connectionStatus = ConnectionStatus.local;
            }else{
              device.connectionStatus = ConnectionStatus.mqtt;
            }
            device.numberOfDisconnections = 0;
          }

          if (device.numberOfDisconnections >= 3){
            device.numberOfDisconnections = 3;
            device.connectionStatus = ConnectionStatus.disconnected;
          }
          device.updateDeviceConnection.cancel();
          device.deviceStatus = DeviceStatus.updated;


          status = ManagerStatus.updated;
          notifyListeners();
        });
      }
    }
    Device device = newDevice;
    if (device.connectionStatus != ConnectionStatus.disconnected) {
      device.deviceStatus = DeviceStatus.updating;
      device.connectionStatus = ConnectionStatus.updating;
      notifyListeners();
      Map <String, dynamic> map = {
        "t": "devices/" + device.mac.toUpperCase().substring(3),
        "a": "getv"
      };
      bool local = true;
      if (await device.isConnectedLocally()) {
        this.send(jsonEncode(map), true);
      } else {
        local = false;
        try {
          this.send(jsonEncode(map), false);
        } catch (e) {

        }
      }
      try {
        if (device.updateDeviceConnection.isActive){
          device.updateDeviceConnection.cancel();
        }
      }catch (e){

      }

      device.updateDeviceConnection =
          Timer.periodic(Duration(seconds: 3), (timer) {
            if (device.connectionStatus == ConnectionStatus.updating){
              device.numberOfDisconnections ++;

            }else{
              if (local){
                device.connectionStatus = ConnectionStatus.local;
              }else{
                device.connectionStatus = ConnectionStatus.mqtt;
              }
              device.numberOfDisconnections = 0;
            }

            if (device.numberOfDisconnections >= 3){
              device.numberOfDisconnections = 3;
              device.connectionStatus = ConnectionStatus.disconnected;
            }
            device.updateDeviceConnection.cancel();
            device.deviceStatus = DeviceStatus.updated;


            status = ManagerStatus.updated;
            notifyListeners();
          });
    }
    status = ManagerStatus.updated;
    notifyListeners();
  }
  List<Device> get getDevices{
    return this.devices;
  }
  void listenForNew() async  {
    udpReceiverForNew = await UDP.bind(Endpoint.any(port: Port(8890)));
    udpReceiverForNew.listen((datagram) {
      var str = String.fromCharCodes(datagram.data);
      newDevice.listen(str,address: datagram.address.address);
      notifyListeners();
    }, timeout: Duration(minutes: 10));
    udpSenderForNew = await UDP.bind(Endpoint.broadcast(port: Port(8888)));
  }
  void listenMqtt(){
    mqttClient.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(
          'EXAMPLE::Change notification:: topic is <${c[0]
              .topic}>, payload is <-- $pt -->');
      getDevices.forEach((device) {
        device.listen(pt);
      });

      notifyListeners();
    });
  }
  void listenUDP() {
    udpReceiver.listen((datagram) {
      var str = String.fromCharCodes(datagram.data);
      print(getDevices.length);
      getDevices.forEach((device){
        device.listen(str,address: datagram.address.address);
      });
      notifyListeners();
    }, timeout: Duration(hours: 1));
  }
  void sendForNew(String message) async {
    status = ManagerStatus.updating;

    var dataLength = await udpSenderForNew.send(
        message.codeUnits, Endpoint.broadcast(port: Port(8888)));
    print("Message: ${message}");
    print("${dataLength} bytes sent.");

    notifyListeners();
  }
  void send(String message,bool local) async {
    status = ManagerStatus.updating;
    if (local) {

      var dataLength = await udpSender.send(
          message.codeUnits, Endpoint.broadcast(port: Port(8888)));
      print("Message: ${message}");
      print("${dataLength} bytes sent.");
    }else{
      if (mqttClient.connectionStatus!.state == MqttConnectionState.connected) {
        const pubTopic = 'control';
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        print('EXAMPLE::Publishing our topic');
        mqttClient.publishMessage(
            pubTopic, MqttQos.exactlyOnce, builder.payload!);
      }
    }
    notifyListeners();
  }

  void selectDevice(Device device) {
    selectedDevice = device;
    notifyListeners();
  }


}

Future<MqttServerClient> connectToMQTT() async {

  MqttServerClient client = MqttServerClient.withPort('appdinamico3.com', 'psironi', 1883);
  client.logging(on: true);
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;
  client.onUnsubscribed = onUnsubscribed;
  client.onSubscribed = onSubscribed;
  client.onSubscribeFail = onSubscribeFail;
  client.pongCallback = pong;
  client.keepAlivePeriod = 60;
  final connMessage = MqttConnectMessage()
      .authenticateAs('psironi', 'Queiveephai6')

      .withWillTopic('willtopic')
      .withWillMessage('Will message')
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);
  client.connectionMessage = connMessage;
  try {
    await client.connect();
  } catch (e) {
    print('Exception: $e');
    client.disconnect();
  }
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client connected');
    print('EXAMPLE::Subscribing to the controltemperatura/# topic');
    const topic = 'controltemperatura/#'; // Not a wildcard topic
    client.subscribe(topic, MqttQos.atMostOnce);
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print(
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
  }
  return client;
}

void onConnected() {
  print('Connected');
}

// unconnected
void onDisconnected() {
  print('Disconnected');
}

// subscribe to topic succeeded
void onSubscribed(String topic) {
  print('Subscribed topic: $topic');
}

// subscribe to topic failed
void onSubscribeFail(String topic) {
  print('Failed to subscribe $topic');
}

// unsubscribe succeeded
void onUnsubscribed(String? topic) {
  print('Unsubscribed topic: $topic');
}
// PING response received
void pong() {
  print('Ping response client callback invoked');
}
