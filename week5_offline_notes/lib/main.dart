import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/prefs.dart';
import 'pages/home_page.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // DATABASE WINDOWS
  // ============================================================

  if (Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS) {
    sqfliteFfiInit();

    databaseFactory =
        databaseFactoryFfi;
  }

  // ============================================================
  // SIMPAN WAKTU APLIKASI DIBUKA
  // ============================================================

  await PrefsRepository()
      .markOpenedNow();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final darkMode =
        ref.watch(darkModeProvider);

    final isDark =
        darkMode.value ?? false;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Week 5 Offline Notes',

      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: isDark
          ? ThemeMode.dark
          : ThemeMode.light,

      home: const HomePage(),
    );
  }
}