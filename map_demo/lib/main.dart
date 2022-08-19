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

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await getCurrentLocation();
  }

  void addRandomMaker() {
    Random random = Random();
    String id = random.nextDouble().toString();
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
            });
          },
          markerId: MarkerId(id),
          infoWindow: InfoWindow(title: random.nextInt(10).toString()),
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
              ],
            ),
    );
  }
}
