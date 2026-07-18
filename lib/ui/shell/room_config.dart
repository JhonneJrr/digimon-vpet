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

/// The doors shown in the menu. Order = display order.
const List<RoomConfig> kRooms = [
  RoomConfig(title: 'Treino', backgroundAsset: 'assets/game/backgrounds/room_training.png'),
  RoomConfig(title: 'Batalha', backgroundAsset: 'assets/game/backgrounds/room_battle.png'),
  RoomConfig(title: 'Mapa', backgroundAsset: 'assets/game/backgrounds/room_map.png'),
  RoomConfig(title: 'Loja', backgroundAsset: 'assets/game/backgrounds/room_shop.png'),
  RoomConfig(title: 'Evo / Bios', backgroundAsset: 'assets/game/backgrounds/room_evo.png'),
];
