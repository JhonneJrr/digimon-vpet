import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'state/background.dart';
import 'ui/home_screen.dart';

const String careCheckTaskName = 'careCheck';
const String careCheckUniqueName = 'care-check';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    careCheckUniqueName,
    careCheckTaskName,
    frequency: const Duration(minutes: 15), // Android floor is 15 minutes.
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    ),
  );
}
