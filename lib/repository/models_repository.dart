import 'dart:async';
import 'package:control_termotanque/dao/device_dao.dart';
import 'package:control_termotanque/dao/user_dao.dart';
import 'package:control_termotanque/models/auth/user_model.dart';
import 'package:control_termotanque/models/models.dart';


class ModelsRepository {
  final userDao = UserDao();
  final deviceDao = DeviceDao();

  Future<void> createUser({required User user}) async {
    // write token with the user to the database
    int result = await userDao.createUser(user);
    print("id $result created");
  }


  Future<User> get getUser async {
    Map<String, dynamic> map = await userDao.selectUser();
    User user = User.fromDatabaseJson(map);
    return user;
  }


  Future<void> createDevice({required Device device}) async {
    // write token with the user to the database
    int result = await deviceDao.createDevice(device);
    print("device $result created");
  }
  Future<void> updateDevice({required Device device}) async {
    // write token with the user to the database
    int result = await deviceDao.updateDevice(device);
    print(device.toDatabaseJson());
    print("device $result updated");
  }
  Future<void> deleteDevice({required Device device}) async {
    // write token with the user to the database
    int result = await deviceDao.deleteDevice(device);
    print(device.toDatabaseJson());
    print("device $result deleted");
  }

  Future<List<Device>> getDevices() async {
    List<Map<String, dynamic>> listMap = await deviceDao.selectDevices();
    List<Device> devices = [];
    listMap.forEach((device){
      devices.add(Device.fromDatabaseJson(device));
    });
    return devices;
  }
  Future<int> createPoint({required Point point}) async {
    // write token with the user to the database
    int result = 0;
    try {
      point = await getPoint(
          device: point.device, dateTime: point.dateTime);
      result = await deviceDao.updatePoint(point);
      //print("point $result updated");
      return result;
    }catch (e){

    }
    result = await deviceDao.createPoint(point);
    //print("point $result created");
    return result;
  }
  Future<int> updatePoint({required Point point}) async {
    // write token with the user to the database
    int result = await deviceDao.updatePoint(point);
    //print("point $result updated");
    return result;
  }
  Future<List<Point>> getPoints({required Device device,required DateTime dateTime}) async {
    List<Map<String, dynamic>> listMap = await deviceDao.selectPoints(device,dateTime);
    List<Point> points = [];
    listMap.forEach((point){
      points.add(Point.fromDatabaseJson(point,device:device));
    });
    return points;
  }
  Future<List<Point>> getAllPoints({required Device device}) async {
    List<Map<String, dynamic>> listMap = await deviceDao.selectAllPoints(device);
    List<Point> points = [];
    listMap.forEach((point){
      points.add(Point.fromDatabaseJson(point,device:device));
    });
    return points;
  }
  Future<Point> getPoint({required Device device,required DateTime dateTime}) async {
    List<Map<String, dynamic>> listMap = await deviceDao.selectPoint(device,dateTime);
    late Point point;
    listMap.forEach((pointJson){
      point = Point.fromDatabaseJson(pointJson,device:device);
    });
    return point;
  }

  Future<void> deletePoints({required Device device}) async {
    await deviceDao.deletePoints(device);

  }
}
