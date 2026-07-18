import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'state/background.dart';
import 'ui/home_screen.dart';

const String careCheckTaskName = 'careCheck';
const String careCheckUniqueName = 'care-check';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The game is designed landscape (the real maps + MainHUD are 538x300).
  await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    careCheckUniqueName,
    careCheckTaskName,
    frequency: const Duration(minutes: 15), // Android floor is 15 minutes.
    // Keep the already-scheduled task across cold starts so opening the app
    // often doesn't perpetually reset the timer and starve the reminder.
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    ),
  );
}
