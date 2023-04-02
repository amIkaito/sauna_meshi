import 'package:flutter/material.dart';
import 'package:sauna_meshi/search_restaurant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サウナ飯a',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SearchRestaurantPage(),
    );
  }
}




