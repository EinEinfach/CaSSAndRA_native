import 'package:cassandra_native/responsive/desktop_material_app.dart';
import 'package:cassandra_native/responsive/mobile_material_app.dart';
import 'package:cassandra_native/responsive/responsive_layout.dart';
import 'package:cassandra_native/responsive/tablet_material_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/theme/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider(),)
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileMaterialApp: MobileMaterialApp(), 
      tabletTabletMaterialApp: TabletMaterialApp(), 
      desktopMaterialApp: DesktopMaterialApp(),);
  }
}
