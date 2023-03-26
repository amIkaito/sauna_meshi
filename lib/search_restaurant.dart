import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class SearchRestaurantPage extends StatefulWidget {
  const SearchRestaurantPage({Key? key}) : super(key: key);

  @override
  State<SearchRestaurantPage> createState() => _SearchRestaurantPageState();
}

class _SearchRestaurantPageState extends State<SearchRestaurantPage> {
  late GoogleMapController mapController;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await _requestLocationPermission();
      _getCurrentLocation().then((position) {
        setState(() {
          currentPosition = position;
        });
      });
    });
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status == PermissionStatus.denied) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('位置情報の利用が許可されていません'),
          content: Text('アプリの機能を使用するためには、位置情報の利用を許可する必要があります。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }


  Future<Position> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } on Exception catch (e) {
      print('位置情報の取得に失敗しました: ${e.toString()}');
      return Position(
          latitude: 35.6895,
          longitude: 139.6917,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          floor: 0);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
      body: currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          zoom: 17,
          target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          tilt: 45.0,
          bearing: 90.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: {
          Marker(
            markerId: MarkerId('current_location'),
            position: LatLng(
                currentPosition!.latitude, currentPosition!.longitude),
          ),
        },
      ),
    );
  }
}