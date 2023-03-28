import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class SearchRestaurantPage extends StatefulWidget {
  const SearchRestaurantPage({Key? key}) : super(key: key);

  @override
  State<SearchRestaurantPage> createState() => _SearchRestaurantPageState();
}


class _SearchRestaurantPageState extends State<SearchRestaurantPage> {
  late Future<Position> _initialLocationFuture;
  late GoogleMapController mapController;
  late Position currentPosition;
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

      // 除外したいキーワードのリストを作成します
      List<String> excludedKeywords = [
        'StarBucks',
        'コンビニ',
        'ドラッグストア',
        'ホテル',
        'ドンキホーテ',
        'カラオケ',
        // その他の除外したいキーワードを追加
      ];

      for (var result in data['results']) {
        String name = result['name'];
        bool isExcluded = false;

        // キーワードリストに含まれる店舗を確認し、除外フラグを設定します
        for (String keyword in excludedKeywords) {
          if (name.contains(keyword)) {
            isExcluded = true;
            break;
          }
        }

        // 除外フラグが立っていない場合のみ、リストに追加します
        if (!isExcluded) {
          restaurants.add({
            'name': name,
            'lat': result['geometry']['location']['lat'],
            'lng': result['geometry']['location']['lng'],
          });
        }
      }

      return restaurants;
    } else {
      throw Exception('Failed to fetch nearby restaurants');
    }
  }

  Set<Marker> _markers = {};



  Future<BitmapDescriptor> _createRestaurantIcon() async {
    final double scaleFactor = 10;
    final ImageConfiguration imageConfiguration =
    ImageConfiguration(devicePixelRatio: scaleFactor);
    return await BitmapDescriptor.fromAssetImage(
        imageConfiguration, 'assets/images/restaurant_pin.png');
  }


  @override
  void initState() {
    super.initState();
    _initialLocationFuture = _initializeLocation();
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

  Future<void> _loadNearbyRestaurants() async {
    final BitmapDescriptor restaurantIcon = await _createRestaurantIcon();

    final restaurants = await fetchNearbyRestaurants(
        currentPosition.latitude,
        currentPosition.longitude,
        _searchRadius,
        'AIzaSyDgO_lHM9F3zzKSQWDoVdpyvTulCXCoc_Q');

    setState(() {
      _markers.clear();
      for (var restaurant in restaurants) {
        _markers.add(Marker(
          markerId: MarkerId(restaurant['name']),
          position: LatLng(restaurant['lat'], restaurant['lng']),
          infoWindow: InfoWindow(title: restaurant['name']),
          icon: restaurantIcon,
        ));
      }
    });
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

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    try {
      String mapStyle = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
      mapController.setMapStyle(mapStyle);
    } catch (e) {
      print('Error loading map style: $e');
    }
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

  Widget _buildGoToCurrentLocationButton() {
    return FloatingActionButton(
      backgroundColor: Colors.blue,
      onPressed: _goToCurrentLocation,
      child: Icon(Icons.my_location),
    );
  }

// 現在地に戻る処理を追加します
  void _goToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: 17.0,
        ),
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
                return Stack(
                  children: [
                    GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          zoom: 17,
                          target: LatLng(currentPosition.latitude,
                              currentPosition.longitude),
                        ),
                      markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                       mapToolbarEnabled: false,
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildGoToCurrentLocationButton(),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSearchRadiusButton(100),
                          _buildSearchRadiusButton(250),
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