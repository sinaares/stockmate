import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'shared/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ApiService.instance.init();
  } catch (e) {
    if (kIsWeb) debugPrint('ApiService init error (non-fatal on web): $e');
  }
  runApp(const ProviderScope(child: StockMateApp()));
}
