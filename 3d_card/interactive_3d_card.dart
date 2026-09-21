// interactive_3d_card.dart
//
// A smooth, physics-based interactive 3D tilt card widget for Flutter.
// Drag or touch to tilt the card in 3D space, watch a soft light glow
// follow your finger, and let it spring back into place when you let go.
//
// Drop this single file into any project (e.g. lib/widgets/interactive_3d_card.dart)
// and import `Interactive3DCard` wherever you need it. No external
// dependencies required.
//
// Basic usage:
//   const Interactive3DCard()
//
// With your own content:
//   Interactive3DCard(child: Text('Hello'))
//
// See the bottom of this file for a runnable demo (`main`), which you can
// remove if you're only importing the widget into an existing app.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Signature for building the front-face content of an [Interactive3DCard].
///
/// Receives the current pointer position normalized to the card's local
/// space, where `(0, 0)` is the top-left corner and `(1, 1)` is the
/// bottom-right corner. Useful when your content should itself react to
/// where the user is dragging.
typedef Interactive3DCardContentBuilder = Widget Function(
  BuildContext context,
  Offset normalizedPointer,
);

/// A card that tilts in 3D space in response to drag/touch gestures, with a
/// soft light glow that follows the pointer and a smooth spring-back
/// animation once the gesture ends.
///
/// Out of the box, with no parameters, [Interactive3DCard] renders a
/// default demo face (icon, title, subtitle). Every visual and behavioral
/// aspect can be customized via the constructor, and [child] /
/// [contentBuilder] let you render your own content while keeping the
/// tilt, glow and spring-back mechanics.
///
/// Example:
/// ```dart
/// Interactive3DCard(
///   child: Text('Hello', style: TextStyle(color: Colors.white)),
/// )
/// ```
class Interactive3DCard extends StatefulWidget {
  const Interactive3DCard({
    super.key,
    this.width,
    this.maxWidth = 360.0,
    this.aspectRatio = 1.35,
    this.horizontalMargin = 32.0,
    this.borderRadius = 32.0,
    this.tiltSensitivity = 0.28,
    this.perspective = 0.0015,
    this.resetDuration = const Duration(milliseconds: 500),
    this.resetCurve = Curves.easeOut,
    this.backgroundGradient,
    this.boxShadow,
    this.glowColor,
    this.glowSize = 280.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.child,
    this.contentBuilder,
    this.onTiltChanged,
  }) : assert(
         child == null || contentBuilder == null,
         'Provide either child or contentBuilder, not both.',
       );

  /// Fixed width of the card. If null, the card expands to fill the
  /// available width (via [LayoutBuilder]), capped at [maxWidth] and
  /// reduced by [horizontalMargin] — matching the original behavior.
  final double? width;

  /// The maximum width the card can take when [width] is not provided.
  final double maxWidth;

  /// Height-to-width ratio used to derive the card's height.
  final double aspectRatio;

  /// Horizontal space reserved when sizing the card automatically (mirrors
  /// the original `constraints.maxWidth - 32`).
  final double horizontalMargin;

  /// Corner radius of the card.
  final double borderRadius;

  /// How strongly the card rotates in response to drag distance from its
  /// center. Higher values tilt more aggressively.
  final double tiltSensitivity;

  /// The perspective (`m34`) entry used for the 3D transform.
  final double perspective;

  /// Duration of the spring-back animation once the gesture ends.
  final Duration resetDuration;

  /// Curve used for the spring-back animation.
  final Curve resetCurve;

  /// Background gradient of the card. Defaults to a dark zinc gradient.
  final Gradient? backgroundGradient;

  /// Shadow(s) cast by the card. Defaults to a soft black drop shadow.
  final List<BoxShadow>? boxShadow;

  /// Color of the radial glow that follows the pointer. Defaults to white.
  final Color? glowColor;

  /// Diameter of the glow.
  final double glowSize;

  /// Color of the thin border drawn around the card. Defaults to a subtle
  /// white outline.
  final Color? borderColor;

  /// Width of the border stroke.
  final double borderWidth;

  /// Static content to render on the card's face. Ignored if
  /// [contentBuilder] is provided. If both are null, a default demo face
  /// is shown.
  final Widget? child;

  /// Builds the card's face dynamically, given the current normalized
  /// pointer position. Ignored if [child] is provided.
  final Interactive3DCardContentBuilder? contentBuilder;

  /// Called whenever the tilt offset changes. Values are roughly within
  /// `[-1, 1]` on each axis, where `(0, 0)` means no tilt.
  final ValueChanged<Offset>? onTiltChanged;

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
      duration: widget.resetDuration,
    );
    _controller.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(covariant Interactive3DCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetDuration != widget.resetDuration) {
      _controller.duration = widget.resetDuration;
    }
  }

  void _onControllerTick() {
    final next = Offset.lerp(
          _tilt,
          Offset.zero,
          widget.resetCurve.transform(_controller.value),
        ) ??
        Offset.zero;
    setState(() => _tilt = next);
    widget.onTiltChanged?.call(_tilt);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    _controller.dispose();
    super.dispose();
  }

  void _handlePointer(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    final normalizedX = delta.dx / center.dx;
    final normalizedY = delta.dy / center.dy;
    final tilt = Offset(
      normalizedX.clamp(-1.0, 1.0),
      normalizedY.clamp(-1.0, 1.0),
    );
    setState(() {
      _tilt = tilt;
      _pointer = Offset(
        (localPosition.dx / size.width).clamp(0.0, 1.0),
        (localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
    widget.onTiltChanged?.call(tilt);
  }

  void _resetCard() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.width != null) {
      final height = widget.width! * widget.aspectRatio;
      return _buildGestureArea(widget.width!, height);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth - widget.horizontalMargin,
          widget.maxWidth,
        );
        final height = width * widget.aspectRatio;
        return _buildGestureArea(width, height);
      },
    );
  }

  Widget _buildGestureArea(double width, double height) {
    return GestureDetector(
      onPanStart: (_) => _controller.stop(),
      onPanUpdate: (details) =>
          _handlePointer(details.localPosition, Size(width, height)),
      onPanEnd: (_) => _resetCard(),
      onPanCancel: _resetCard,
      child: SizedBox(
        width: width,
        height: height,
        child: _buildCard(width, height),
      ),
    );
  }

  Widget _buildCard(double width, double height) {
    final rotationX = -_tilt.dy * widget.tiltSensitivity;
    final rotationY = _tilt.dx * widget.tiltSensitivity;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, widget.perspective)
      ..rotateX(rotationX)
      ..rotateY(rotationY);
    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            _buildGlow(width, height),
            _buildContent(context),
            _buildBorder(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: widget.backgroundGradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF27272A), Color(0xFF09090B)],
            ),
        boxShadow: widget.boxShadow ??
            [
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
    final glowColor = widget.glowColor ?? Colors.white;
    return Positioned(
      left: (_pointer.dx * width) - widget.glowSize / 2,
      top: (_pointer.dy * height) - widget.glowSize / 2,
      child: IgnorePointer(
        child: Container(
          width: widget.glowSize,
          height: widget.glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withOpacity(0.20),
                glowColor.withOpacity(0.04),
                glowColor.withOpacity(0.0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.contentBuilder != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: widget.contentBuilder!(context, _pointer),
      );
    }
    if (widget.child != null) {
      return Padding(padding: const EdgeInsets.all(28), child: widget.child!);
    }
    return const _DefaultCardContent();
  }

  Widget _buildBorder() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ?? Colors.white.withOpacity(0.12),
            width: widget.borderWidth,
          ),
        ),
      ),
    );
  }
}

/// The default demo face shown when neither [Interactive3DCard.child] nor
/// [Interactive3DCard.contentBuilder] is provided. Preserves the original
/// widget's out-of-the-box look exactly.
class _DefaultCardContent extends StatelessWidget {
  const _DefaultCardContent();

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.55)),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.arrow_outward_rounded, color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo entry point — safe to delete if you're only copying the widget above
// into an existing app. Run this file directly to see the card in action.
// ---------------------------------------------------------------------------

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