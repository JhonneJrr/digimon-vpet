// lib/state/background.dart
import 'package:workmanager/workmanager.dart';
import 'notifications.dart';

/// Entry point invoked by the OS (via workmanager) on a background isolate
/// when the periodic "care check" task fires. This must stay a top-level
/// function annotated with `vm:entry-point` so it survives tree-shaking and
/// is resolvable from native code.
///
/// Intentionally does NOT touch [PetRepository] or any game logic (spec
/// §10) — it only shows the same "needs you" notification that firing on
/// app-background does.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final notifications = Notifications();
    await notifications.init();
    await notifications.scheduleNeedsYou();
    return true;
  });
}
