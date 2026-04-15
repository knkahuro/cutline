import 'dart:ui';

class ObjectSilhouette {
  final String name;
  final List<Offset> points;
  final List<List<Offset>> holes;

  ObjectSilhouette({
    required this.name,
    required this.points,
    this.holes = const [],
  });
}

class ObjectLibrary {
  static final List<ObjectSilhouette> silhouettes = [
    ObjectSilhouette(
      name: 'Heart',
      points: [
        const Offset(0, 30),
        const Offset(30, -10),
        const Offset(60, -40),
        const Offset(80, -70),
        const Offset(85, -100),
        const Offset(70, -130),
        const Offset(40, -140),
        const Offset(10, -130),
        const Offset(0, -110),
        const Offset(-10, -130),
        const Offset(-40, -140),
        const Offset(-70, -130),
        const Offset(-85, -100),
        const Offset(-80, -70),
        const Offset(-60, -40),
        const Offset(-30, -10),
      ].map((p) => p + const Offset(0, 60)).toList(), // Shifted to center
    ),
    ObjectSilhouette(
      name: 'Bottle',
      points: [
        const Offset(-20, -100),
        const Offset(20, -100),
        const Offset(20, -60),
        const Offset(50, -20),
        const Offset(60, 40),
        const Offset(60, 100),
        const Offset(-60, 100),
        const Offset(-60, 40),
        const Offset(-50, -20),
        const Offset(-20, -60),
      ],
    ),
    ObjectSilhouette(
      name: 'House',
      points: [
        const Offset(0, -100),
        const Offset(80, -20),
        const Offset(80, 80),
        const Offset(-80, 80),
        const Offset(-80, -20),
      ],
      holes: [
        [
          const Offset(-20, 20),
          const Offset(20, 20),
          const Offset(20, 60),
          const Offset(-20, 60),
        ]
      ],
    ),
    ObjectSilhouette(
      name: 'Wrench',
      points: [
        const Offset(-20, -80),
        const Offset(20, -80),
        const Offset(20, 80),
        const Offset(-20, 80),
        // Simplistic handle
      ],
      // Actually let's make a better wrench
    ),
    ObjectSilhouette(
      name: 'Crescent',
      points: [
         const Offset(0, -100),
         const Offset(40, -80),
         const Offset(70, -40),
         const Offset(80, 0),
         const Offset(70, 40),
         const Offset(40, 80),
         const Offset(0, 100),
         const Offset(20, 70),
         const Offset(35, 30),
         const Offset(35, -30),
         const Offset(20, -70),
      ],
    ),
    ObjectSilhouette(
      name: 'Blade',
      points: [
        const Offset(-15, -120),
        const Offset(15, -120),
        const Offset(15, 80),
        const Offset(40, 100),
        const Offset(0, 140),
        const Offset(-15, 80),
      ],
    ),
    ObjectSilhouette(
      name: 'Fish',
      points: [
        const Offset(-80, 0),
        const Offset(-40, -40),
        const Offset(20, -50),
        const Offset(60, -20),
        const Offset(100, -60),
        const Offset(80, 0),
        const Offset(100, 60),
        const Offset(60, 20),
        const Offset(20, 50),
        const Offset(-40, 40),
      ],
      holes: [
        [
           const Offset(-55, -10),
           const Offset(-45, -10),
           const Offset(-45, 0),
           const Offset(-55, 0),
        ]
      ],
    ),
  ];
}
