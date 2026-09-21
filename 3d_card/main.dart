import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Interactive3DCard()));
  }
}

class Interactive3DCard extends StatefulWidget {
  const Interactive3DCard({super.key});
  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _tilt = Offset.zero;
  Offset _pointer = Offset.zero;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.addListener(() {
      setState(() {
        _tilt =
            Offset.lerp(
              _tilt,
              Offset.zero,
              Curves.easeOut.transform(_controller.value),
            ) ??
            Offset.zero;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointer(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    final normalizedX = delta.dx / center.dx;
    final normalizedY = delta.dy / center.dy;
    setState(() {
      _tilt = Offset(
        normalizedX.clamp(-1.0, 1.0),
        normalizedY.clamp(-1.0, 1.0),
      );
      _pointer = Offset(
        (localPosition.dx / size.width).clamp(0.0, 1.0),
        (localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  void _resetCard() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth - 32, 360.0);
        final height = width * 1.35;
        return GestureDetector(
          onPanStart: (_) {
            _controller.stop();
          },
          onPanUpdate: (details) {
            _handlePointer(details.localPosition, Size(width, height));
          },
          onPanEnd: (_) {
            _resetCard();
          },
          onPanCancel: _resetCard,
          child: SizedBox(
            width: width,
            height: height,
            child: _buildCard(width, height),
          ),
        );
      },
    );
  }

  Widget _buildCard(double width, double height) {
    final rotationX = -_tilt.dy * 0.28;
    final rotationY = _tilt.dx * 0.28;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateX(rotationX)
      ..rotateY(rotationY);
    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            _buildGlow(width, height),
            _buildContent(),
            _buildBorder(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27272A), Color(0xFF09090B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 20),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(double width, double height) {
    return Positioned(
      left: (_pointer.dx * width) - 140,
      top: (_pointer.dy * height) - 140,
      child: IgnorePointer(
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.20),
                Colors.white.withOpacity(0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Icon(Icons.auto_awesome, size: 34, color: Colors.white),
          const SizedBox(height: 24),
          const Text(
            'INTERACTIVE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '3D CARD',
            style: TextStyle(
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Move your finger',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDot(),
              const Icon(Icons.arrow_outward_rounded, color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBorder() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
      ),
    );
  }
}
