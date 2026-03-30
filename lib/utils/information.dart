import 'package:flutter/material.dart';

enum IconTextLayout {
  horizontal,
  vertical,
}

class ChatInfoWidget extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool isCompact;

  const ChatInfoWidget({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: isCompact 
          ? const EdgeInsets.symmetric(vertical: 2, horizontal: 12)
          : padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: isCompact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey[100],
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor ?? Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IconText extends StatelessWidget {
  final Widget? leading;
  final String text;
  final Color? iconColor;
  final Color textColor;
  final double? iconSize;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final MainAxisAlignment mainAxisAlignment;
  final bool showIcon;
  final int? maxLines;
  final IconTextLayout layout;

  const IconText({
    super.key,
    this.leading,
    required this.text,
    this.iconColor,
    required this.textColor,
    this.iconSize,
    this.fontSize,
    this.padding,
    this.margin,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.showIcon = true,
    this.maxLines,
    this.layout = IconTextLayout.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? iconWidget = showIcon
        ? (leading ??
            Icon(
              Icons.help_outline,
              color: iconColor ?? Colors.grey,
              size: iconSize ?? 18,
            ))
        : null;

    final textWidget = Expanded(
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.visible,
        softWrap: true,
        textAlign: layout == IconTextLayout.vertical
            ? TextAlign.center
            : TextAlign.start,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize ?? 14,
        ),
      ),
    );

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(4),
      child: layout == IconTextLayout.horizontal
          ? Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?iconWidget,
                if (iconWidget != null) const SizedBox(width: 8),
                textWidget,
              ],
            )
          : Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ?iconWidget,
                if (iconWidget != null) const SizedBox(height: 4),
                textWidget,
              ],
            ),
    );
  }
}

class IconTextVariants {
  static Widget success({
    required String text,
    IconData icon = Icons.check_circle,
    IconTextLayout layout = IconTextLayout.horizontal,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool showIcon = true,
    int? maxLines,
  }) {
    return IconText(
      leading: Icon(Icons.check_circle, color: Colors.green),
      text: text,
      layout: layout,
      iconColor: Colors.green,
      textColor: Colors.green.shade700,
      iconSize: iconSize,
      fontSize: fontSize,
      padding: padding,
      margin: margin,
      mainAxisAlignment: mainAxisAlignment,
      showIcon: showIcon,
      maxLines: maxLines,
    );
  }

  static Widget error({
    required String text,
    IconData icon = Icons.error,
    IconTextLayout layout = IconTextLayout.horizontal,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool showIcon = true,
    int? maxLines,
  }) {
    return IconText(
      leading: Icon(Icons.error, color: Colors.red),
      text: text,
      layout: layout,
      iconColor: Colors.red,
      textColor: Colors.red.shade700,
      iconSize: iconSize,
      fontSize: fontSize,
      padding: padding,
      margin: margin,
      mainAxisAlignment: mainAxisAlignment,
      showIcon: showIcon,
      maxLines: maxLines,
    );
  }

  static Widget warning({
    required String text,
    IconData icon = Icons.warning,
    IconTextLayout layout = IconTextLayout.horizontal,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool showIcon = true,
    int? maxLines,
  }) {
    return IconText(
      leading: Icon(Icons.warning, color: Colors.orange),
      text: text,
      layout: layout,
      iconColor: Colors.orange,
      textColor: Colors.orange.shade700,
      iconSize: iconSize,
      fontSize: fontSize,
      padding: padding,
      margin: margin,
      mainAxisAlignment: mainAxisAlignment,
      showIcon: showIcon,
      maxLines: maxLines,
    );
  }

  static Widget info({
    required String text,
    IconData icon = Icons.info,
    IconTextLayout layout = IconTextLayout.horizontal,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool showIcon = true,
    int? maxLines,
  }) {
    return IconText(
      leading: Icon(Icons.info, color: Colors.blue),
      text: text,
      layout: layout,
      iconColor: Colors.blue,
      textColor: Colors.blue.shade700,
      iconSize: iconSize,
      fontSize: fontSize,
      padding: padding,
      margin: margin,
      mainAxisAlignment: mainAxisAlignment,
      showIcon: showIcon,
      maxLines: maxLines,
    );
  }

  static Widget neutral({
    required String text,
    IconData icon = Icons.help_outline,
    IconTextLayout layout = IconTextLayout.horizontal,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool showIcon = true,
    int? maxLines,
  }) {
    return IconText(
      leading: Icon(icon, color: Colors.grey),
      text: text,
      layout: layout,
      iconColor: Colors.grey,
      textColor: Colors.grey.shade700,
      iconSize: iconSize,
      fontSize: fontSize,
      padding: padding,
      margin: margin,
      mainAxisAlignment: mainAxisAlignment,
      showIcon: showIcon,
      maxLines: maxLines,
    );
  }
}

class DividerText extends StatelessWidget {
  final String text;
  final double lineThickness;
  final Color lineColor;
  final double fontSize;
  final Color textColor;
  final double minSpacing;

  const DividerText({
    super.key,
    this.text = "Stay Tuned",
    this.lineThickness = 1.2,
    this.lineColor = Colors.black,
    required this.fontSize,
    this.textColor = Colors.black,
    this.minSpacing = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final int lineFlex = screenWidth >= 1200
        ? 5
        : screenWidth >= 600
            ? 3
            : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final textWidth = textPainter.width;
        final availableWidth = constraints.maxWidth;

        double spacing = (availableWidth - textWidth) * 0.05;
        spacing = spacing.clamp(minSpacing, 24.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: lineFlex,
                child: Divider(
                  color: lineColor,
                  thickness: lineThickness,
                ),
              ),
              SizedBox(width: spacing),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                flex: lineFlex,
                child: Divider(
                  color: lineColor,
                  thickness: lineThickness,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}