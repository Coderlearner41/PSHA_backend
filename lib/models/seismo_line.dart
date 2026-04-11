import 'package:latlong2/latlong.dart';

class SeismoLine {
  final int zoneId;
  final List<LatLng> points;

  SeismoLine(this.zoneId, this.points);
}