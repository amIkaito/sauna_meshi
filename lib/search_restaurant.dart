import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchRestaurantPage extends StatefulWidget {
  const SearchRestaurantPage({Key? key}) : super(key: key);

  @override
  State<SearchRestaurantPage> createState() => _SearchRestaurantPageState();
}

class _SearchRestaurantPageState extends State<SearchRestaurantPage> {
  late Future<Position> _initialLocationFuture;
  late GoogleMapController mapController;
  late Position currentPosition;
  late BitmapDescriptor _arrowIcon;
  late StreamSubscription<Position> _positionStreamSubscription;
  int _searchRadius = 200;
  double _heading = 0;

  Future<List<Map<String, dynamic>>> fetchNearbyRestaurants(
      double lat, double lng, int radius, String apiKey) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?' +
            'location=$lat,$lng&radius=$radius&type=restaurant&opennow&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> restaurants = [];

      for (var result in data['results']) {
        restaurants.add({
          'name': result['name'],
          'lat': result['geometry']['location']['lat'],
          'lng': result['geometry']['location']['lng'],
        });
      }

      return restaurants;
    } else {
      throw Exception('Failed to fetch nearby restaurants');
    }
  }
  Set<Marker> _markers = {};

  Future<void> _loadNearbyRestaurants() async {
    final restaurants = await fetchNearbyRestaurants(
        currentPosition.latitude, currentPosition.longitude, _searchRadius, 'AIzaSyDgO_lHM9F3zzKSQWDoVdpyvTulCXCoc_Q');

    setState(() {
      _markers.clear();
      for (var restaurant in restaurants) {
        _markers.add(Marker(
          markerId: MarkerId(restaurant['name']),
          position: LatLng(restaurant['lat'], restaurant['lng']),
          infoWindow: InfoWindow(title: restaurant['name']),
        ));
      }
    });
  }



  @override
  void initState() {
    super.initState();
    _loadArrowIcon();
    _initialLocationFuture = _initializeLocation();
  }

  Future<void> _loadArrowIcon() async {
    _arrowIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0), 'assets/arrow.png');
  }

  Future<Position> _initializeLocation() async {
    await _requestLocationPermission();
    return await _getCurrentLocation();
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();

    if (status.isDenied) {
      // ユーザーが位置情報の許可を拒否した場合の処理
      print("位置情報の許可が拒否されました。");
    }
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _startLocationUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.best,
      intervalDuration: Duration(seconds: 1),
    ).listen((Position position) {
      _updateHeading(position);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadNearbyRestaurants();
    _startLocationUpdates();
  }

  void _updateHeading(Position position) {
    double newHeading = position.heading;

    if (mapController != null) {
      setState(() {
        currentPosition = position;
        _heading = newHeading;
      });

      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17.0,
        ),
      ));
    }
  }

  Widget _buildSearchRadiusButton(int radius) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _searchRadius = radius;
        });
        _loadNearbyRestaurants();
// TODO: ここで検索範囲が変更されたときの処理を実行します
      },
      child: Text('$radius m'),
      style: ElevatedButton.styleFrom(
        primary: _searchRadius == radius ? Colors.blue : Colors.grey,
      ),
    );
  }


  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'サウナ飯',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: FutureBuilder<Position>(
          future: _initialLocationFuture,
          builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else {
                currentPosition = snapshot.data!;
                return Column(
                  children: [
                    Expanded(
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          zoom: 17,
                          target: LatLng(currentPosition.latitude,
                              currentPosition.longitude),
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId("user_marker"),
                            position: LatLng(currentPosition.latitude,
                                currentPosition.longitude),
                            icon: _arrowIcon,
                            rotation: _heading,
                            anchor: Offset(0.5, 0.5),
                          ),
                        },
                        myLocationEnabled: false,
                        myLocationButtonEnabled: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSearchRadiusButton(200),
                          _buildSearchRadiusButton(300),
                          _buildSearchRadiusButton(400),
                          _buildSearchRadiusButton(500),
                        ],
                      ),
                    ),
                  ],
                );
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        )
    );
  }
}