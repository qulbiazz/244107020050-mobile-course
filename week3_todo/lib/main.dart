import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/stats_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StatsApp(),
    ),
  );
}

class StatsApp extends StatelessWidget {
  const StatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stats Riverpod',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const StatsPage(),
    );
  }
}