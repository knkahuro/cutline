import 'dart:math';
import 'package:flutter/material.dart';

class GeometryUtils {
  static double calculateArea(List<Offset> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int next = (i + 1) % points.length;
      area += (points[i].dx * points[next].dy) - (points[next].dx * points[i].dy);
    }
    return area.abs() / 2.0;
  }

  /// Checks if a point is inside a polygon using ray casting algorithm.
  static bool isPointInsidePolygon(Offset point, List<Offset> polygon) {
    if (polygon.isEmpty) return false;
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
          (point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) + polygon[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Calculates the minimum distance from a point to a polygon boundary.
  static double getMinDistanceToPolygon(Offset p, List<Offset> polygon) {
    if (polygon.isEmpty) return double.infinity;
    double minSqrDist = double.infinity;
    for (int i = 0; i < polygon.length; i++) {
      Offset v = polygon[i];
      Offset w = polygon[(i + 1) % polygon.length];
      
      double l2 = (v - w).distanceSquared;
      if (l2 == 0) {
        double d2 = (p - v).distanceSquared;
        if (d2 < minSqrDist) minSqrDist = d2;
        continue;
      }
      double t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
      t = max(0, min(1, t));
      Offset projection = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
      double distSq = (p - projection).distanceSquared;
      if (distSq < minSqrDist) minSqrDist = distSq;
    }
    return sqrt(minSqrDist);
  }

  /// Returns the number of unique boundary intersections a polyline makes with a polygon.
  static int getIntersectionCount(List<Offset> polygon, List<Offset> polyline) {
    if (polyline.length < 2 || polygon.isEmpty) return 0;
    
    List<Offset> intersections = [];
    const double epsilon = 0.001;

    for (int j = 0; j < polyline.length - 1; j++) {
      Offset s1 = polyline[j];
      Offset s2 = polyline[j + 1];
      for (int i = 0; i < polygon.length; i++) {
        Offset? intersect = _getLineIntersection(s1, s2, polygon[i], polygon[(i + 1) % polygon.length]);
        if (intersect != null) {
          // Check if we already have this intersection point (or one very close to it)
          bool isNew = true;
          for (var existing in intersections) {
            if ((existing - intersect).distance < epsilon) {
              isNew = false;
              break;
            }
          }
          if (isNew) {
            intersections.add(intersect);
          }
        }
      }
    }
    return intersections.length;
  }

  /// Splits a polygon using a polyline.
  /// Assumes the polyline crosses the polygon.
  static List<List<Offset>> splitPolygonWithPolyline(List<Offset> polygon, List<Offset> polyline) {
    if (polyline.length < 2) return [polygon, []];

    // 1. Find all intersections between polyline segments and polygon edges
    List<Map<String, dynamic>> intersections = []; // {point: Offset, polySeg: int, polyEdge: int, t: double}

    for (int j = 0; j < polyline.length - 1; j++) {
      Offset s1 = polyline[j];
      Offset s2 = polyline[j + 1];

      for (int i = 0; i < polygon.length; i++) {
        Offset v1 = polygon[i];
        Offset v2 = polygon[(i + 1) % polygon.length];

        Offset? intersect = _getLineIntersection(s1, s2, v1, v2);
        if (intersect != null) {
          intersections.add({
            'point': intersect,
            'polySeg': j,
            'polyEdge': i,
            't': (intersect - s1).distance / (s2 - s1).distance,
          });
        }
      }
    }

    if (intersections.length < 2) {
      // If we only have 0 or 1 intersection, it's not a complete cut.
      // We fall back to a straight line cut between start and end for safety,
      // or return nothing. Let's return the original.
      return [polygon, []];
    }

    // Sort intersections by their position on the polyline
    intersections.sort((a, b) {
      if (a['polySeg'] != b['polySeg']) return a['polySeg'].compareTo(b['polySeg']);
      return a['t'].compareTo(b['t']);
    });

    Offset entry = intersections.first['point'];
    Offset exit = intersections.last['point'];
    int entryEdge = intersections.first['polyEdge'];
    int exitEdge = intersections.last['polyEdge'];

    // Get the part of the polyline between first and last intersection
    List<Offset> cutPath = [];
    cutPath.add(entry);
    for (int j = intersections.first['polySeg'] + 1; j <= intersections.last['polySeg']; j++) {
      cutPath.add(polyline[j]);
    }
    cutPath[cutPath.length - 1] = exit;

    // Piece 1: Entry -> ... -> Exit along polygon (CW) -> ... -> Entry along cutPath (reversed)
    List<Offset> piece1 = [];
    piece1.addAll(_getPathAlongPolygon(polygon, entry, exit, entryEdge, exitEdge, true));
    piece1.addAll(cutPath.reversed.skip(1).take(cutPath.length - 2));

    // Piece 2: Entry -> ... -> Exit along polygon (CCW) -> ... -> Entry along cutPath (reversed)
    List<Offset> piece2 = [];
    piece2.addAll(_getPathAlongPolygon(polygon, entry, exit, entryEdge, exitEdge, false));
    piece2.addAll(cutPath.reversed.skip(1).take(cutPath.length - 2));

    return [piece1, piece2];
  }

  static List<Offset> _getPathAlongPolygon(List<Offset> polygon, Offset start, Offset end, int startEdge, int endEdge, bool clockwise) {
    List<Offset> path = [start];
    int n = polygon.length;
    
    if (clockwise) {
      int curEdge = startEdge;
      path.add(polygon[(curEdge + 1) % n]);
      curEdge = (curEdge + 1) % n;
      while (curEdge != endEdge) {
        path.add(polygon[(curEdge + 1) % n]);
        curEdge = (curEdge + 1) % n;
      }
    } else {
      int curEdge = startEdge;
      path.add(polygon[curEdge]);
      curEdge = (curEdge - 1 + n) % n;
      while (curEdge != (endEdge - 1 + n) % n) {
        path.add(polygon[curEdge]);
        curEdge = (curEdge - 1 + n) % n;
      }
    }
    path.add(end);
    return path;
  }

  static Offset? _getLineIntersection(Offset a, Offset b, Offset c, Offset d) {
    double det = (b.dx - a.dx) * (d.dy - c.dy) - (b.dy - a.dy) * (d.dx - c.dx);
    if (det == 0) return null; // Parallel

    double u = ((c.dx - a.dx) * (d.dy - c.dy) - (c.dy - a.dy) * (d.dx - c.dx)) / det;
    double v = ((c.dx - a.dx) * (b.dy - a.dy) - (c.dy - a.dy) * (b.dx - a.dx)) / det;

    if (u >= 0 && u <= 1 && v >= 0 && v <= 1) {
      return Offset(a.dx + u * (b.dx - a.dx), a.dy + u * (b.dy - a.dy));
    }
    return null;
  }

  static List<Offset> generateShape({
    required bool symmetric,
    required double size,
    bool smooth = false,
  }) {
    final random = Random();
    final int verticesCount = random.nextInt(4) + 6; // slightly more vertices
    List<Offset> points = [];

    if (symmetric) {
      int halfCount = (verticesCount / 2).ceil();
      List<Offset> halfPoints = [];
      for (int i = 0; i < halfCount; i++) {
        double angle = (pi * i) / (halfCount - 1) - pi / 2;
        double radius = (0.5 + random.nextDouble() * 0.5) * (size / 2);
        halfPoints.add(Offset(cos(angle) * radius, sin(angle) * radius));
      }
      points.addAll(halfPoints);
      for (int i = halfPoints.length - 2; i > 0; i--) {
        points.add(Offset(-halfPoints[i].dx, halfPoints[i].dy));
      }
    } else {
      for (int i = 0; i < verticesCount; i++) {
        double angle = (2 * pi * i) / verticesCount;
        double radius = (0.4 + random.nextDouble() * 0.6) * (size / 2);
        points.add(Offset(cos(angle) * radius, sin(angle) * radius));
      }
    }

    if (smooth) {
      points = _smoothPolygon(points, 4); // More iterations for better smoothing
    }

    Offset offset = Offset(random.nextDouble() * 20 - 10, random.nextDouble() * 20 - 10);
    return points.map((p) => p + offset).toList();
  }

  static List<List<Offset>> generateHoles(List<Offset> outer, {required bool smooth}) {
    final random = Random();
    if (random.nextDouble() > 0.4) return [];

    List<List<Offset>> holes = [];
    int holeTargetCount = random.nextInt(2) + 1;
    const double margin = 20.0;

    for (int i = 0; i < holeTargetCount; i++) {
      // 1. Generate a candidate hole centered at (0,0)
      List<Offset> holeBase = [];
      double holeSize = 30.0 + random.nextDouble() * 40.0;
      double angleOffset = random.nextDouble() * 2 * pi;
      int vCount = random.nextInt(3) + 3; // 3 to 5 vertices
      
      for (int v = 0; v < vCount; v++) {
        double angle = (2 * pi * v) / vCount + angleOffset;
        double radius = (0.7 + random.nextDouble() * 0.3) * (holeSize / 2);
        holeBase.add(Offset(cos(angle) * radius, sin(angle) * radius));
      }
      if (smooth) holeBase = _smoothPolygon(holeBase, 2);

      // 2. Try placing it multiple times
      List<Offset>? placedHole;
      for (int attempt = 0; attempt < 30; attempt++) {
        // Pick a random shift within a reasonable range
        Offset shift = Offset(
          (random.nextDouble() - 0.5) * 250,
          (random.nextDouble() - 0.5) * 250,
        );
        
        List<Offset> candidate = holeBase.map((p) => p + shift).toList();
        
        if (_isHolePlacementValid(candidate, outer, holes, margin)) {
          placedHole = candidate;
          break;
        }
      }

      if (placedHole != null) {
        holes.add(placedHole);
      }
    }
    return holes;
  }

  /// Validates if a hole placement is safe (inside outer, away from walls and other holes).
  static bool _isHolePlacementValid(List<Offset> hole, List<Offset> outer, List<List<Offset>> existingHoles, double margin) {
    // Check if every vertex of the hole is inside the outer polygon and respects the margin
    for (var p in hole) {
      if (!isPointInsidePolygon(p, outer)) return false;
      if (getMinDistanceToPolygon(p, outer) < margin) return false;
    }

    // Check if every vertex of the outer polygon respects the margin from the hole
    for (var p in outer) {
      if (getMinDistanceToPolygon(p, hole) < margin) return false;
    }

    // Check against existing holes
    for (var otherHole in existingHoles) {
      for (var p in hole) {
        if (getMinDistanceToPolygon(p, otherHole) < margin) return false;
      }
      for (var p in otherHole) {
        if (getMinDistanceToPolygon(p, hole) < margin) return false;
      }
    }

    return true;
  }

  static List<Offset> _smoothPolygon(List<Offset> points, int iterations) {
    List<Offset> smoothed = List.from(points);
    for (int k = 0; k < iterations; k++) {
       List<Offset> nextPoints = [];
       for (int i = 0; i < smoothed.length; i++) {
         Offset p1 = smoothed[i];
         Offset p2 = smoothed[(i + 1) % smoothed.length];

         // Chaikin's algorithm
         Offset q = Offset(p1.dx * 0.75 + p2.dx * 0.25, p1.dy * 0.75 + p2.dy * 0.25);
         Offset r = Offset(p1.dx * 0.25 + p2.dx * 0.75, p1.dy * 0.25 + p2.dy * 0.75);

         nextPoints.add(q);
         nextPoints.add(r);
       }
       smoothed = nextPoints;
    }
    return smoothed;
  }
}
