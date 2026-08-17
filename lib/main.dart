import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient().init();
  runApp(const SoftstoreBuyerApp());
}
