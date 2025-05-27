class LocationData {
  final String locationId; //uniquely identifies a place - currently uuid

  final String floorPlanId; // name of image of the floor plan
  final double locationX; // x coordinate relative to image
  final double locationY;// y coordinate relative to image

  LocationData({
    required this.locationId,
    required this.floorPlanId,
    required this.locationX,
    required this.locationY,
  });
}