import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:cassandra_native/utils/ui_state_storage.dart';
import 'package:cassandra_native/data/app_data.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/theme/theme_provider.dart';
import 'package:cassandra_native/pages/servers_page.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

Future<void> _initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;
}

Future<void> _loadStoredUiState() async {
  user.storedUiState = await UiStateStorage.loadUiState();
}

Future setWindowSize() async {
  await DesktopWindow.setMinWindowSize(
    const Size(400, 600),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowSize();
  }
  _initPackageInfo();
  _loadStoredUiState();
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
    Provider.of<ThemeProvider>(context).initTheme();
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
