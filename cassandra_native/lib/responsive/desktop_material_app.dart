import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/theme/theme_provider.dart';
import 'package:cassandra_native/pages/desktop/home_page.dart';
import 'package:cassandra_native/pages/mobile/settings_page.dart';
import 'package:cassandra_native/data/ui_state.dart';

class DesktopMaterialApp extends StatelessWidget {
  const DesktopMaterialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CaSSAndRA native',
      initialRoute: currentPage,
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
      },
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}