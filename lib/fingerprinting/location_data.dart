

import 'package:indoor_navigation/fingerprinting/positioning_data.dart';

class LocationData {
  final String locationId; //uniquely identifies a place - currently uuid

  final String floorPlanId; // name of image
  final double locationX; // x coordinate relative to image (or screen idk)
  final double locationY;// y coordinate relative to image (or screen idk)

  final List<PositioningData> positioningData; // fingerprinting data

  LocationData({
    required this.locationId,
    required this.floorPlanId,
    required this.locationX,
    required this.locationY,
    required this.positioningData,
  });
}