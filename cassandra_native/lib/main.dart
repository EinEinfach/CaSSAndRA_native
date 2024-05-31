import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/pages/home_page.dart';
import 'package:cassandra_native/pages/settings_page.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'CaSSAndRA native',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
      },
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
