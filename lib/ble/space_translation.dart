import 'dart:math';
import 'dart:ui';

class TranslationConstants {
  static double pixelsPerMeter = (311.171875 - 231.806640625) / 2.841;
  static Point<double> imageOrigin = Point(138.51745684617896, 188.24063459703137);
}

class PixelSpacePoint extends Point<double> {
  const PixelSpacePoint(super.x, super.y);
  PixelSpacePoint.fromPoint(Point<double> p) : super(p.x, p.y);

  Offset toOffset() {
    return Offset(x, y);
  }

  RealSpacePoint imageToReal() {
    double dx = x - TranslationConstants.imageOrigin.x;
    double dy = TranslationConstants.imageOrigin.y - y;
    return RealSpacePoint(dx / TranslationConstants.pixelsPerMeter, dy / TranslationConstants.pixelsPerMeter);
  }
}

class RealSpacePoint extends Point<double> {
  const RealSpacePoint(super.x, super.y);
  RealSpacePoint.fromPoint(Point<double> p) : super(p.x, p.y);

  PixelSpacePoint realToImage() {
    double dx = x * TranslationConstants.pixelsPerMeter;
    double dy = y * TranslationConstants.pixelsPerMeter;
    return PixelSpacePoint(TranslationConstants.imageOrigin.x + dx, TranslationConstants.imageOrigin.y - dy);
  }
}