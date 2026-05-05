import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/helper/login_helper.dart';
import 'package:ride_sharing_user_app/util/images.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationData;
  final String? userName;

  const SplashScreen({super.key, this.notificationData, this.userName});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late AnimationController _controller;
  late AnimationController _particlesController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initializeParticles();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    Get.find<SplashController>().initSharedData();
    Get.find<TripController>().rideCancellationReasonList();
    Get.find<TripController>().parcelCancellationReasonList();
    Get.find<AuthController>().remainingTime();
    Get.find<WalletController>().getPaymentGetWayList();

    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _route();
      }
    });

    if (!GetPlatform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkConnectivity();
      });
    }
  }

  void _initializeParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(random: _random));
    }
  }

  void _checkConnectivity() {
    bool isFirst = true;
    _onConnectivityChanged = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (!mounted) return;

      final bool isConnected = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);

      if (!isFirst || !isConnected) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: Duration(milliseconds: isConnected ? 1000 : 3000),
            content: Text(
              isConnected ? 'connected'.tr : 'no_connection'.tr,
              textAlign: TextAlign.center,
            ),
          ),
        );

        if (isConnected && !isFirst && mounted) {
          _route();
        }
      }
      isFirst = false;
    });
  }

  void _route() async {
    bool isSuccess = await Get.find<SplashController>().getConfigData();
    if (isSuccess) {
      LoginHelper().checkLoginRoutes(widget.notificationData, widget.userName);
    }
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    _controller.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideController>(builder: (rideController) {
        return GetBuilder<ProfileController>(builder: (profileController) {
          return GetBuilder<LocationController>(builder: (locationController) {
            return Container(
              color: Colors.white,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _particlesController,
                      builder: (context, child) {
                        for (final particle in _particles) {
                          particle.update();
                        }
                        return CustomPaint(
                          painter: ParticlePainter(_particles,
                              orangeColor: Theme.of(context).primaryColor),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),
                  ..._buildDecorativeCircles(),
                  Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        double scale = _scaleAnimation.value;
                        if (_controller.value >= 0.7) {
                          scale *= (1.0 +
                              (_pulseAnimation.value - 1.0) *
                                  ((_controller.value - 0.7) / 0.3));
                        }

                        return Transform.translate(
                          offset: const Offset(0, -18),
                          child: Transform.rotate(
                            angle: _rotationAnimation.value * pi,
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      Images.logoWithNameSvg,
                                      width: 162,
                                      height: 162,
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).primaryColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Text(
                                    //   'Soutraly Pro',
                                    //   style: Theme.of(context)
                                    //       .textTheme
                                    //       .headlineSmall
                                    //       ?.copyWith(
                                    //     color: Colors.white,
                                    //     fontWeight: FontWeight.w800,
                                    //     letterSpacing: 0.8,
                                    //     shadows: const [
                                    //       Shadow(
                                    //         color: Color(0x55000000),
                                    //         blurRadius: 10,
                                    //         offset: Offset(0, 3),
                                    //       )
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          });
        });
      }),
    );
  }

  List<Widget> _buildDecorativeCircles() {
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double progress =
              (_controller.value - 0.1 * (index + 1)).clamp(0.0, 0.8) / 0.8;

          if (_controller.value < 0.1 * (index + 1)) {
            return const SizedBox.shrink();
          }

          return Positioned(
            left: 50.0 + (index * 100.0),
            top: 100.0 + (index * 150.0),
            child: Opacity(
              opacity: (1.0 - progress) * 0.3,
              child: Transform.scale(
                scale: 1.0 + progress * 3,
                child: Container(
                  width: 30.0 + (index * 20.0),
                  height: 30.0 + (index * 20.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class Particle {
  double x, y, size, speed, opacity, angle;
  final Random random;

  Particle({required this.random})
      : x = 0,
        y = 0,
        size = 0,
        speed = 0,
        opacity = 0,
        angle = 0 {
    _reset();
  }

  void _reset() {
    x = random.nextDouble() * 1.2 - 0.1;
    y = random.nextDouble() * 1.2 - 0.1;
    size = 1.0 + random.nextDouble() * 3.0;
    speed = 0.001 + random.nextDouble() * 0.005;
    opacity = 0.1 + random.nextDouble() * 0.3;
    angle = random.nextDouble() * 2 * pi;
  }

  void update() {
    angle += speed;
    x += sin(angle) * 0.0005;
    y += cos(angle) * 0.0005;
    if (x < -0.1 || x > 1.1 || y < -0.1 || y > 1.1) {
      _reset();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color _orangeColor;
  ParticlePainter(this.particles, {Color orangeColor = const Color(0xFFFF6600)})
      : _orangeColor = orangeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    for (final particle in particles) {
      paint.color = _orangeColor.withValues(alpha: particle.opacity);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
