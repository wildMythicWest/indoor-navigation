
import 'dart:async';

import 'package:indoor_navigation/scanner/Scanner.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WiFiScanner implements Scanner {

    List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
    StreamSubscription<List<WiFiAccessPoint>>? subscription;
    bool shouldCheckCan = true;

    bool get isStreaming => subscription != null;

    @override
    Future<ScanData> scan() async {
        final canStartScan = await WiFiScan.instance.canStartScan(askPermissions: true);
        if (canStartScan != CanStartScan.yes) {
            return ScanData.error("Not allowed to start scan: ${canStartScan.name}");
        }
        if (!await WiFiScan.instance.startScan()) {
            return ScanData.error("Failed starting scan");
        }

        final canGetResult = await WiFiScan.instance.canGetScannedResults(askPermissions: true);

        if (canGetResult != CanGetScannedResults.yes) {
            return ScanData.error("Not allowed to get scan results: ${canGetResult.name}");
        }
        final result = await WiFiScan.instance.getScannedResults();

        return map(result);
    }

    ScanData map(List<WiFiAccessPoint> data) {
        return ScanData(data.map((ap) => toDeviceData(ap)).toList());
    }

    DeviceData toDeviceData(WiFiAccessPoint ap) {
        return DeviceData(ap.bssid, ap.level);
    }
}