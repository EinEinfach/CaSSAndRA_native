import 'package:flutter/material.dart';

import 'package:cassandra_native/pages/mobile/home_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/home_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/home_page_desktop.dart';
import 'package:cassandra_native/data/ui_state.dart';
import 'package:cassandra_native/models/server.dart';

class HomePage extends StatelessWidget{
  final Server server;

  const HomePage({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (constrains.maxWidth < smallWidth) {
        return HomePageMobile(server: server);
        //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return HomePageTablet(server: server);
        //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else {
        return HomePageDesktop(server: server);
      }
    });
  }
}
