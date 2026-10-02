import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../utils/screen_util.dart';
import '../../../../gen/assets.gen.dart';
import '../widgets/confetti_painter.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({super.key});

  @override
  State<CongratulationsScreen> createState() =>
      _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen>
    with SingleTickerProviderStateMixin {
  // ── ticker ──────────────────────────────────────────────────────────────
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── particles ────────────────────────────────────────────────────────────
  final List<ConfettiParticle> _particles = [];
  final Random _rnd = Random(42); // deterministic seed
  final GlobalKey _coneKey = GlobalKey();

  // ── gravity (pixels per second²) ─────────────────────────────────────────
  static const double _gravity = 320.0;

  // ── screen size set on first frame ───────────────────────────────────────
  Size _screenSize = Size.zero;
  bool _spawned = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _scheduleNavigation();
  }

  void _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 4500));
    if (mounted) context.go(AppRouter.personalization);
  }

  // ── Called once we know the screen size and widget positions ─────────────
  void _spawnParticles(Size size) {
    _spawned = true;
    
    // Find exact center of the cone image, adjusted to the tip
    Offset origin = Offset(size.width / 2, size.height * 0.3); // fallback
    if (_coneKey.currentContext != null) {
      final RenderBox box = _coneKey.currentContext!.findRenderObject() as RenderBox;
      final Offset position = box.localToGlobal(Offset.zero);
      // The tip of the cone in a square asset is typically near the center or slightly above.
      // We set it to the horizontal center, and 40% down from the top of the image box.
      origin = Offset(
        position.dx + (box.size.width / 2), 
        position.dy + (box.size.height * 0.35) 
      ); 
    }

    const int count = 90;
    final shapes = ConfettiShape.values;

    for (int i = 0; i < count; i++) {
      // Spread: full 360° but weighted heavily upward (bias toward -π/2)
      // angle range: -π (left) to 0 (right), centred on straight up (-π/2)
      final double angle = -pi + _rnd.nextDouble() * pi;
      // Speed: varied so pieces travel different distances
      final double speed = 180.0 + _rnd.nextDouble() * 380.0;

      final vx = cos(angle) * speed;
      final vy = sin(angle) * speed; // negative = upward in Flutter

      final double size0 = 4.0 + _rnd.nextDouble() * 7.0;
      final ConfettiShape shape = shapes[_rnd.nextInt(shapes.length)];
      final Color color = kConfettiColors[_rnd.nextInt(kConfettiColors.length)];

      _particles.add(ConfettiParticle(
        position: origin,
        velocity: Offset(vx, vy),
        rotation: _rnd.nextDouble() * pi * 2,
        rotationVelocity: (_rnd.nextDouble() - 0.5) * 12.0,
        size: size0,
        opacity: 1.0,
        color: color,
        shape: shape,
        scaleX: 1.0,
      ));
    }
  }

  // ── Ticker callback ───────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // Lazy-initialise once screen size is known AND the widget has been laid out
    if (!_spawned && _screenSize != Size.zero && _coneKey.currentContext != null) {
      _spawnParticles(_screenSize);
    }

    final double dt = _lastElapsed == Duration.zero
        ? 0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;

    if (dt <= 0 || _particles.isEmpty) return;

    setState(() {
      for (final p in _particles) {
        // Apply gravity
        p.velocity = Offset(p.velocity.dx, p.velocity.dy + _gravity * dt);

        // Move
        p.position = Offset(
          p.position.dx + p.velocity.dx * dt,
          p.position.dy + p.velocity.dy * dt,
        );

        // Rotate
        p.rotation += p.rotationVelocity * dt;

        // 3-D tumble for ribbons (cosine of time gives ±1 oscillation)
        p.scaleX = cos(elapsed.inMilliseconds / 300.0 + p.rotation);

        // Fade out after 2.5 s
        final double t = elapsed.inMilliseconds / 2500.0;
        p.opacity = (1.0 - (t - 0.6).clamp(0.0, 1.0) / 0.4).clamp(0.0, 1.0);
      }

      // Remove particles that have left the screen entirely
      if (_screenSize != Size.zero) {
        _particles.removeWhere((p) =>
            p.position.dy > _screenSize.height + 60 ||
            p.position.dx < -80 ||
            p.position.dx > _screenSize.width + 80);
      }

      // Stop ticker when all gone or after 4 s (save battery)
      if (_particles.isEmpty || elapsed.inMilliseconds > 4000) {
        _ticker.stop();
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    // Capture screen size on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_spawned) {
        final size = MediaQuery.of(context).size;
        if (size != Size.zero && _coneKey.currentContext != null) {
          _screenSize = size;
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // ── Background (full-screen) ──────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: ConfettiPainter(particles: _particles),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Celebration graphic as the burst focal point
                  Image.asset(
                    key: _coneKey,
                    Assets.png.confetti.path,
                    height: 160,
                    width: 160,
                  ),

                  6.sh,

                  Text(
                    'Congratulations!',
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  4.sh,

                  Text(
                    'You\'ve just taken an important step toward prioritizing your mental well-being.',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  4.sh,

                  Text(
                    'Cozy is here to support you every step of the way.',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  8.sh,

                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
