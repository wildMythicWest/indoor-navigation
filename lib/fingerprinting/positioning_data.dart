

class PositioningData {

  final String ssid;
  final String bssid;
  final int rssi;

  final String floorPlanId;
  final double locationX;
  final double locationY;

  const PositioningData({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.floorPlanId,
    required this.locationX,
    required this.locationY
  });

  Map<String, dynamic> toMap() {
  return {
  'ssid': ssid.isNotEmpty ? ssid : "***",
  'bssid': bssid,
  'rssi': rssi,
  };
  }

}