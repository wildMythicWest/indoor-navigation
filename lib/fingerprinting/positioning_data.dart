class PositioningData {

  final String ssid; // name of network
  final String bssid; // mac address of Access Point
  final int rssi; // received signal strength indicator

  const PositioningData({
    required this.ssid,
    required this.bssid,
    required this.rssi,
  });

  Map<String, dynamic> toMap() {
  return {
  'ssid': ssid.isNotEmpty ? ssid : "***",
  'bssid': bssid,
  'rssi': rssi,
  };
  }

}