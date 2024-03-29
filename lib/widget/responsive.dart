// import 'package:badhandatainput/util/debug.dart';
import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  static String tag = "Responsive";

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

// This size work fine on my design, maybe you need some customization depends on your design

  static const double _smallScreenMaxWidth = 700;
  static const double _largeScreenMinWidth = 1200;

  // This isMobile, isTablet, isDesktop helep us later
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _smallScreenMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _smallScreenMaxWidth &&
      MediaQuery.of(context).size.width < _largeScreenMinWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _largeScreenMinWidth;

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    // If our width is more than 1100 then we consider it a desktop
    if (_size.width >= _largeScreenMinWidth) {
      //Log.d(tag, "rendering desktop view");
      return desktop;
    }
    // If width it less then 1100 and more then 850 we consider it as tablet
    else if (_size.width >= _smallScreenMaxWidth && tablet != null) {
      //Log.d(tag, "rendering tablet view");
      return tablet!;
    }
    // Or less then that we called it mobile
    else {
      //Log.d(tag, "rendering mobile view");
      return mobile;
    }
  }
}
