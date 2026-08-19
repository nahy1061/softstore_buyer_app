import 'dart:io';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/network/dio_client.dart';
import 'core/network/http_overrides.dart';
import 'core/services/notification_service.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  try {
    HttpOverrides.global = SoftStoreHttpOverrides();
  } catch (_) {}

  WidgetsFlutterBinding.ensureInitialized();

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

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[Main] NotificationService init error: $e');
  }

  runApp(const SoftstoreBuyerApp());
}
