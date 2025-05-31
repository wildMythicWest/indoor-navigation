
import 'package:indoor_navigation/ble/space_translation.dart';

/// DEVICE 1 - ScanResult{device: BluetoothDevice{remoteId: D7:02:13:00:02:FA, platformName: xBeacon, services: null}, advertisementData: AdvertisementData{advName: xBeacon, txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {76: [2, 21, 253, 165, 6, 147, 164, 226, 79, 177, 175, 207, 198, 235, 7, 100, 120, 37, 39, 17, 1, 250, 187]}, serviceData: {3560: [80, 11, 214, 3, 232, 1, 66, 215, 2, 19, 0, 2, 250, 39, 17, 1, 250]}, serviceUuids: []}, rssi: -48, timeStamp: 2025-05-28 17:29:29.898745}
/// DEVICE 2 - ScanResult{device: BluetoothDevice{remoteId: D7:02:13:00:02:FB, platformName: xBeacon, services: null}, advertisementData: AdvertisementData{advName: xBeacon, txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {76: [2, 21, 253, 165, 6, 147, 164, 226, 79, 177, 175, 207, 198, 235, 7, 100, 120, 37, 39, 17, 1, 251, 187]}, serviceData: {3560: [80, 11, 232, 3, 232, 1, 66, 215, 2, 19, 0, 2, 251, 39, 17, 1, 251]}, serviceUuids: []}, rssi: -51, timeStamp: 2025-05-28 17:32:58.506741}
/// DEVICE 3 - ScanResult{device: BluetoothDevice{remoteId: D7:02:13:00:02:F3, platformName: xBeacon, services: null}, advertisementData: AdvertisementData{advName: xBeacon, txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {76: [2, 21, 253, 165, 6, 147, 164, 226, 79, 177, 175, 207, 198, 235, 7, 100, 120, 37, 39, 17, 1, 243, 187]}, serviceData: {3560: [80, 11, 202, 3, 232, 1, 66, 215, 2, 19, 0, 2, 243, 39, 17, 1, 243]}, serviceUuids: []}, rssi: -58, timeStamp: 2025-05-28 17:35:44.418501}
/// DEVICE 4 - ScanResult{device: BluetoothDevice{remoteId: D7:02:13:00:02:F9, platformName: xBeacon, services: null}, advertisementData: AdvertisementData{advName: xBeacon, txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {76: [2, 21, 253, 165, 6, 147, 164, 226, 79, 177, 175, 207, 198, 235, 7, 100, 120, 37, 39, 17, 1, 249, 187]}, serviceData: {3560: [80, 11, 232, 3, 232, 1, 66, 215, 2, 19, 0, 2, 249, 39, 17, 1, 249]}, serviceUuids: []}, rssi: -63, timeStamp: 2025-05-28 17:39:24.993982}
/// DEVICE 5 - ScanResult{device: BluetoothDevice{remoteId: D7:02:13:00:02:F4, platformName: xBeacon, services: null}, advertisementData: AdvertisementData{advName: xBeacon, txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {76: [2, 21, 253, 165, 6, 147, 164, 226, 79, 177, 175, 207, 198, 235, 7, 100, 120, 37, 39, 17, 1, 244, 187]}, serviceData: {3560: [80, 11, 202, 3, 232, 1, 66, 215, 2, 19, 0, 2, 244, 39, 17, 1, 244]}, serviceUuids: []}, rssi: -62, timeStamp: 2025-05-28 17:43:57.235146}

/// Locations


enum Beacon {
  ble1(id: "D7:02:13:00:02:FA", location: PixelSpacePoint(161.93359375, 70.58203125), rssiAtZeroDistance: -52),
  ble2(id: "D7:02:13:00:02:FB", location: PixelSpacePoint(139.169921875, 194.15625), rssiAtZeroDistance: -52),
  ble3(id: "D7:02:13:00:02:F3", location: PixelSpacePoint(187.509765625, 221.24609375), rssiAtZeroDistance: -50),
  ble4(id: "D7:02:13:00:02:F9", location: PixelSpacePoint(214.931640625, 150.181640625), rssiAtZeroDistance: -57),
  ble5(id: "D7:02:13:00:02:F4", location: PixelSpacePoint(211.767578125, 103.423828125), rssiAtZeroDistance: -58);

  final String id;
  final PixelSpacePoint location;
  final int rssiAtZeroDistance;

  const Beacon({
    required this.id,
    required this.location,
    required this.rssiAtZeroDistance,
  });
}