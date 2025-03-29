

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:indoor_navigation/fingerprinting/positioning_data.dart';


class RfFingerprintService {

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  Future<void> saveFingerprintData(List<PositioningData> data) async {
    CollectionReference locations = FirebaseFirestore.instance.collection('locations');
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    try {
      await locations.doc('location_demo').set({
        'device': {
          'device_name': androidInfo.name,
          'device_model': '${androidInfo.manufacturer} ${androidInfo.model}'
        },
        'fingerprint_data': data.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      // do nothing
    }
  }
}