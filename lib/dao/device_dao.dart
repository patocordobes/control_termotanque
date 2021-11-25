import 'package:control_termotanque/database/database.dart';

import 'package:control_termotanque/models/models.dart';
import 'package:sqflite/sqflite.dart';

class DeviceDao {
  final dbProvider = DatabaseProvider.dbProvider;

  Future<int> createDevice(Device device) async {
    final db = await dbProvider.database;

    var result = db.insert(deviceTable, device.toCreateDatabaseJson(),conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }
  Future<int> updateDevice(Device device) async {
    final db = await dbProvider.database;

    var result = db.insert(deviceTable, device.toDatabaseJson(),conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  Future<int> deleteDevice(Device device) async {
    final db = await dbProvider.database;
    var result = await db
        .delete(deviceTable, where: "id = ?", whereArgs: [device.id]);
    return result;
  }

  Future<List<Map<String,dynamic>>> selectDevices() async {
    final db = await dbProvider.database;
    try {
      List<Map<String,dynamic>> devices = await db
          .query(deviceTable);
      

      return devices;
    } catch (error) {
      print(error);
      throw Exception("Error selecting devices.");

    }
  }

  Future<int> createPoint(Point point) async {
    final db = await dbProvider.database;
    var result = db.insert(pointTable, point.toCreateDatabaseJson(),conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  Future<int> updatePoint(Point point) async {
    final db = await dbProvider.database;
    var result = db.insert(pointTable, point.toDatabaseJson(),conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  Future<List<Map<String,dynamic>>> selectPoints(Device device, DateTime dateTime) async {
    final db = await dbProvider.database;

    var query = "SELECT * FROM $pointTable where point_device = ${device
        .id} and datetime(date_time) BETWEEN  datetime('${dateTime.year}-${dateTime
        .month}-${dateTime.day} 00:00:00') and datetime('${dateTime
        .year}-${dateTime.month}-${dateTime.day} 23:59:59');";
    if (dateTime.day == DateTime.now().day){
      query = "SELECT * FROM $pointTable where point_device = ${device
          .id} and datetime(date_time) BETWEEN  datetime('${dateTime.year}-${dateTime
          .month}-${dateTime.day} 00:00:00') and datetime('${dateTime
          .year}-${dateTime.month}-${dateTime.day} ${DateTime.now().hour}:59:59');";
    }
    print(query);
    var result = await db
        .rawQuery(query);
    return result;
  }
  Future<List<Map<String,dynamic>>> selectAllPoints(Device device) async {
    final db = await dbProvider.database;
    var query = "SELECT * FROM $pointTable where point_device = ${device
        .id};";
    print(query);
    var result = await db
        .rawQuery(query);
    return result;
  }
  Future<List<Map<String,dynamic>>> selectPoint(Device device, DateTime dateTime) async {

    final db = await dbProvider.database;
    var query = "SELECT * FROM $pointTable where point_device = ${device
        .id} and datetime(date_time) = datetime('${dateTime.year}-${dateTime
        .month}-${dateTime.day} ${dateTime.hour}:00:00');";
    var result = await db
        .rawQuery(query);
    return result;
  }
  Future<int> deletePoints(Device device) async {
    final db = await dbProvider.database;
    var result = await db
        .delete(pointTable, where: "point_device = ?", whereArgs: [device.id]);
    return result;
  }
}
