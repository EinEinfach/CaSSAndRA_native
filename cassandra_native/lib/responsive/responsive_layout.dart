import 'package:flutter/material.dart';
import 'package:cassandra_native/data/ui_state.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileMaterialApp;
  final Widget tabletTabletMaterialApp;
  final Widget desktopMaterialApp;

  const ResponsiveLayout({
    super.key,
    required this.mobileMaterialApp,
    required this.tabletTabletMaterialApp,
    required this.desktopMaterialApp,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains){
      if (constrains.maxWidth < smallWidth){
        return mobileMaterialApp;
      } else if (constrains.maxWidth < largeWidth){
        return tabletTabletMaterialApp;
      } else {
        return desktopMaterialApp;
      }
    });
  }
}
