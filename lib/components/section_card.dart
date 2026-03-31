import 'package:flutter/material.dart';

/// Reusable card used to separate dashboard sections clearly.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.spacing = 12,
  });

  final Widget child;
  final String? title;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: spacing),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
