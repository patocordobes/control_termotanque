import 'package:control_termotanque/database/database.dart';
import 'package:control_termotanque/models/auth/user_model.dart';
import 'package:sqflite/sqflite.dart';

class UserDao {
  final dbProvider = DatabaseProvider.dbProvider;

  Future<int> createUser(User user) async {
    final db = await dbProvider.database;

    var result = db.insert(userTable, user.toDatabaseJson(),conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  Future<int> deleteUser(int? id) async {
    final db = await dbProvider.database;
    var result = await db
        .delete(userTable, where: "id = ?", whereArgs: [id]);
    return result;
  }

  Future<bool> checkUser(int? id) async {
    final db = await dbProvider.database;
    try {
      List<Map> users = await db
          .query(userTable, where: 'id = ?', whereArgs: [id]);
      if (users.length > 0) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      print(error);
      return false;
    }
  }
  Future<Map<String,dynamic>> selectUser() async {
    final db = await dbProvider.database;
    try {
      List<Map<String,dynamic>> users = await db
          .query(userTable);
      Map<String,dynamic> map = Map();

      users.forEach((row) {
        map = row;
      });

      return map;
    } catch (error) {
      throw Exception("error");

    }
  }
}
