import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:indoor_navigation/ble/trilateration.dart';
import 'package:indoor_navigation/floor/floor_ids.dart';

import '../ble/circle_painter.dart';
import '../floor/image.dart';

class BleTrilaterationPage extends StatefulWidget {
  /// Default constructor for [BleTrilaterationPage] widget.
  const BleTrilaterationPage({super.key});

  @override
  State<BleTrilaterationPage> createState() => _BleTrilaterationPageState();
}

class _BleTrilaterationPageState extends State<BleTrilaterationPage> {

  String selectedImage = FloorId.apartment; // Stores the selected image
  Offset? pinPosition; // Stores pin position
  List<Marker> allPins = [];

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  
  List<CustomPaint> circles = [];

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() => _scanResults = results);
      }
    }, onError: (e) {
      print("Scan Error: $e");
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (_isScanning == true && state == false) {
        setState(() {
          var locationResult = Trilateration.findMe(_scanResults);
          circles = locationResult.originAndRadius.entries
              .map((entry) => CirclePainter(center: Offset(entry.key.x, entry.key.y), radius: entry.value) as CustomPainter)
              .map((painter) => CustomPaint(painter: painter,))
          .toList();
          pinPosition = locationResult.position;
          //allPins = [];
          allPins.add(Pin(pinPosition: pinPosition!, color: Colors.red));
          allPins.addAll(locationResult.originAndRadius.entries
              .map((entry) => Marker(position: Offset(entry.key.x, entry.key.y), icon: Icon(Icons.add, color: Colors.cyanAccent, size: 24,), adjustment: Offset(-14, -14)))
              .toList());
        });
      }
      if (mounted) {
        setState(() => _isScanning = state);
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  /// see https://github.com/chipweinberger/flutter_blue_plus/blob/master/packages/flutter_blue_plus/example/lib/screens/scan_screen.dart
  /// This is basically what is needed.
  /// Only difference is that when findMe is pressed, the location data is updated, not the scanResults and a pin is placed on the map.
  Future<void> _scan(BuildContext context) async {
    /// first attach a listener to result stream
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      withNames: [
        "xBeacon"
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BLE Trilateration'),
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
                  },
                  painters: circles,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Find me'),
                      onPressed: () async => _scan(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Clear'),
                      onPressed: () => setState(() {
                        pinPosition = null;
                        circles = [];
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