class User {
  int id;
  String typeTemp;
  


  User(
      {this.id = 0,
      this.typeTemp = "c",
    });

  factory User.fromDatabaseJson(Map<String, dynamic> data) => User(
    id: data['id'],
    typeTemp: data['type_temp'],
    
  );

  Map<String, dynamic> toDatabaseJson() => {
    "id": this.id,
    "type_temp": this.typeTemp,
  
  };

}
