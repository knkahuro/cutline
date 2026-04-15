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
    int holeCount = random.nextInt(2) + 1;

    for (int i = 0; i < holeCount; i++) {
       List<Offset> hole = [];
       double holeSize = 30.0 + random.nextDouble() * 40.0;
       double angleOffset = random.nextDouble() * 2 * pi;
       
       for (int v = 0; v < 5; v++) {
         double angle = (2 * pi * v) / 5 + angleOffset;
         double radius = (0.8 + random.nextDouble() * 0.4) * (holeSize / 2);
         hole.add(Offset(cos(angle) * radius, sin(angle) * radius));
       }

       if (smooth) hole = _smoothPolygon(hole, 2);

       Offset shift = Offset(
         (random.nextDouble() - 0.5) * 100,
          (random.nextDouble() - 0.5) * 100,
       );
       
       holes.add(hole.map((p) => p + shift).toList());
    }
    return holes;
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
