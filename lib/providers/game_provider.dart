import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/geometry_utils.dart';
import '../utils/constants.dart';
import '../utils/object_library.dart';

class GameProvider extends ChangeNotifier {
  List<Offset> _currentPolygon = [];
  List<List<Offset>> _holes = [];
  List<Offset> _cutPath = [];
  double _targetRatio = 0.5;
  double? _lastScore;
  bool _isSymmetric = false;
  bool _isPointy = false;
  bool _gameEnded = false;

  // Multiplayer
  bool _isMultiplayer = false;
  int _playerCount = 2;
  int _currentPlayerIndex = 0;
  List<double> _multiplayerScores = [];
  bool _isWaitingForNextPlayer = false;

  List<Offset> get currentPolygon => _currentPolygon;
  List<List<Offset>> get holes => _holes;
  List<Offset> get cutPath => _cutPath;
  double get targetRatio => _targetRatio;
  double? get lastScore => _lastScore;
  bool get isSymmetric => _isSymmetric;
  bool get isPointy => _isPointy;
  bool get gameEnded => _gameEnded;

  // Multiplayer getters
  bool get isMultiplayer => _isMultiplayer;
  int get playerCount => _playerCount;
  int get currentPlayerIndex => _currentPlayerIndex;
  List<double> get multiplayerScores => _multiplayerScores;
  bool get isWaitingForNextPlayer => _isWaitingForNextPlayer;

  GameProvider() {
    newGame();
  }

  void newGame() {
    final random = Random();
    // 20% chance to pick from library automatically
    if (random.nextDouble() < 0.2) {
      final silhouette = ObjectLibrary.silhouettes[random.nextInt(ObjectLibrary.silhouettes.length)];
      _loadSilhouetteData(silhouette);
    } else {
      _currentPolygon = GeometryUtils.generateShape(
        symmetric: _isSymmetric,
        size: GameConstants.maxShapeSize,
        smooth: !_isPointy,
      );
      _holes = GeometryUtils.generateHoles(_currentPolygon, smooth: !_isPointy);
    }
    _cutPath = [];
    _gameEnded = false;
    _currentPlayerIndex = 0;
    _multiplayerScores = [];
    _isWaitingForNextPlayer = false;
    _lastScore = null;
    notifyListeners();
  }

  void loadSilhouette(ObjectSilhouette silhouette) {
    _loadSilhouetteData(silhouette);
    _cutPath = [];
    _gameEnded = false;
    _currentPlayerIndex = 0;
    _multiplayerScores = [];
    _isWaitingForNextPlayer = false;
    _lastScore = null;
    notifyListeners();
  }

  void _loadSilhouetteData(ObjectSilhouette silhouette) {
    _currentPolygon = List.from(silhouette.points);
    _holes = silhouette.holes.map((h) => List<Offset>.from(h)).toList();
  }

  void updateCutStart(Offset pos) {
    if (_gameEnded) return;
    _cutPath = [pos];
    notifyListeners();
  }

  void updateCutEnd(Offset pos) {
    if (_gameEnded) return;
    _cutPath.add(pos);
    notifyListeners();
  }

  void submitCut() {
    if (_cutPath.length < 2 || _gameEnded) return;
    
    // Check total distance to prevent accidental tiny taps
    double dist = 0;
    for (int i = 0; i < _cutPath.length - 1; i++) {
       dist += (_cutPath[i+1] - _cutPath[i]).distance;
    }
    
    if (dist < 30) {
      _cutPath = [];
      notifyListeners();
      return;
    }

    final splitOuter = GeometryUtils.splitPolygonWithPolyline(_currentPolygon, _cutPath);
    
    // Split all holes
    final splitHoles = _holes.map((h) => GeometryUtils.splitPolygonWithPolyline(h, _cutPath)).toList();

    // Area 1 = Area(Outer1) - Sum(Area(HolePieces in Side 1))
    double area1 = GeometryUtils.calculateArea(splitOuter[0]);
    for (var sh in splitHoles) {
      area1 -= GeometryUtils.calculateArea(sh[0]);
    }

    // Area 2 = Area(Outer2) - Sum(Area(HolePieces in Side 2))
    double area2 = GeometryUtils.calculateArea(splitOuter[1]);
    for (var sh in splitHoles) {
      area2 -= GeometryUtils.calculateArea(sh[1]);
    }

    final totalArea = area1 + area2;

    if (totalArea > 0) {
      final ratio1 = area1 / totalArea;
      final ratio2 = area2 / totalArea;
      final diff1 = (ratio1 - _targetRatio).abs();
      final diff2 = (ratio2 - _targetRatio).abs();
      final bestDiff = diff1 < diff2 ? diff1 : diff2;
      _lastScore = (100 - (bestDiff * 200)).clamp(0, 100);
      
      if (_isMultiplayer) {
        _multiplayerScores.add(_lastScore!);
        if (_currentPlayerIndex < _playerCount - 1) {
          _isWaitingForNextPlayer = true;
        } else {
          _gameEnded = true;
        }
      } else {
        _gameEnded = true;
      }
    } else {
      _lastScore = 0;
      if (_isMultiplayer) _multiplayerScores.add(0);
      _gameEnded = true;
    }

    notifyListeners();
  }

  void startNextPlayer() {
    _currentPlayerIndex++;
    _cutPath = [];
    _isWaitingForNextPlayer = false;
    _lastScore = null;
    notifyListeners();
  }

  void setMultiplayer(bool value) {
    _isMultiplayer = value;
    newGame();
  }

  void setPlayerCount(int count) {
    _playerCount = count;
    newGame();
  }

  void setTargetRatio(double ratio) {
    _targetRatio = ratio;
    notifyListeners();
  }

  void setSymmetric(bool value) {
    _isSymmetric = value;
    newGame();
  }

  void setPointy(bool value) {
    _isPointy = value;
    newGame();
  }
}
