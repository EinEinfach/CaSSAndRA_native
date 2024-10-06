import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:cassandra_native/data/app_data.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/theme/theme_provider.dart';
import 'package:cassandra_native/pages/servers_page.dart';

Future<void> _initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
  }

Future setWindowSize() async {
  await DesktopWindow.setMinWindowSize(
    const Size(800, 600),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowSize();
  }
  _initPackageInfo();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => CassandraNative(),
        ),
        // ChangeNotifierProvider(
        //   create: (context) => Robot(),
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
