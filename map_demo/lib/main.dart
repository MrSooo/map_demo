import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();
  late Marker currentPos;
  late CameraPosition currentCamera;
  bool isInit = true;
  late Polyline polyline;
  Set<Marker> markers = {};

  late double des;
  late String driverName;
  bool onClick = false;
  int count = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

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
    print("Latitude: $lat and Longitude: $long");

    currentPos = Marker(
      markerId: MarkerId('currentPos'),
      infoWindow: InfoWindow(title: "Current Position"),
      icon: BitmapDescriptor.defaultMarker,
      position: LatLng(lat, long),
    );

    markers.add(currentPos);

    currentCamera = CameraPosition(
      target: LatLng(lat, long),
      zoom: 14.4746,
    );

    polyline = Polyline(
        polylineId: PolylineId('currentLine'),
        points: [
          LatLng(currentPos.position.latitude, currentPos.position.longitude),
        ],
        width: 2);

    setState(() {
      isInit = false;
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void addRandomMaker() {
    Random random = Random();
    String id = random.nextDouble().toString();
    String name = (count++).toString();
    double lat = currentPos.position.latitude +
        (random.nextBool()
            ? random.nextDouble() / 100
            : -random.nextDouble() / 100);
    double long = currentPos.position.longitude -
        (random.nextBool()
            ? random.nextDouble() / 100
            : -random.nextDouble() / 100);
    setState(() {
      markers.add(Marker(
          onTap: () {
            setState(() {
              if (polyline.points.length == 1) {
                polyline.points.add(LatLng(lat, long));
              } else {
                polyline.points.removeLast();
                polyline.points.add(LatLng(lat, long));
              }
              des = calculateDistance(currentPos.position.latitude,
                  currentPos.position.longitude, lat, long);
              driverName = name;
              onClick = true;
            });
          },
          markerId: MarkerId(id),
          infoWindow: InfoWindow(title: name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: LatLng(lat, long)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          addRandomMaker();
        },
      ),
      body: isInit
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  markers: markers,
                  polylines: {polyline},
                  initialCameraPosition: currentCamera,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
                onClick
                    ? Padding(
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
                              padding: EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundImage:
                                        AssetImage('assets/images/avatar.jpg'),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Destination: ' +
                                            des.toStringAsFixed(6),
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Spacer(),
                                      Text(
                                        'Driver Name: ' + driverName,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container()
              ],
            ),
    );
  }
}
