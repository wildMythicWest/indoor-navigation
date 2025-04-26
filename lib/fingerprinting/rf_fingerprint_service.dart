import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:indoor_navigation/fingerprinting/fingerprint_data.dart';
import 'package:indoor_navigation/fingerprinting/location_data.dart';
import 'package:indoor_navigation/fingerprinting/positioning_data.dart';
import 'package:indoor_navigation/floor/floor_ids.dart';

class LocationsRepository {

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final HttpsCallable getRelativeLocationFunction = FirebaseFunctions.instance.httpsCallable('get_relative_location'); // Function name


  List<LocationData> savedLocations = [];

  Future<void> saveFingerprintData(FingerprintData data) async {
    return;
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
    return savedLocations;
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

  Future<LocationData> getCurrentLocation(List<PositioningData> input) async {
    try {
      final result = await getRelativeLocationFunction.call(<String, dynamic>{
        'wifi_scan': {
          for (var data in input) data.bssid : data.rssi
        }
      });
      print("Response: ${result.data}");

      LocationData currentLocation = LocationData(
          locationId: "current",
          floorPlanId: FloorId.apartment,
          locationX: result.data['location_x'],
          locationY: result.data['location_y']
      );
      print("Current location: ${currentLocation.locationX}, ${currentLocation.locationY}");

      return currentLocation;
    } catch (e) {
      // Handle errors if the Firebase function call fails
      print("Error during function call: $e");
      rethrow;
    }
  }

}