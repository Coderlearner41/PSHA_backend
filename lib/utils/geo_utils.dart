import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const distance = Distance();

  static double distanceToSegment(
      LatLng p,
      LatLng v,
      LatLng w) {
    if (v == w) {
      return distance.as(
          LengthUnit.Kilometer,
          p,
          v);
    }

    double cosLat =
        math.cos(p.latitude * math.pi / 180);

    double x1 = v.longitude * cosLat;
    double y1 = v.latitude;

    double x2 = w.longitude * cosLat;
    double y2 = w.latitude;

    double xP = p.longitude * cosLat;
    double yP = p.latitude;

    num l2 =
        math.pow(x2 - x1, 2) +
            math.pow(y2 - y1, 2);

    double t =
        ((xP - x1) * (x2 - x1) +
                (yP - y1) *
                    (y2 - y1)) /
            l2;

    t = math.max(0.0, math.min(1.0, t));

    double projX =
        x1 + t * (x2 - x1);

    double projY =
        y1 + t * (y2 - y1);

    LatLng projected =
        LatLng(projY, projX / cosLat);

    return distance.as(
        LengthUnit.Kilometer,
        p,
        projected);
  }
}