

import 'DeviceData.dart';

class ScanData {
    late final List<DeviceData> deviceDataList;
    late final String error;
    late final bool isError;

    ScanData(this.deviceDataList) {
        error = "";
        isError = false;
    }

    ScanData.error(this.error) {
        isError = true;
        deviceDataList = [];
    }
}