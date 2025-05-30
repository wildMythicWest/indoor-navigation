import 'dart:async';

import 'package:flutter/material.dart';
import 'package:indoor_navigation/fingerprinting/fingerprint_data.dart';
import 'package:indoor_navigation/fingerprinting/positioning_data.dart';
import 'package:indoor_navigation/fingerprinting/rf_fingerprint_service.dart';
import 'package:indoor_navigation/floor/floor_ids.dart';
import 'package:uuid/uuid.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../fingerprinting/location_data.dart';
import '../floor/image.dart';
import '../global_utils.dart';

class FingerprintingPage extends StatefulWidget {
  /// Default constructor for [FingerprintingPage] widget.
  const FingerprintingPage({super.key});

  @override
  State<FingerprintingPage> createState() => _FingerprintingPageState();
}

class _FingerprintingPageState extends State<FingerprintingPage> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  StreamSubscription<List<WiFiAccessPoint>>? saveWifiFingerprintSubscription;
  bool shouldCheckCan = true;

  bool get isStreaming => subscription != null;

  /// Клас за комуникация с базата данни.
  LocationsRepository locationsRepository = LocationsRepository();

  /// Име на карта на етажа.
  /// Използва се за зареждане на изображението на картата върху екрана и запазването на сканирана локация в базата данни.
  String selectedImage = FloorId.theMallFloor0;

  /// Избрана позиция за сканиране върху картата.
  /// Пази координатите (x, y) на избран пиксел върху изображението.
  /// Използва се за запазване на сканирана локация в базата данни.
  Offset? pinPosition;

  /// Метод за сканиране за WiFi мрежи и записване на събраните резултати в база данни.
  Future<void> _startScan(BuildContext context) async {
    // Проверка дали приложението има необходимите права за сканиране за WiFi мрежи
    final can = await WiFiScan.instance.canStartScan();
    // Ако липсват права показваме съобщение на екрана.
    if (can != CanStartScan.yes) {
      if (context.mounted) kShowSnackBar(context, "Cannot start scan: $can");
      return;
    }

    // Започване на сканирането и показване на статус на екрана
    final result = await WiFiScan.instance.startScan();
    if (context.mounted) kShowSnackBar(context, "startScan: $result");

    await collectScanResults();
    fetchSavedPositions();
  }

  /// Събиране на резултати от сканирането.
  /// Резултатите се запазват в база данни.
  Future<void> collectScanResults() async {
    List<WiFiAccessPoint> wifiScanData = await collectData(WiFiScan.instance.onScannedResultsAvailable, Duration(seconds: 5));

    Set<String> unique = {};
    locationsRepository.saveFingerprintData(
        FingerprintData(
            locationData: LocationData(
              locationId: Uuid().v4(),
              floorPlanId: selectedImage,
              locationX: pinPosition!.dx,
              locationY: pinPosition!.dy,
            ),
            positioningData: wifiScanData.map((el) =>
                PositioningData(ssid: el.ssid,
                    bssid: el.bssid,
                    rssi: el.level
                )
            ).where((el) => unique.add(el.bssid))
            .toList()));
  }

  /// Метод за събиране на данни от поток със резултати от сканирането за мрежи.
  /// Този метод е необходим, защото в противен случай асинхроността на сканирането води до множество отделни записи в базата данни от едно сканиране.
  /// Това не е желателно защото води до по-неточни резултати.
  /// [stream] поток със сканирани резултати.
  /// [timeout] интервал от време за агрегиране на данните. След изтичане на интервала, потокът се затваря и агрегираните резултати се връщат.
  Future<List<WiFiAccessPoint>> collectData(Stream<List<WiFiAccessPoint>> stream, Duration timeout) async {
    List<WiFiAccessPoint> results = [];
    late StreamSubscription<List<WiFiAccessPoint>> subscription;
    final completer = Completer<List<WiFiAccessPoint>>();

    // Агрегираща функция, резултатите в потока се събират в [results]
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

    // Таймер, отброяващ зададения интервал от време.
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(results);
      }
    });

    return completer.future;
  }

  /// Пин-ове описващи сканирани позиции
  List<Marker> allPins = [];

  /// Изчертаване на екрана на всички сканирани локации.
  /// Метода извлича всички данни за положението на сканирани локации и ги задава в променливата [allPins].
  /// Извикването на метод [setState()] принуждава Flutter да преизчертае компонентите по екрана, които зависят от променените променливи.
  /// В случая това води до преизчертаване на пин-овете върху изображението на плана на етажа.
  void fetchSavedPositions() async {
    List<Pin> positions = (await locationsRepository.getAllLocationsOnFloor(selectedImage, false))
        .map((data) => Offset(data.locationX, data.locationY))
        .map((position) => Pin(pinPosition: position, color: Colors.green))
        .toList();
    setState(() {
      allPins = positions;
    });
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
    // stop subscription for scanned results
    subscription?.cancel();
    subscription = null;
    super.dispose();
  }

  bool showSavedPins = false;

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
                  pins: [...allPins, if (pinPosition != null) Pin(pinPosition: pinPosition!, color: Colors.red)],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showSavedPins = !showSavedPins;
                          if (showSavedPins) fetchSavedPositions();
                        });
                      },
                      child: Text(showSavedPins ? "Hide Saved Locations" : "Show Saved Locations"),
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