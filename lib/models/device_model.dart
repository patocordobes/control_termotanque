
class Device  {
  final String mac;
  String? name;
  bool? connectedToWiFi;

  
  Device({
    required this.mac,
    this.name,
    this.connectedToWiFi,
  }) : assert(mac != "" );

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      mac: json["mac"],
      name: json["name"],
      connectedToWiFi: json["connectedToWiFi"],
    );
  }

  Map <String, dynamic> toJson() => {
    "mac": this.mac,
    "name": this.name,
    "connectedToWiFi": this.connectedToWiFi,
  };
}


