import 'dart:async';
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
  late Position currentPosition;
  late BitmapDescriptor _arrowIcon;
  late StreamSubscription<Position> _positionStreamSubscription;
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    _loadArrowIcon();
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
        future: _initializeLocation(),
    builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
    if (snapshot.hasError) {
    return Center(child: Text("Error: ${snapshot.error}"));
    } else {
    currentPosition = snapshot.data!;
    return GoogleMap(
    onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        zoom: 17,
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
      ),
      markers: {
        Marker(
          markerId: MarkerId("user_marker"),
          position: LatLng(currentPosition.latitude, currentPosition.longitude),
          icon: _arrowIcon,
          rotation: _heading,
          anchor: Offset(0.5, 0.5),
        ),
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: true,
    );
    }
    } else {
      return Center(child: CircularProgressIndicator());
    }
    },
        ),
    );
  }
}