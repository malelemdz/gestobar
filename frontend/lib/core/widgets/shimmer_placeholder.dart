import 'package:flutter/material.dart';

class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.margin,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: const [
                Color(0xFF1E2024), // Sleek surface container color
                Color(0xFF282A2F), // Slightly lighter reflection color
                Color(0xFF1E2024),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-2.0 + _controller.value * 4.0, -0.5),
              end: Alignment(-1.0 + _controller.value * 4.0, 0.5),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.03),
              width: 1.0,
            ),
          ),
        );
      },
    );
  }
}
