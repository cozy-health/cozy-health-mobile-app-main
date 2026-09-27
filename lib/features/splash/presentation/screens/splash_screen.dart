import 'dart:math' as math;
import 'package:cozy_health/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/storage/token_storage.dart';

const Color _kBgC    = Color(0xFFF0ECD8);
const Color _kBlueC  = Color(0xFF1A68D0);
const Color _kYellowC= Color(0xFFF5C318);
const Color _kGreenC = Color(0xFF2D9E54);
const Color _kOrangeC= Color(0xFFF26B1D);

class _Particle {
  final double startX, startY;
  final double endX, endY;
  final double size;
  final Color  color;
  final double delay;
  final double spinDir;

  const _Particle({
    required this.startX, required this.startY,
    required this.endX,   required this.endY,
    required this.size,   required this.color,
    required this.delay,
    required this.spinDir,
  });
}

List<_Particle> _buildParticles(double sw, double sh) {
  final rng = math.Random(42);
  final colors = [_kBlueC, _kGreenC, _kOrangeC, _kYellowC];
  return List.generate(100, (i) {
    final angle = rng.nextDouble() * 2 * math.pi;
    final dist  = 0.6 + rng.nextDouble() * 0.3;
    final sx    = 0.5 + math.cos(angle) * dist;
    final sy    = 0.5 + math.sin(angle) * dist * (sh / sw);
    final ex    = 0.5 + (rng.nextDouble() - 0.5) * 0.12;
    final ey    = 0.5 + (rng.nextDouble() - 0.5) * 0.12;
    return _Particle(
      startX: sx, startY: sy,
      endX:   ex, endY:   ey,
      size:   2.0 + rng.nextDouble() * 6.0,
      color:  colors[i % colors.length],
      delay:  rng.nextDouble() * 0.5,
      spinDir: rng.nextBool() ? 1.0 : -1.0,
    );
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _partCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _dotCtrl;

  late final Animation<double> _logoAlpha;
  late final Animation<double> _logoScale;
  late final Animation<double> _flashRadius;
  late final Animation<double> _flashAlpha;

  List<_Particle>? _particles;
  bool _authDone = false;

  @override
  void initState() {
    super.initState();

    _partCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _dotCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

    _logoAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    
    _flashRadius = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutExpo),
    );
    _flashAlpha = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );

    _partCtrl.forward();
    // 0.8 * 2600ms = 2080ms. Trigger logo right when explosion happens
    Future.delayed(const Duration(milliseconds: 2080), () {
      if (mounted) {
        _logoCtrl.forward().then((_) {
          if (mounted && !_authDone) _dotCtrl.repeat(reverse: true);
        });
      }
    });

    _runAuthCheck();
  }

  Future<void> _runAuthCheck() async {
    final results = await Future.wait([
      _fetchToken(),
      Future.delayed(const Duration(milliseconds: 4500)),
    ]);
    final token = results[0] as String?;
    if (!mounted) return;
    setState(() => _authDone = true);
    _dotCtrl.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    context.go(token != null && token.isNotEmpty ? AppRouter.home : AppRouter.onboarding);
  }

  Future<String?> _fetchToken() async {
    try { return await TokenStorage().getToken(); } catch (_) { return null; }
  }

  @override
  void dispose() {
    _partCtrl.dispose();
    _logoCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final logoSz = size.width * 0.48;
    _particles ??= _buildParticles(size.width, size.height);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_partCtrl, _logoCtrl, _dotCtrl]),
        builder: (context, _) {
          final p  = _partCtrl.value;
          final la = _logoAlpha.value;
          final ls = _logoScale.value;
          final fr = _flashRadius.value;
          final fa = _flashAlpha.value;

          return Stack(children: [
            // Particles
            CustomPaint(
              size: size,
              painter: _ParticlePainter(
                progress: p,
                particles: _particles!, w: size.width, h: size.height,
              ),
            ),

            // Flash effect when logo appears
            if (la > 0 && fa > 0)
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: fa,
                    child: Container(
                      width: size.width * 1.5 * fr,
                      height: size.width * 1.5 * fr,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

            // Logo
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: la,
                  child: Transform.scale(
                    scale: ls,
                    child: SvgPicture.asset(Assets.svg.logo, width: logoSz, height: logoSz),
                  ),
                ),
              ),
            ),

            // Dots
            if (la > 0.4 && !_authDone)
              Positioned(
                bottom: size.height * 0.10,
                left: 0, right: 0,
                child: _LoadingDots(ctrl: _dotCtrl),
              ),
          ]);
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final double w, h;
  final _paint = Paint();

  _ParticlePainter({required this.progress, required this.particles, required this.w, required this.h});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      double x, y, currentAlpha, sizeScale;
      
      if (progress < 0.8) {
        // Phase 1: Fly in and cluster (progress 0.0 to 0.7 is moving, 0.7 to 0.8 is clustered)
        final localP = ((progress - p.delay) / (0.7 - p.delay)).clamp(0.0, 1.0);
        final tIn = Curves.easeOutCubic.transform(localP);
        
        final angleOffset = localP * math.pi * 1.5 * p.spinDir; 
        final dx = (p.startX - 0.5) * (1 - tIn) + (p.endX - 0.5) * tIn;
        final dy = (p.startY - 0.5) * (1 - tIn) + (p.endY - 0.5) * tIn;
        
        final cosA = math.cos(angleOffset);
        final sinA = math.sin(angleOffset);
        
        final rotDx = dx * cosA - dy * sinA;
        final rotDy = dx * sinA + dy * cosA;
        
        x = (0.5 + rotDx) * w;
        y = (0.5 + rotDy) * h;
        sizeScale = 1.0;
        currentAlpha = math.min(1.0, localP * 3.0); // fade in quickly at start
      } else {
        // Phase 2: Explode outward! (progress 0.8 to 1.0)
        final tOut = Curves.easeOutQuart.transform((progress - 0.8) / 0.2);
        
        final endAngle = 1.0 * math.pi * 1.5 * p.spinDir;
        final dx = (p.endX - 0.5);
        final dy = (p.endY - 0.5);
        final cosA = math.cos(endAngle);
        final sinA = math.sin(endAngle);
        
        final rotDx = dx * cosA - dy * sinA;
        final rotDy = dx * sinA + dy * cosA;
        
        final len = math.sqrt(rotDx*rotDx + rotDy*rotDy) + 0.001;
        final nx = rotDx / len;
        final ny = rotDy / len;
        
        final explodeDist = 0.5 * tOut; // fly radially out half the screen
        
        x = (0.5 + rotDx + nx * explodeDist) * w;
        y = (0.5 + rotDy + ny * explodeDist) * h;
        sizeScale = 1.0 + 3.0 * tOut; // get larger as they fly
        currentAlpha = 1.0 - tOut; // fade out
      }
      
      _paint.color = p.color.withOpacity(currentAlpha);
      canvas.drawCircle(Offset(x, y), p.size * sizeScale, _paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _LoadingDots extends StatelessWidget {
  final AnimationController ctrl;
  const _LoadingDots({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final phase = (ctrl.value + i * 0.28) % 1.0;
          final s = 0.4 + 0.6 * phase;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Transform.scale(
              scale: s,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _kBlueC.withOpacity(0.35 + 0.65 * phase),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
