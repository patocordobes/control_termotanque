
class Device  {
  final String mac;
  String? name;
  bool connectedToWiFi = false;
  String ssid = "";
  String brand = "";
  int? capacity;

  int? amountTubes;

  double? watts;

  
  Device({
    required this.mac,
    this.name,
    this.connectedToWiFi = false,
    this.ssid = "",
    this.brand = "",
    this.capacity,
    this.amountTubes,
    this.watts,

  }) : assert(mac != "" );

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      mac: json["mac"],
      name: json["name"],
      connectedToWiFi: json["connected_wifi"],
      ssid: json["ssid"],
      brand: json["brand"],
      capacity: json["capacity"],
      amountTubes: json["amount_tubes"],
      watts: json["watts"],

    );
  }
  factory Device.fromDatabaseJson(Map<String, dynamic> json) {
    return Device(
      mac: json["mac"],
      name: json["name"],
      connectedToWiFi: (json["connected_wifi"] == 1)? true: false,
      ssid: json["ssid"],
      brand: json["brand"],
      capacity: json["capacity"],
      amountTubes: json["amount_tubes"],
      watts: json["watts"],

    );
  }
  Map <String, dynamic> toDatabaseJson() => {
    "mac": this.mac,
    "name": this.name,
    "connected_wifi": this.connectedToWiFi,
    "ssid": this.ssid,
    "brand": this.brand,
    "capacity": this.capacity,
    "amount_tubes":this.amountTubes,
    "watts": this.watts,
  };

  Map <String, dynamic> toArduinoJson() => {
    "n": this.name,
    "m": this.brand,
    "c": this.capacity,
    "tb": this.amountTubes,
    "w": this.watts,

  };

}


