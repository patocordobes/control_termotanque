import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final userTable = 'userTable';
final deviceTable = 'device';

class DatabaseProvider {
  static final DatabaseProvider dbProvider = DatabaseProvider();

  Database? _database;

  Future <Database> get database async {
    if (_database != null){
      return Future.value(_database);
    }
    _database = await createDatabase();
    return Future.value(_database);
  }

  createDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "User.db");

    var database = await openDatabase(
      path,
      version: 4,
      onUpgrade: onUpgrade,
      onCreate: initDB,
    );
    return database;
  }

  Future<void> onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (newVersion > oldVersion) {
      await database.execute(
          "DROP TABLE IF EXISTS $userTable");

      await database.execute(
          "DROP TABLE IF EXISTS $deviceTable");
    }
    await database.execute(
        "CREATE TABLE $userTable ("
            "id INTEGER PRIMARY KEY, "
            "type_temp BOOLEAN "
            ")"
    );

    await database.execute(
        "CREATE TABLE $deviceTable ("
            "id INTEGER PRIMARY KEY autoincrement, "
            "mac TEXT, "
            "name TEXT, "
            "connected_wifi BOOLEAN, "
            "ssid TEXT, "
            "brand TEXT, "
            "capacity INTEGER, "
            "amount_tubes INTEGER, "
            "watts DOUBLE "
            ")"
    );
  }

  void initDB(Database database, int version) async {
    await database.execute(
      "CREATE TABLE $userTable ("
      "id INTEGER PRIMARY KEY, "
      "type_temp BOOLEAN "
      ")"
    );
    
    await database.execute(
      "CREATE TABLE $deviceTable ("
      "id INTEGER PRIMARY KEY autoincrement, "
      "mac TEXT, "
      "name TEXT, "
      "connected_wifi BOOLEAN, "
      "ssid TEXT, "
      "brand TEXT, "
      "capacity INTEGER, "
      "amount_tubes INTEGER, "
      "watts DOUBLE "
      ")"
    );
  }
}