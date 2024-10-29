import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Package info
late PackageInfo packageInfo;

// App version
late String appVersion;
const String requiredServerVersion = '0.135.0';

// Temporarly data for UI
int smallWidth = 550;
int largeWidth = 1500;
int minHeight = 500;

// Scafold
final GlobalKey<ScaffoldState> scafoldKey = GlobalKey<ScaffoldState>();

