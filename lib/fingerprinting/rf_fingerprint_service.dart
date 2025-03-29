

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:indoor_navigation/fingerprinting/location_data.dart';

class RfFingerprintService {

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  Future<void> saveFingerprintData(LocationData data) async {
    CollectionReference locations = FirebaseFirestore.instance.collection('locations');
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    try {
      await locations.doc(data.locationId).set({
        'device': {
          'device_name': androidInfo.name,
          'device_model': '${androidInfo.manufacturer} ${androidInfo.model}'
        },
        'floor_plan': data.floorPlanId,
        'location_x': data.locationX,
        'location_y': data.locationY,
        'fingerprint_data': data.positioningData.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      // do nothing
    }
  }
}