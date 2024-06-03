import 'package:cassandra_native/pages/desktop/home_page_desktop.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/pages/mobile/home_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/home_page_tablet.dart';
import 'package:cassandra_native/data/ui_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (constrains.maxWidth < smallWidth) {
        return const HomePageMobile();
        //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return const HomePageTablet();
        //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else {
        return const HomePageDesktop();
      }
    });
  }
}
