// @dart=2.9
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:untitled3/location_services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Completer<GoogleMapController> _controller = Completer();
  MapType _currentMapType = MapType.normal;
  static const LatLng _center = const LatLng(45.521563, -122.677433);
  LatLng _lastMapPosition = _center;

  final Set<Marker> _markers = {};
  final TextEditingController _searchController =TextEditingController();
  String _currentAddress;


  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        position.latitude, position.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        '${place.street}, ${place.subLocality},${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission().then((value){
    }).onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR"+error.toString());
    });
    _getAddressFromLatLng(await Geolocator.getCurrentPosition());
    return await Geolocator.getCurrentPosition();
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);

  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }


  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _onAddTapMarkerButtonPressed(LatLng latLng) {
    setState(() {
      _markers.clear();
      _getAddressFromLatLng(Position(latitude: latLng.latitude,longitude: latLng.longitude));
      _markers.add(Marker(
        // This marker id can be anything that uniquely identifies each marker.
        markerId: MarkerId(latLng.toString()),
        position: latLng,
        infoWindow: InfoWindow(
          title: _currentAddress,
          snippet: '5 Star Rating',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
  }

  void _onAddMarkerButtonPressed() {
    setState(() {
      _markers.clear();
      _getAddressFromLatLng(Position(latitude: _lastMapPosition.latitude,longitude: _lastMapPosition.longitude));
      _markers.add(Marker(
        // This marker id can be anything that uniquely identifies each marker.
        markerId: MarkerId(_lastMapPosition.toString()),
        position: _lastMapPosition,
        infoWindow: InfoWindow(
          title: _currentAddress,
          snippet: '5 Star Rating',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Maps Sample App'),
          backgroundColor: Colors.green[700],
        ),
        body: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      textCapitalization:TextCapitalization.words ,
                      decoration:const InputDecoration(hintText: 'Search by City'),
                      onChanged: (value) {

                      },)),
                IconButton(onPressed: () async {
                  var placeTo = await LocationService().getPlace(_searchController.text);
                  _goToPlace(placeTo);
                }, icon: const Icon(Icons.search))
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 11.0,
                    ),
                    mapType: _currentMapType,
                    markers: _markers,
                    onCameraMove: _onCameraMove,
                    onTap:(LatLng latlng){
                      _onAddTapMarkerButtonPressed(latlng);
                    }
                    ,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            onPressed: _onMapTypeButtonPressed,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.map, size: 36.0),
                          ),
                          SizedBox(height: 16.0),
                          FloatingActionButton(
                            onPressed: _onAddMarkerButtonPressed,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.add_location, size: 36.0),
                          ),
                          SizedBox(height: 16.0),
                          FloatingActionButton(
                            onPressed: () async{
                          getUserCurrentLocation().then((value) async {
                          print(value.latitude.toString() +" "+value.longitude.toString());

                          // marker added for current users location
                          _markers.clear();
                          _markers.add(
                          Marker(
                          markerId: MarkerId(value.toString()),
                          position: LatLng(value.latitude, value.longitude),
                          infoWindow: InfoWindow(
                          title: _currentAddress,
                          ),
                          )
                          );

                          // specified current users location
                          CameraPosition cameraPosition = new CameraPosition(
                          target: LatLng(value.latitude, value.longitude),
                          zoom: 14,
                          );

                          final GoogleMapController controller = await _controller.future;
                          controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
                          setState(() {
                          });
                          });
                          },
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.my_location, size: 36.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _goToPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(lat,lng), zoom: 12),
    ));

  }
}