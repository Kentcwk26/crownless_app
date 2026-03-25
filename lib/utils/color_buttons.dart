import 'package:flutter/material.dart';

class ElevatedButtonVariants {
  static ButtonStyle _baseStyle(Color background, Color foreground) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey;
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.all(foreground),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return background.withOpacity(0.8);
        }
        return null;
      }),
      padding: WidgetStateProperty.all(const EdgeInsets.all(16)),
    );
  }

  static Widget _build({
    required Color background,
    required Color foreground,
    required VoidCallback? onPressed,
    required Widget child,
    Widget? icon,
  }) {
    final style = _baseStyle(background, foreground);

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: child,
        style: style,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  static Widget success({
    required VoidCallback? onPressed,
    required Widget child,
    Widget? icon,
  }) =>
      _build(
        background: Colors.green,
        foreground: Colors.white,
        onPressed: onPressed,
        child: child,
        icon: icon,
      );

  static Widget warning({
    required VoidCallback? onPressed,
    required Widget child,
    Widget? icon,
  }) =>
      _build(
        background: Colors.orange,
        foreground: Colors.white,
        onPressed: onPressed,
        child: child,
        icon: icon,
      );

  static Widget danger({
    required VoidCallback? onPressed,
    required Widget child,
    Widget? icon,
  }) {
    return _build(
      background: Colors.red,
      foreground: Colors.white,
      onPressed: onPressed,
      child: child,
      icon: icon,
    );
  }

  static Widget info({
    required VoidCallback? onPressed,
    required Widget child,
    Widget? icon,
  }) =>
      _build(
        background: Colors.blue,
        foreground: Colors.white,
        onPressed: onPressed,
        child: child,
        icon: icon,
      );

  static Widget disable({
    required VoidCallback? onPressed,
    required Widget child,
    Widget? icon,
  }) =>
      _build(
        background: Colors.grey,
        foreground: Colors.white,
        onPressed: onPressed,
        child: child,
        icon: icon,
      );

  static Widget auto({
    required VoidCallback? onPressed,
    required Widget child,
    Widget? icon,
  }) =>
      _build(
        background: Colors.orange,
        foreground: Colors.black,
        onPressed: onPressed,
        child: child,
        icon: icon,
      );
}