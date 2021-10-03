import 'package:control_termotanque/models/device_model.dart';
import 'package:control_termotanque/pages/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments ;
    print("route: ${settings.name}");


    switch (settings.name) {
      case '/devices':
        return MaterialPageRoute(builder: (_) => DevicesPage(title: "Dispositivos",));
      case '/search_devices':
        return MaterialPageRoute(builder: (_) => SearchDevicesPage(title: "Buscar Dispositivos",));
      case '/choose_wifi':
        Map<String, dynamic> map = args as Map<String, dynamic>;
        print(map);
        Device? device;
        if (map['device'] != null) {
          device = Device.fromJson(map['device']);
        }
        return MaterialPageRoute(builder: (_) => ChooseWifiPage(title: "Elige el WiFi",device: device!));
      case "/device_configuration": 
        Map<String, dynamic> map = args as Map<String, dynamic>;
        print(map);
        Device? device;
        if (map['device'] != null) {
          device = Device.fromJson(map['device']);
        }
        return MaterialPageRoute(builder: (_) => DeviceConfigrationPage(title: "Configuracion del dispositivo",device: device!));
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsPage(title: "Configuracion",));
      default:
        return MaterialPageRoute(builder: (_) => DevicesPage(title: "Dispositivos",));
    }
  }
}
