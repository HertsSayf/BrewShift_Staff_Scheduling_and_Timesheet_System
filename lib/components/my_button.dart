import 'package:flutter/material.dart';

/// Shared button used across the prototype for a consistent look.
class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );

    if (isOutlined) {
      return icon == null
          ? OutlinedButton(
              onPressed: isLoading ? null : onTap,
              child: child,
            )
          : OutlinedButton.icon(
              onPressed: isLoading ? null : onTap,
              icon: Icon(icon),
              label: child,
            );
    }

    return icon == null
        ? FilledButton(
            onPressed: isLoading ? null : onTap,
            child: child,
          )
        : FilledButton.icon(
            onPressed: isLoading ? null : onTap,
            icon: Icon(icon),
            label: child,
          );
  }
}
