import 'dart:async';

import 'package:flutter/material.dart';
import 'package:indoor_navigation/fingerprinting/positioning_data.dart';
import 'package:indoor_navigation/fingerprinting/rf_fingerprint_service.dart';
import 'package:indoor_navigation/floor/floor_ids.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../fingerprinting/location_data.dart';
import '../floor/image.dart';
import '../global_utils.dart';

/// Example app for wifi_scan plugin.
class FindMePage extends StatefulWidget {
  /// Default constructor for [FindMePage] widget.
  const FindMePage({Key? key}) : super(key: key);

  @override
  State<FindMePage> createState() => _FindMePageState();
}

class _FindMePageState extends State<FindMePage> {
  LocationsRepository locationsRepository = LocationsRepository();
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  bool shouldCheckCan = true;

  bool get isStreaming => subscription != null;

  String selectedImage = FloorId.apartment; // Stores the selected image
  Offset? pinPosition; // Stores pin position
  List<Pin> allPins = [];

  Future<void> _findMe(BuildContext context) async {
    // check if "can" startScan
    if (shouldCheckCan) {
      // check if can-startScan
      final can = await WiFiScan.instance.canStartScan();
      // if can-not, then show error
      if (can != CanStartScan.yes) {
        if (context.mounted) kShowSnackBar(context, "Cannot start scan: $can");
        return;
      }
    }

    // call startScan API
    final result = await WiFiScan.instance.startScan();
    if (context.mounted) kShowSnackBar(context, "startScan: $result");
    // reset access points.

    List<WiFiAccessPoint> wifiScanData = await collectData(WiFiScan.instance.onScannedResultsAvailable, Duration(seconds: 5));

    LocationData foundLocation = await locationsRepository.getCurrentLocation(
    wifiScanData.map((el) => PositioningData(ssid: el.ssid, bssid: el.bssid, rssi: el.level)).toList());

    setState(() {
      pinPosition = Offset(foundLocation.locationX, foundLocation.locationY);
      if (pinPosition != null) {
        allPins.add(Pin(pinPosition: pinPosition!, color: Colors.red));
      }
    });
  }

  Future<List<WiFiAccessPoint>> collectData(Stream<List<WiFiAccessPoint>> stream, Duration timeout) async {
    List<WiFiAccessPoint> results = [];
    late StreamSubscription<List<WiFiAccessPoint>> subscription;

    final completer = Completer<List<WiFiAccessPoint>>();

    subscription = stream.listen((data) {
      results.addAll(data);
    }, onDone: () {
      if (!completer.isCompleted) {
        completer.complete(results);
      }
    }, onError: (error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    });

    // Timeout handling
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(results);
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    // stop subscription for scanned results
    subscription?.cancel();
    subscription = null;
    super.dispose();
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
                  locationsRepository: locationsRepository,
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