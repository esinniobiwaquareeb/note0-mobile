import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await ScreenProtector.preventScreenshotOn();
  runApp(const ProviderScope(child: App()));
}
