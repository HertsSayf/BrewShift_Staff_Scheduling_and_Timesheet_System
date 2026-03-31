import 'package:flutter/material.dart';

/// Reusable header card shown at the top of each dashboard.
class DashboardHeaderCard extends StatelessWidget {
  const DashboardHeaderCard({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            for (var i = 0; i < lines.length; i++) ...[
              Text(lines[i]),
              if (i != lines.length - 1) const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }
}
