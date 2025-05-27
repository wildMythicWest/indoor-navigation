import 'dart:async';

import 'package:flutter/material.dart';
import 'package:indoor_navigation/floor/floor_ids.dart';

import '../floor/image.dart';

class BleTriangulationPage extends StatefulWidget {
  /// Default constructor for [BleTriangulationPage] widget.
  const BleTriangulationPage({super.key});

  @override
  State<BleTriangulationPage> createState() => _BleTriangulationPageState();
}

class _BleTriangulationPageState extends State<BleTriangulationPage> {

  String selectedImage = FloorId.theMallFloor0; // Stores the selected image
  Offset? pinPosition; // Stores pin position
  List<Pin> allPins = [];

  /// Метод за сканиране за BLE устройства и намиране на локацията на устройсвото
  Future<void> _findMe(BuildContext context) async {
    // scan BLE devices - find specific devices
    var foundLocation;
    // Изчертаване на намерената локация на екрана
    setState(() {
      pinPosition = Offset(foundLocation.locationX, foundLocation.locationY);
      if (pinPosition != null) {
        allPins.add(Pin(pinPosition: pinPosition!, color: Colors.red));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Find Me!'),
        ),
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageSelectorWidget(
                  selectedImage: selectedImage,
                  pins: allPins,
                  onImageChanged: (newImage) {
                    setState(() {
                      selectedImage = newImage;
                      pinPosition = null; // Reset pin when changing image
                      allPins = [];
                    });
                  },
                  onPinPlaced: (newPin) {
                    setState(() {
                      pinPosition = newPin;
                      allPins.add(Pin(pinPosition: newPin, color: Colors.red));
                    });
                  },),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Find me'),
                      onPressed: () async => _findMe(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Clear'),
                      onPressed: () => setState(() {
                        pinPosition = null;
                        allPins = [];
                      }),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}