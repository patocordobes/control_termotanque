import 'package:control_termotanque/database/database.dart';
import 'package:control_termotanque/models/device_model.dart';
import 'package:sqflite/sqflite.dart';

class DeviceDao {
  final dbProvider = DatabaseProvider.dbProvider;

  Future<int> createDevice(Device device) async {
    final db = await dbProvider.database;

    var result = db.insert(deviceTable, device.toDatabaseJson(),conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }
  Future<int> updateDevice(Device device) async {
    final db = await dbProvider.database;

    var result = db.insert(deviceTable, device.toDatabaseJson(),conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  Future<int> deleteDevice(String? mac) async {
    final db = await dbProvider.database;
    var result = await db
        .delete(deviceTable, where: "mac = ?", whereArgs: [mac]);
    return result;
  }

  Future<List<Map<String,dynamic>>> selectDevices() async {
    final db = await dbProvider.database;
    try {
      List<Map<String,dynamic>> devices = await db
          .query(userTable);
      

      return devices;
    } catch (error) {
      throw Exception("Error selecting devices.");

    }
  }
}
