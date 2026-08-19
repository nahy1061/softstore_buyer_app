import 'dart:io';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/network/dio_client.dart';
import 'core/network/http_overrides.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    HttpOverrides.global = SoftStoreHttpOverrides();
  } catch (_) {}

  // Initialize core services safely
  try {
    await DioClient().init();
  } catch (e) {
    debugPrint('[Main] DioClient init error: $e');
  }

  try {
    await LocalStorageService().init();
  } catch (e) {
    debugPrint('[Main] LocalStorageService init error: $e');
  }

  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('[Main] HiveService init error: $e');
  }

  runApp(const SoftstoreBuyerApp());
}
