import 'package:flutter/widgets.dart';

class User with ChangeNotifier {
  int id;
  bool celsius;

  User(
      {this.id = 0,
      this.celsius = true,
    });
  set setCelcius(bool celsius) {
    this.celsius = celsius;
    notifyListeners();
  }
  factory User.fromDatabaseJson(Map<String, dynamic> data) => User(
    id: data['id'],
    celsius: (data['celsius'] == 1)? true:false,
    
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": this.id,
    "celsius": (this.celsius)? 1: 0,
  };

}
