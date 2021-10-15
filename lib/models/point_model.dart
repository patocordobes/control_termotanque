

class Point  {
  int? id;
  final int temperature;
  final int resistanceTime;
  final DateTime dateTime;
  final int deviceId;
  
  Point({
    this.id,
    required this.temperature,
    required this.resistanceTime,
    required this.dateTime,
    required this.deviceId,
  }) : assert(resistanceTime <= 60);

  factory Point.fromDatabaseJson(Map<String, dynamic> json) {
    return Point(
      id: json["id"],
      temperature: json["temperature"],
      resistanceTime: json["resistance_time"],
      dateTime: json["date_time"],
      deviceId: json["device_id"]
    );
  }
  Map <String, dynamic> toDatabaseJson() => {
    "id": this.id,
    "temperature": this.temperature,
    "resistance_time": this.resistanceTime,
    "date_time": this.dateTime,
    "device_id": this.deviceId,
  };
  Map <String, dynamic> toCreateDatabaseJson() => {
    "temperature": this.temperature,
    "resistance_time": this.resistanceTime,
    "date_time": this.dateTime,
    "device_id": this.deviceId,
  };
}

