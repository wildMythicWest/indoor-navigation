

import 'ScanData.dart';


export 'DeviceData.dart';
export 'ScanData.dart';

export 'BLEScanner.dart';
export 'WiFiScanner.dart';

abstract class Scanner {
    Future<ScanData> scan();
}