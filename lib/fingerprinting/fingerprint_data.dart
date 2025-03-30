import 'package:indoor_navigation/fingerprinting/location_data.dart';
import 'package:indoor_navigation/fingerprinting/positioning_data.dart';

class FingerprintData {
  final LocationData locationData;
  final List<PositioningData> positioningData; // fingerprinting data

  FingerprintData({
    required this.locationData,
    required this.positioningData,
  });
}