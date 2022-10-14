import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:trex_game/trex_game.dart';

enum PlayerState { crashed, jumping, running, waiting }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameRef<TRexGame>, CollisionCallbacks {
  Player() : super(size: Vector2(90, 88));

  // TODO: moon mode: 0.75, earth mode: 1.0, jupiter mode: 1.2
  final double gravity = 1;

  final double initialJumpVelocity = -15.0;
  final double introDuration = 1500.0;
  final double startXPosition = 50;

  double _jumpVelocity = 0.0;

  double get groundYPos {
    return (gameRef.size.y / 2) - height / 2;
  }

  @override
  Future<void> onLoad() async {
    // Body hitbox
    add(
      RectangleHitbox.relative(
        Vector2(0.7, 0.6),
        position: Vector2(0, height / 3),
        parentSize: size,
      ),
    );
    // Head hitbox
    add(
      RectangleHitbox.relative(
        Vector2(0.45, 0.35),
        position: Vector2(width / 2, 0),
        parentSize: size,
      ),
    );
    animations = {
      PlayerState.running: _getAnimation(
        size: Vector2(88.0, 90.0),
        frames: [Vector2(1514.0, 4.0), Vector2(1602.0, 4.0)],
        stepTime: 0.2,
        // stepTime: lerpDouble(0.2, 0.1, gameRef.speedProgress)!,
      ),
      PlayerState.waiting: _getAnimation(
        size: Vector2(88.0, 90.0),
        frames: [Vector2(76.0, 6.0)],
      ),
      PlayerState.jumping: _getAnimation(
        size: Vector2(88.0, 90.0),
        frames: [Vector2(1339.0, 6.0)],
      ),
      PlayerState.crashed: _getAnimation(
        size: Vector2(88.0, 90.0),
        frames: [Vector2(1782.0, 6.0)],
      ),
    };
    current = PlayerState.waiting;
    Timer.periodic(const Duration(seconds: 1), (_) {
      animations?[PlayerState.running]?.stepTime =
          lerpDouble(0.5, 0.01, gameRef.speedProgress)!;
    });
  }

  void jump(double speed) {
    if (current == PlayerState.jumping) {
      return;
    }

    current = PlayerState.jumping;
    _jumpVelocity = initialJumpVelocity - (speed / 500);
  }

  void reset() {
    y = groundYPos;
    _jumpVelocity = 0.0;
    current = PlayerState.running;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (current == PlayerState.jumping) {
      y += _jumpVelocity;
      _jumpVelocity += gravity;
      if (y > groundYPos) {
        reset();
      }
    } else {
      y = groundYPos;
    }

    if (gameRef.isIntro && x < startXPosition) {
      x += (startXPosition / introDuration) * dt * 5000;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    y = groundYPos;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    gameRef.gameOver();
  }

  SpriteAnimation _getAnimation({
    required Vector2 size,
    required List<Vector2> frames,
    double stepTime = double.infinity,
  }) {
    return SpriteAnimation.spriteList(
      frames
          .map(
            (vector) => Sprite(
              gameRef.spriteImage,
              srcSize: size,
              srcPosition: vector,
            ),
          )
          .toList(),
      stepTime: stepTime,
    );
  }
}
