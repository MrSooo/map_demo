import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//Chứa các hàm hỗ trợ như tính khoảng cách, lấy vị trí hiện tại
class MapUtils {
  //vị trí hiện tại
  static late Marker currentPos;

  //hàm lấy vị trí hiện tại, sử dụng package geolocator
  static Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    //Kiểm tra xem ứng dụng đã được cấp quyền truy cập vị trí chưa, nếu chưa thì báo lỗi
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    double lat = position.latitude;
    double long = position.longitude;

    currentPos = Marker(
      markerId: const MarkerId('currentPos'),
      infoWindow: const InfoWindow(title: "Current Position"),
      icon: BitmapDescriptor.defaultMarker,
      position: LatLng(lat, long),
    );
  }

  //Hàm tính khoảng cách giữa 2 vị trí trên bản đồ
  static double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
