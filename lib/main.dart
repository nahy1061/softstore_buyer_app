import 'dart:io';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/network/dio_client.dart';
import 'core/network/http_overrides.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  HttpOverrides.global = SoftStoreHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize core services
  await DioClient().init();
  await LocalStorageService().init();
  await HiveService.init();
  runApp(const SoftstoreBuyerApp());
}
