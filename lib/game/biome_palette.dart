import 'dart:ui' show Color;
import '../state/biome.dart';

/// Colors for one biome. `accent` is also the HUD's derived accent color.
/// Values are first-pass and tunable; alpha-encoded ARGB (0xAARRGGBB).
class BiomePalette {
  final Color skyTop;
  final Color skyBottom;
  final Color far; // distant hills (low-alpha over sky)
  final Color mid; // decorative blobs (low-alpha)
  final Color ground; // solid ground band
  final Color accent; // HUD accent (dots, rings, highlights)

  const BiomePalette({
    required this.skyTop,
    required this.skyBottom,
    required this.far,
    required this.mid,
    required this.ground,
    required this.accent,
  });
}

const Map<Biome, BiomePalette> _palettes = {
  Biome.nursery: BiomePalette(
    skyTop: Color(0xFF4A3B8B), skyBottom: Color(0xFFF7A8C4),
    far: Color(0x1AFFFFFF), mid: Color(0x33FFE0F0),
    ground: Color(0xFF6FC3A0), accent: Color(0xFFFF9FCE)),
  Biome.meadow: BiomePalette(
    skyTop: Color(0xFF3A2B6B), skyBottom: Color(0xFFFF8A7A),
    far: Color(0x1AFFFFFF), mid: Color(0x33FFD6A5),
    ground: Color(0xFF3FC27D), accent: Color(0xFF7BE0C9)),
  Biome.jungle: BiomePalette(
    skyTop: Color(0xFF163A2B), skyBottom: Color(0xFF57C084),
    far: Color(0x1AFFFFFF), mid: Color(0x3357C084),
    ground: Color(0xFF2A9660), accent: Color(0xFFFFC24B)),
  Biome.savanna: BiomePalette(
    skyTop: Color(0xFF6B3A16), skyBottom: Color(0xFFFFB25C),
    far: Color(0x22FFFFFF), mid: Color(0x33FFD6A5),
    ground: Color(0xFFC98A4B), accent: Color(0xFFFF7A3D)),
  Biome.chrome: BiomePalette(
    skyTop: Color(0xFF0F2027), skyBottom: Color(0xFF2C5364),
    far: Color(0x1AFFFFFF), mid: Color(0x334A6A7A),
    ground: Color(0xFF3A4A55), accent: Color(0xFF5FFBF1)),
  Biome.wasteland: BiomePalette(
    skyTop: Color(0xFF1A1420), skyBottom: Color(0xFF4A2C4A),
    far: Color(0x14FFFFFF), mid: Color(0x33553355),
    ground: Color(0xFF2A2233), accent: Color(0xFFB98CFF)),
};

BiomePalette paletteForBiome(Biome b) => _palettes[b]!;
