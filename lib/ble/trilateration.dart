import 'dart:math';
import 'dart:ui';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:indoor_navigation/ble/space_translation.dart';

import 'ble_devices.dart';

class LocationResult {
  final Offset position;
  final Map<PixelSpacePoint, double> originAndRadius;

  LocationResult(this.position, this.originAndRadius);
}

class Trilateration {

  static LocationResult findMe(List<ScanResult> scanResults) {
    Map<RealSpacePoint, double> distancesMap = {};
    // find distance to all devices
    for (var result in scanResults) {
      // print(result);
      // if (result.rssi < -75) continue;

      Beacon device = Beacon.values
          .firstWhere((item) => item.id == result.device.remoteId.str);

      double powerD0 = device.rssiAtZeroDistance.toDouble();

      double powerD = result.rssi.toDouble();
      double d0 = 1; // 1 meter away
      double n = 3;

      // d is in meters
      double d = d0 * pow(10, (powerD0 - powerD) / (10 * n));

      distancesMap[device.location.imageToReal()] = d;
      print("Device ${device.name} - rssi $powerD - at distance $d");
    }

    // find trilateration point
    var myLocation = estimateLocation(distancesMap).realToImage();

    return LocationResult(myLocation.toOffset(), distancesMap.map((key, value) => MapEntry(key.realToImage(), value * TranslationConstants.pixelsPerMeter)));
  }

  static RealSpacePoint estimateLocation(Map<RealSpacePoint, double> distances) {
    // Initial guess: average of all known points
    double avgX = 0, avgY = 0;
    for (var p in distances.keys) {
      avgX += p.x;
      avgY += p.y;
    }
    avgX /= distances.length;
    avgY /= distances.length;

    RealSpacePoint guess = RealSpacePoint(avgX, avgY);

    // return gradientDescent(distances, guess);

    return leastSquares(distances, guess);
  }

  static RealSpacePoint leastSquares(Map<RealSpacePoint, double> distances, RealSpacePoint guess) {
    double learningRate = 0.01;
    int iterations = 1000;

    for (int i = 0; i < iterations; i++) {
      double dx = 0;
      double dy = 0;

      for (var entry in distances.entries) {
        final anchor = entry.key;
        final expectedDistance = entry.value;

        final actualDistance = sqrt(pow(guess.x - anchor.x, 2) + pow(guess.y - anchor.y, 2));
        if (actualDistance == 0) continue;

        // Gradient of squared error
        double error = actualDistance - expectedDistance;
        dx += error * (guess.x - anchor.x) / actualDistance;
        dy += error * (guess.y - anchor.y) / actualDistance;
        // print("Gradient of squared error: $error");
      }

      guess = RealSpacePoint(guess.x - learningRate * dx, guess.y - learningRate * dy);
      // print("Guess: $guess");
    }

    return guess;
  }

  static RealSpacePoint gradientDescent(Map<RealSpacePoint, double> distances, RealSpacePoint initialGuess) {
    List<RealSpacePoint> centers = distances.keys.toList();
    List<double> radii = distances.values.toList();
    RealSpacePoint pos = initialGuess;
    double learningRate = 0.01;

    for (int i = 0; i < 100; i++) {
      double dx = 0, dy = 0;

      for (int j = 0; j < centers.length; j++) {
        final diffX = pos.x - centers[j].x;
        final diffY = pos.y - centers[j].y;
        final dist = sqrt(diffX * diffX + diffY * diffY);
        if (dist == 0) continue;

        final err = dist - radii[j];
        dx += (err * diffX) / dist;
        dy += (err * diffY) / dist;
      }

      pos = RealSpacePoint(
        pos.x - learningRate * dx,
        pos.y - learningRate * dy,
      );
    }

    return pos;
  }
}

