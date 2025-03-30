import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:indoor_navigation/fingerprinting/fingerprint_data.dart';
import 'package:indoor_navigation/fingerprinting/location_data.dart';

class LocationsRepository {

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<LocationData> savedLocations = [];

  Future<void> saveFingerprintData(FingerprintData data) async {
    CollectionReference locations = db.collection('locations');
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    try {
      await locations.doc(data.locationData.locationId).set({
        'device': {
          'device_name': androidInfo.name,
          'device_model': '${androidInfo.manufacturer} ${androidInfo.model}'
        },
        'floor_plan': data.locationData.floorPlanId,
        'location_x': data.locationData.locationX,
        'location_y': data.locationData.locationY,
        'fingerprint_data': data.positioningData.map((e) => e.toMap()).toList(),
      }).whenComplete(() => savedLocations.add(data.locationData));
    } catch (e) {
      // do nothing
    }
  }

  Future<List<LocationData>> getAllLocationsOnFloor(String floorPlan, bool forceUpdate) async {
    if (savedLocations.isNotEmpty && !forceUpdate) {
      return savedLocations;
    }

    QuerySnapshot querySnapshot = await db.collection('locations')
        .where('floor_plan', isEqualTo: floorPlan)
        .get();
    return querySnapshot.docs.map((doc) => LocationData(
        locationId: doc.id,
        floorPlanId: doc.get("floor_plan"),
        locationX: doc.get("location_x"),
        locationY: doc.get("location_y")))
        .toList();
  }
}