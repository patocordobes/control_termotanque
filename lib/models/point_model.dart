

import 'package:control_termotanque/repository/models_repository.dart';

import 'device_model.dart';

class Point {
  int? id;
  int temperature = 0;
  int resistanceTime = 0;
  final DateTime dateTime;
  final Device device;
  ModelsRepository modelsRepository = ModelsRepository();
  bool temperatureError = false;
  bool resistanceError = false;
  Point({
    this.id,
    this.temperature = 0,
    this.resistanceTime = 0,
    required this.dateTime,
    required this.device,
  }){
    if (this.resistanceTime > 60){
      resistanceError = true;
      this.resistanceTime = 0;
    }
    if (this.temperature > 120){
      temperatureError = true;
      this.temperature = 0;
    }
    if (this.temperature < -20){
      this.temperature = 0;
    }
  }

  factory Point.fromDatabaseJson(Map<String, dynamic> json,
      {required Device device}) {
    return Point(
        id: json["id"],
        temperature: json["temperature"],
        resistanceTime: json["resistance_time"],
        dateTime: DateTime.parse(json["date_time"]),
        device: device
    );
  }

  Map <String, dynamic> toDatabaseJson() {
    Map <String, dynamic> map = {
      "id": this.id,
      "temperature": this.temperature,
      "resistance_time": this.resistanceTime,
      "date_time": this.dateTime.toString(),
      "point_device": this.device.id,
    };
    return map;
  }
  Map <String, dynamic> toCreateDatabaseJson() {
    Map <String, dynamic> map = {
      "temperature": this.temperature,
      "resistance_time": this.resistanceTime,
      "date_time": this.dateTime.toString(),
      "point_device": this.device.id,
    };
    return map;
  }
}

