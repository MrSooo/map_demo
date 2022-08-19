import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_map_markers/custom_map_markers.dart';

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
  late LatLng currentPos;
  late CameraPosition currentCamera;
  bool isInit = true;
  bool onClick = false;
  late Polyline polyline;
  List<MarkerData> _customMarkers = [];
  int count = 0;

  late double des;
  late String driverName;
  late String avatarPath;

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
    currentPos = LatLng(lat, long);
    // markers.add(currentPos);
    _customMarkers.add(
      MarkerData(
          marker: Marker(
              markerId: const MarkerId('CurrentPositon'),
              position: LatLng(lat, long)),
          child: _currentMarker()),
    );

    currentCamera = CameraPosition(
      target: LatLng(lat, long),
      zoom: 14.4746,
    );

    polyline = Polyline(
        polylineId: PolylineId('currentLine'),
        points: [
          LatLng(currentPos.latitude, currentPos.longitude),
        ],
        width: 2);

    setState(() {
      isInit = false;
    });
  }

  _currentMarker() {
    return Icon(
      Icons.location_pin,
      color: Colors.red,
      size: 30,
    );
  }

  _customMarker(Color color) {
    return Stack(
      children: [
        Icon(
          Icons.add_location,
          color: color,
          size: 60,
        ),
        Positioned(
          left: 17,
          top: 10,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
                child: CircleAvatar(
              radius: 48,
              backgroundImage: AssetImage('assets/images/avatar.jpg'),
            )),
          ),
        )
      ],
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void addRandomMaker() async {
    Random random = Random();
    String id = random.nextDouble().toString();
    String name = (count++).toString();
    double lat = currentPos.latitude +
        (random.nextBool()
            ? random.nextDouble() / 100
            : -random.nextDouble() / 100);
    double long = currentPos.longitude -
        (random.nextBool()
            ? random.nextDouble() / 100
            : -random.nextDouble() / 100);

    setState(() {
      _customMarkers.add(
        MarkerData(
            marker: Marker(
                onTap: () {
                  setState(() {
                    if (polyline.points.length == 1) {
                      polyline.points.add(LatLng(lat, long));
                    } else {
                      polyline.points.removeLast();
                      polyline.points.add(LatLng(lat, long));
                    }
                    des = calculateDistance(
                        currentPos.latitude, currentPos.longitude, lat, long);
                    driverName = name;
                    onClick = true;
                  });
                },
                markerId: MarkerId(name),
                position: LatLng(lat, long)),
            child: _customMarker(Colors.blue)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.width * 0.3),
        child: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            addRandomMaker();
          },
        ),
      ),
      body: isInit
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomGoogleMapMarkerBuilder(
                  builder: (BuildContext, Set<Marker>? markers) {
                    if (markers == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return GoogleMap(
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      markers: markers,
                      polylines: {polyline},
                      initialCameraPosition: currentCamera,
                    );
                  },
                  customMarkers: _customMarkers,
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





// import 'package:custom_map_markers/custom_map_markers.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Custom Marker Example',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const MyHomePage(title: 'Custom Marker Example'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({Key? key, required this.title}) : super(key: key);
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final locations = const [
//     LatLng(37.42796133580664, -122.085749655962),
//     LatLng(37.41796133580664, -122.085749655962),
//     LatLng(37.43796133580664, -122.085749655962),
//     LatLng(37.42796133580664, -122.095749655962),
//     LatLng(37.42796133580664, -122.075749655962),
//   ];

//   late List<MarkerData> _customMarkers;

//   @override
//   void initState() {
//     super.initState();
//     _customMarkers = [
//       MarkerData(
//           marker:
//               Marker(markerId: const MarkerId('id-1'), position: locations[0]),
//           child: _customMarker3('Everywhere\nis a Widgets', Colors.blue)),
//       MarkerData(
//           marker:
//               Marker(markerId: const MarkerId('id-5'), position: locations[4]),
//           child: _customMarker('A', Colors.black)),
//       MarkerData(
//           marker:
//               Marker(markerId: const MarkerId('id-2'), position: locations[1]),
//           child: _customMarker('B', Colors.red)),
//       MarkerData(
//           marker:
//               Marker(markerId: const MarkerId('id-3'), position: locations[2]),
//           child: _customMarker('C', Colors.green)),
//       MarkerData(
//           marker:
//               Marker(markerId: const MarkerId('id-4'), position: locations[3]),
//           child: _customMarker2('D', Colors.purple)),
//       MarkerData(
//           marker:
//               Marker(markerId: const MarkerId('id-5'), position: locations[4]),
//           child: _customMarker('A', Colors.blue)),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             if (_customMarkers.isNotEmpty) {
//               _customMarkers.removeLast();
//             }
//           });
//         },
//       ),
//       body: CustomGoogleMapMarkerBuilder(
//         //screenshotDelay: const Duration(seconds: 4),
//         customMarkers: _customMarkers,
//         builder: (BuildContext context, Set<Marker>? markers) {
//           if (markers == null) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           return GoogleMap(
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(37.42796133580664, -122.085749655962),
//               zoom: 14.4746,
//             ),
//             markers: markers,
//             onMapCreated: (GoogleMapController controller) {},
//           );
//         },
//       ),
//     );
//   }

//   _customMarker(String symbol, Color color) {
//     return Stack(
//       children: [
//         Icon(
//           Icons.add_location,
//           color: color,
//           size: 70,
//         ),
//         Positioned(
//           left: 20,
//           top: 10,
//           child: Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white,
//             ),
//             child: Center(
//                 child: CircleAvatar(
//               radius: 48,
//               backgroundImage: AssetImage('assets/images/avatar.jpg'),
//             )),
//           ),
//         )
//       ],
//     );
//   }

//   _customMarker2(String symbol, Color color) {
//     return Container(
//       width: 30,
//       height: 30,
//       margin: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//           border: Border.all(color: color, width: 2),
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [BoxShadow(color: color, blurRadius: 6)]),
//       child: Center(child: Text(symbol)),
//     );
//   }

//   _customMarker3(String text, Color color) {
//     return Container(
//       margin: const EdgeInsets.all(8),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//           border: Border.all(color: color, width: 2),
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           boxShadow: [BoxShadow(color: color, blurRadius: 6)]),
//       child: Center(
//           child: Text(
//         text,
//         textAlign: TextAlign.center,
//       )),
//     );
//   }
// }
