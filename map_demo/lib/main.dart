import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_demo/model/driver.dart';
import 'package:map_demo/network/network_request.dart';
import 'package:map_demo/utils/map_utils.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  //Những state được dùng trong ứng dụng
  //Những state dùng trong Map
  late CameraPosition
      currentCamera; //vị trí camera khi khởi tạo sẽ được gán = với vị trí hiện tại
  late Polyline polyline; //Những đường polyline sẽ được vẽ trên map
  Set<Marker> markers = {}; //Những marker sẽ được thể hiện trên map

  //Những state dùng để thể hiện thông tin khi nhấn vào 1 marker, gồm có: link avatar, khoảng cách từ marker đến vị trí hiện tại, tên tài xế
  late String imgLink;
  late double des;
  late String driverName;

  //Những state để đảm bảo dữ liệu được load trước khi build UI
  bool onClick = false;
  bool isInit = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await MapUtils.getCurrentLocation(); //Lấy bị trí hiện tại
    await initializeApp(); //Hàm lấy danh sách Driver, gán vị trí cam
  }

  //Lấy ảnh avatar từ link và chuyển thành dạng Uint8List để custom marker
  Future<Uint8List> loadNetworkImage(path) async {
    final completed = Completer<ImageInfo>();
    var image = NetworkImage(path);
    image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) => completed.complete(info)));
    final imageInfo = await completed.future;
    final byteData =
        await imageInfo.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  //Hàm lấy danh sách tài xế từ API, lấy vị trí camera, tạo danh sách các marker để show trên map
  Future<void> initializeApp() async {
    markers.add(MapUtils.currentPos); //Gắn marker vị trí hiện tại

    //gán vị trí cho camera
    currentCamera = CameraPosition(
      target: LatLng(MapUtils.currentPos.position.latitude,
          MapUtils.currentPos.position.longitude),
      zoom: 14.4746,
    );

    //Khởi tạo đường polyline với điểm LatLng đầu tiên là CurrentPos (vị trí hiện tại)
    polyline = Polyline(
        polylineId: const PolylineId('currentLine'),
        points: [
          LatLng(MapUtils.currentPos.position.latitude,
              MapUtils.currentPos.position.longitude),
        ],
        width: 2);

    //Lấy danh sách tài xế từ API
    List<Driver> driverList = await NetworkRequest.getDrivers();

    //Khởi tạo các marker từ danh sách tài xế
    for (var driver in driverList) {
      double lat = double.parse(driver.geolocation!.split(',')[0]);
      double long = double.parse(driver.geolocation!.split(',')[1]);

      Uint8List image = await loadNetworkImage(driver.avatar);
      final ui.Codec markerImageCodec = await ui.instantiateImageCodec(
          image.buffer.asUint8List(),
          targetHeight: 150,
          targetWidth: 150);
      final ui.FrameInfo frameInfo = await markerImageCodec.getNextFrame();
      final ByteData? byteData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List resizedImageMarker = byteData!.buffer.asUint8List();

      markers.add(Marker(
          onTap: () {
            setState(() {
              if (polyline.points.length == 1) {
                polyline.points.add(LatLng(lat, long));
              } else {
                polyline.points.removeLast();
                polyline.points.add(LatLng(lat, long));
              }
              des = MapUtils.calculateDistance(
                  MapUtils.currentPos.position.latitude,
                  MapUtils.currentPos.position.longitude,
                  lat,
                  long);
              driverName = driver.name!;
              imgLink = driver.avatar!;
              onClick =
                  true; //Đánh dấu việc có thể click vào marker để thể hiện 1 ô thông tin cần thiết
            });
          },
          markerId: MarkerId(driver.name!),
          infoWindow: InfoWindow(title: driver.name!),
          icon: BitmapDescriptor.fromBytes(resizedImageMarker),
          position: LatLng(lat, long)));
    }

    //Đánh dấu việc load dữ liệu đã xong để tắt đi CircularProgressIndicator()
    setState(() {
      isInit = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isInit
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  markers: markers,
                  polylines: {polyline},
                  initialCameraPosition: currentCamera,
                ),
                if (onClick)
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.85),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.width * 0.225,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30.0,
                                backgroundImage: NetworkImage(imgLink),
                                backgroundColor: Colors.transparent,
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Destination: ${des.toStringAsFixed(8)}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    'Driver Name: $driverName',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container()
              ],
            ),
    );
  }
}
