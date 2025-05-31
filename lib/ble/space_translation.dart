import 'dart:math';
import 'dart:ui';

class TranslationConstants {
  // I/flutter (12586): Pin placed at: 231.806640625, 241.099609375
  // I/flutter (12586): Pin placed at: 311.171875, 241.841796875
  static double pixelsPerMeter = (311.171875 - 231.806640625) / 2.841;

  // I/flutter (12586): Pin placed at: 138.51745684617896, 188.24063459703137
  static Point<double> imageOrigin = Point(138.51745684617896, 188.24063459703137); // the robo-vacuum spot
  static Point<double> realOrigin = Point(0, 0);      // in meters
}

class PixelSpacePoint extends Point<double> {
  const PixelSpacePoint(super.x, super.y);
  PixelSpacePoint.fromPoint(Point<double> p) : super(p.x, p.y);

  Offset toOffset() {
    return Offset(x, y);
  }

  RealSpacePoint imageToReal() {
    double dx = x - TranslationConstants.imageOrigin.x;
    double dy = TranslationConstants.imageOrigin.y - y; // y-axis might be flipped
    return RealSpacePoint(dx / TranslationConstants.pixelsPerMeter, dy / TranslationConstants.pixelsPerMeter);
  }

}

class RealSpacePoint extends Point<double> {
  const RealSpacePoint(super.x, super.y);
  RealSpacePoint.fromPoint(Point<double> p) : super(p.x, p.y);

  PixelSpacePoint realToImage() {
    double dx = x * TranslationConstants.pixelsPerMeter;
    double dy = y * TranslationConstants.pixelsPerMeter;
    return PixelSpacePoint(TranslationConstants.imageOrigin.x + dx, TranslationConstants.imageOrigin.y - dy); // flip Y back
  }

}