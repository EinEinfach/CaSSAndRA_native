import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'dart:ui';

import 'package:cassandra_native/theme/theme_provider.dart';
//import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/pages/servers_page.dart';
//import 'package:cassandra_native/pages/home_page.dart';
//import 'package:cassandra_native/pages/settings_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        // ChangeNotifierProvider(
        //   create: (context) => Servers(),
        // ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // scrollBehavior: const MaterialScrollBehavior().copyWith(
      //   dragDevices: {PointerDeviceKind.mouse},
      // ),
      title: 'CaSSAndRA native',
      home: const ServersPage(),
      // initialRoute: '/servers',
      // routes: {
      //   '/servers': (context) => const ServersPage(),
      //   '/home': (context) => const HomePage(),
      //   '/settings': (context) => const SettingsPage(),
      // },
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
