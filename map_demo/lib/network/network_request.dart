import 'dart:convert';

import 'package:map_demo/model/driver.dart';
import 'package:http/http.dart' as http;

//Chứa các hàm để request API lấy data về và map nó vào 1 danh sách các đối tượng Driver model
class NetworkRequest {
  static const url = 'https://mamajoi.com/api/mamajoi/nearby';

  static Future<List<Driver>> getDrivers() async {
    final res = await http.post(Uri.parse(url));

    Map<String, dynamic> map = json.decode(res.body);
    List<dynamic> list = map["data"];

    List<Driver> drivers = list.map((e) => Driver.fromJson(e)).toList();

    return drivers;
  }
}
