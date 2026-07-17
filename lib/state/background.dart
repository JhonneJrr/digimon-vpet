// lib/state/background.dart
import 'package:workmanager/workmanager.dart';
import 'notifications.dart';
import 'pet_logic.dart';
import 'pet_repository.dart';

/// Entry point invoked by the OS (via workmanager) on a background isolate
/// when the periodic "care check" task fires. Must stay a top-level function
/// annotated with `vm:entry-point` so it survives tree-shaking and is
/// resolvable from native code.
///
/// Reads the persisted pet and only nudges when it actually needs attention,
/// so a well-tended (or actively-played) pet never nags. Per spec §10 this is
/// READ-ONLY: it applies elapsed time in memory to judge the current state but
/// never saves, so it can't corrupt or race the foreground game's state.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final pet = await PrefsPetRepository().load();
    if (pet == null) return true; // nothing hatched yet — nothing to remind about
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = PetLogic.applyElapsed(pet, now); // in-memory only, not saved
    if (PetLogic.needsAttention(current)) {
      final notifications = Notifications();
      await notifications.init();
      await notifications.scheduleNeedsYou();
    }
    return true;
  });
}
