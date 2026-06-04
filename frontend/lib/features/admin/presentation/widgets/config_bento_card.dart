import 'package:flutter/material.dart';
import 'package:gestobar/core/theme/app_theme.dart';

class ConfigBentoCard extends StatelessWidget {
  final double width;
  final String title;
  final String? description;
  final IconData icon;
  final Widget child;

  const ConfigBentoCard({
    super.key,
    this.width = double.infinity,
    required this.title,
    this.description,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.liquidSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.liquidPrimary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.liquidOnSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Colors.white10),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
