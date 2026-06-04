import 'package:flutter/material.dart';

class DrinkPlaceholder extends StatelessWidget {
  final double size;
  final Color? color;

  const DrinkPlaceholder({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = color ?? const Color(0xFF7000FF).withOpacity(0.4);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7000FF).withOpacity(0.15),
            const Color(0xFF00F0FF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_bar_outlined,
          color: iconColor,
          size: size,
        ),
      ),
    );
  }
}
