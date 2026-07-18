// lib/ui/shell/room_config.dart
import 'package:flutter/widgets.dart';

/// One navigable room. Stubs set [comingSoon]; real screens pass [content].
class RoomConfig {
  const RoomConfig({
    required this.title,
    required this.backgroundAsset,
    this.comingSoon = true,
    this.content,
  });
  final String title;
  final String backgroundAsset;
  final bool comingSoon;
  final WidgetBuilder? content;
}

/// The six MainHUD sockets, in socket order (index N ↔ menu button btn_N).
/// DigiVice reuses the map bg as a placeholder until it gets its own art.
const List<RoomConfig> kRooms = [
  RoomConfig(title: 'DigiVice', backgroundAsset: 'assets/game/backgrounds/room_map.png'),
  RoomConfig(title: 'Loja', backgroundAsset: 'assets/game/backgrounds/room_shop.png'),
  RoomConfig(title: 'Treino', backgroundAsset: 'assets/game/backgrounds/room_training.png'),
  RoomConfig(title: 'Evo / Bios', backgroundAsset: 'assets/game/backgrounds/room_evo.png'),
  RoomConfig(title: 'Database', backgroundAsset: 'assets/game/backgrounds/room_database.png'),
  RoomConfig(title: 'Batalha', backgroundAsset: 'assets/game/backgrounds/room_battle.png'),
];
