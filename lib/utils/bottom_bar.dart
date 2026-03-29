import 'package:flutter/material.dart';

class StickyBottomBar extends StatelessWidget {
  final Widget? left;
  final Widget? right;

  final String? text;
  final String? buttonText;
  final VoidCallback? onPressed;

  const StickyBottomBar({
    super.key,
    this.left,
    this.right,
    this.text,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget leftWidget = left ??
        (text != null
            ? Text(
                text!,
                style: theme.textTheme.bodyMedium,
              )
            : const SizedBox());

    Widget rightWidget = right ??
        (buttonText != null
            ? ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText!),
              )
            : const SizedBox());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: leftWidget),
            const SizedBox(width: 12),
            rightWidget,
          ],
        ),
      ),
    );
  }
}