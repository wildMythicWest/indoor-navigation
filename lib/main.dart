import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:indoor_navigation/fingerprinting/positioning_data.dart';
import 'package:indoor_navigation/fingerprinting/rf_fingerprint_service.dart';
import 'package:indoor_navigation/floor/floor_ids.dart';
import 'package:uuid/uuid.dart';
import 'package:wifi_scan/wifi_scan.dart';

import 'package:permission_handler/permission_handler.dart';

import 'fingerprinting/location_data.dart';
import 'floor/image.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  await dotenv.load(fileName: ".env");

  final firebaseOptions = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY']!,
    appId: dotenv.env['FIREBASE_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
  );


  await Firebase.initializeApp(options: firebaseOptions);

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.locationAlways
  ].request();
}

/// Example app for wifi_scan plugin.
class MyApp extends StatefulWidget {
  /// Default constructor for [MyApp] widget.
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RfFingerprintService rfFingerprintService = RfFingerprintService();
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  StreamSubscription<List<WiFiAccessPoint>>? saveWifiFingerprintSubscription;
  bool shouldCheckCan = true;

  bool get isStreaming => subscription != null;

  String selectedImage = FloorId.apartment; // Stores the selected image
  Offset? pinPosition; // Stores pin position

  Future<void> _startScan(BuildContext context) async {
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
    setState(() => accessPoints = <WiFiAccessPoint>[]);

    saveWifiFingerprintSubscription?.cancel();
    saveWifiFingerprintSubscription = null;
    saveWifiFingerprintSubscription = WiFiScan.instance.onScannedResultsAvailable
        .listen((result) => rfFingerprintService.saveFingerprintData(
        LocationData(locationId: "location_demo",
            floorPlanId: selectedImage,
            locationX: pinPosition!.dx,
            locationY: pinPosition!.dy,
            positioningData: result.map((el) => PositioningData(ssid: el.ssid,
                bssid: el.bssid,
                rssi: el.level
                )
            ).toList())));
  }

  Future<bool> _canGetScannedResults(BuildContext context) async {
    if (shouldCheckCan) {
      // check if can-getScannedResults
      final can = await WiFiScan.instance.canGetScannedResults();
      // if can-not, then show error
      if (can != CanGetScannedResults.yes) {
        if (context.mounted) {
          kShowSnackBar(context, "Cannot get scanned results: $can");
        }
        accessPoints = <WiFiAccessPoint>[];
        return false;
      }
    }
    return true;
  }

  Future<void> _getScannedResults(BuildContext context) async {
    if (await _canGetScannedResults(context)) {
      // get scanned results
      final results = await WiFiScan.instance.getScannedResults();
      setState(() => accessPoints = results);
    }
  }

  Future<void> _startListeningToScanResults(BuildContext context) async {
    if (await _canGetScannedResults(context)) {
      subscription = WiFiScan.instance.onScannedResultsAvailable
          .listen((result) => setState(() => accessPoints = result));
    }
  }

  void _stopListeningToScanResults() {
    subscription?.cancel();
    setState(() => subscription = null);
  }

  @override
  void dispose() {
    super.dispose();
    // stop subscription for scanned results
    _stopListeningToScanResults();
  }

  // build toggle with label
  Widget _buildToggle({
    String? label,
    bool value = false,
    ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) =>
      Row(
        children: [
          if (label != null) Text(label),
          Switch(value: value, onChanged: onChanged, activeColor: activeColor),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WiFi Positioning System'),
          actions: [
            _buildToggle(
                label: "Check can?",
                value: shouldCheckCan,
                onChanged: (v) => setState(() => shouldCheckCan = v),
                activeColor: Colors.purple)
          ],
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
                  pinPosition: pinPosition,
                  onImageChanged: (newImage) {
                    setState(() {
                      selectedImage = newImage;
                      pinPosition = null; // Reset pin when changing image
                    });
                  },
                  onPinPlaced: (newPin) {
                    setState(() {
                      pinPosition = newPin;
                    });
                  },),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.perm_scan_wifi),
                      label: const Text('SCAN'),
                      onPressed: () async => _startScan(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('GET'),
                      onPressed: () async => _getScannedResults(context),
                    ),
                    _buildToggle(
                      label: "STREAM",
                      value: isStreaming,
                      onChanged: (shouldStream) async => shouldStream
                          ? await _startListeningToScanResults(context)
                          : _stopListeningToScanResults(),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: Center(
                    child: accessPoints.isEmpty
                        ? const Text("NO SCANNED RESULTS")
                        : ListView.builder(
                        itemCount: accessPoints.length,
                        itemBuilder: (context, i) =>
                            _AccessPointTile(accessPoint: accessPoints[i])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show tile for AccessPoint.
///
/// Can see details when tapped.
class _AccessPointTile extends StatelessWidget {
  final WiFiAccessPoint accessPoint;

  const _AccessPointTile({Key? key, required this.accessPoint})
      : super(key: key);

  // build row that can display info, based on label: value pair.
  Widget _buildInfo(String label, dynamic value) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey)),
    ),
    child: Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value.toString()))
      ],
    ),
  );

  /// Following data can be used to determine signal quality:
  /// -30 dBm = Excellent
  /// -67 dBm = Very Good
  /// -70 dBm = Okay
  /// -80 dBm = Not Good
  /// -90 dBm = Unusable

  IconData getWifiIconForSignal(int rssi) {
    return switch(rssi) {
      >= -67 => Icons.signal_wifi_4_bar,
      >= -70 && < -67 => Icons.network_wifi_3_bar,
      >= -80 && < -70 => Icons.network_wifi_2_bar,
      >= -90 && < -80 => Icons.network_wifi_1_bar,
      < -90 => Icons.signal_wifi_0_bar,
      int() => Icons.wifi,
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = accessPoint.ssid.isNotEmpty ? accessPoint.ssid : "**EMPTY**";
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(getWifiIconForSignal(accessPoint.level)),
      title: Text("$title : ${accessPoint.bssid}"),
      subtitle: Text("${accessPoint.level}"),
      onTap: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfo("BSSDI", accessPoint.bssid),
              // _buildInfo("Capability", accessPoint.capabilities),
              // _buildInfo("frequency", "${accessPoint.frequency}MHz"),
              _buildInfo("level", accessPoint.level),
              // _buildInfo("standard", accessPoint.standard),
              // _buildInfo(
              //     "centerFrequency0", "${accessPoint.centerFrequency0}MHz"),
              // _buildInfo(
              //     "centerFrequency1", "${accessPoint.centerFrequency1}MHz"),
              // _buildInfo("channelWidth", accessPoint.channelWidth),
              // _buildInfo("isPasspoint", accessPoint.isPasspoint),
              // _buildInfo(
              //     "operatorFriendlyName", accessPoint.operatorFriendlyName),
              // _buildInfo("venueName", accessPoint.venueName),
              // _buildInfo("is80211mcResponder", accessPoint.is80211mcResponder),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show snackbar.
void kShowSnackBar(BuildContext context, String message) {
  if (kDebugMode) print(message);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}