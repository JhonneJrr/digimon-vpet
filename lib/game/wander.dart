// lib/game/wander.dart
import 'dart:math';

/// Pure horizontal "amble": the pet walks to random points along a ground band,
/// pausing between strolls. No Flame/Flutter deps — unit-testable. The game
/// layer reads [x], [facing], and [isWalking] each frame to drive the sprite.
class WanderController {
  WanderController({
    this.speed = 42,
    this.pauseMin = 1.2,
    this.pauseMax = 3.2,
    double Function()? rng,
  }) : _rng = rng ?? Random().nextDouble;

  final double speed; // px/s
  final double pauseMin, pauseMax;
  final double Function() _rng;

  double _minX = 0, _maxX = 0, _x = 0, _target = 0;
  double _pause = 0;
  bool _walking = false;
  int _facing = 1; // 1 = right, -1 = left

  double get x => _x;
  bool get isWalking => _walking;
  int get facing => _facing;

  /// Define the walkable band [minX, maxX]. Clamps the current x and parks the
  /// pet with a short pause before its next stroll.
  void setBand(double minX, double maxX, {double? startX}) {
    _minX = min(minX, maxX);
    _maxX = max(minX, maxX);
    _x = (startX ?? _x).clamp(_minX, _maxX);
    _target = _x;
    _walking = false;
    if (_pause <= 0) _pause = pauseMin;
  }

  void update(double dt) {
    if (_maxX <= _minX) {
      _walking = false;
      return;
    }
    if (_pause > 0) {
      _pause -= dt;
      _walking = false;
      if (_pause <= 0) _pickTarget();
      return;
    }
    final delta = _target - _x;
    final step = speed * dt;
    if (delta.abs() <= step) {
      _x = _target;
      _walking = false;
      _pause = pauseMin + _rng() * (pauseMax - pauseMin);
      return;
    }
    _facing = delta > 0 ? 1 : -1;
    _x += _facing * step;
    _walking = true;
  }

  void _pickTarget() {
    _target = _minX + _rng() * (_maxX - _minX);
    // If the pick is too close, stroll to a far edge instead so it actually moves.
    if ((_target - _x).abs() < (_maxX - _minX) * 0.15) {
      _target = (_x < (_minX + _maxX) / 2) ? _maxX : _minX;
    }
    _facing = _target >= _x ? 1 : -1;
    _walking = true;
  }
}
