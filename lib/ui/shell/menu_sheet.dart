// lib/ui/shell/menu_sheet.dart
import 'package:flutter/material.dart';
import 'room_config.dart';
import 'room_screen.dart';

/// A glass bottom sheet of doors. Tapping one closes the sheet and pushes its
/// [RoomScreen]. This is the navigation seam for future mechanics.
Future<void> showMenuSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // size to content; don't cap at ~half screen
    builder: (sheetCtx) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE6161226),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      // ListTile paints ink on its nearest Material ancestor; give it a
      // transparent one so the Container's fill doesn't swallow the splash.
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10, top: 2),
                child: Text('IR PARA',
                    style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700)),
              ),
              for (final room in kRooms)
                ListTile(
                  title: Text(room.title,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right,
                      color: Color(0x99FFFFFF)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop(); // close sheet
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => RoomScreen(config: room)));
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
