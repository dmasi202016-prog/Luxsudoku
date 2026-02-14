import 'package:flutter/material.dart';

typedef ResponsiveBuilder = Widget Function(
  BuildContext context,
  Size size,
);

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.builder,
  });

  final ResponsiveBuilder builder;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return builder(context, size);
  }
}
