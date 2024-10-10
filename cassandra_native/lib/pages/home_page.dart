import 'package:cassandra_native/components/new_mow_parameters.dart';
import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:cassandra_native/utils/mow_parameters_storage.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/pages/mobile/home_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/home_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/home_page_desktop.dart';
import 'package:cassandra_native/data/app_data.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/home_page/select_tasks.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class HomePage extends StatefulWidget {
  final Server server;
  const HomePage({super.key, required this.server});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  void openTasksOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text(
          'Tasks',
          style: TextStyle(fontSize: 14),
        ),
        content: SelectTasks(
          server: widget.server,
        ),
      ),
    );
  }

  void setMowParameters(MowParameters mowParameters) {
    user.currentMowParameters = mowParameters;
    MowParametersStorage.saveMowParameters(mowParameters);
  }

  void openMowParametersOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text(
          'Mow parameters',
          style: TextStyle(fontSize: 14),
        ),
        content: NewMowParameters(
          onSetMowParameters: setMowParameters,
          mowParameters: user.currentMowParameters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (constrains.maxWidth < smallWidth) {
        return HomePageMobile(
          server: widget.server,
          onOpenTasksOverlay: openTasksOverlay,
          openMowParametersOverlay: openMowParametersOverlay,
        );
        //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return HomePageTablet(
          server: widget.server,
          onOpenTasksOverlay: openTasksOverlay,
          openMowParametersOverlay: openMowParametersOverlay,
        );
        //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else {
        return HomePageDesktop(
          server: widget.server,
          onOpenTasksOverlay: openTasksOverlay,
          openMowParametersOverlay: openMowParametersOverlay,
        );
      }
    });
  }
}
