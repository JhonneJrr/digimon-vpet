// lib/ui/hud_theme.dart
import 'package:flutter/widgets.dart';
import '../state/biome.dart';
import '../game/biome_palette.dart';

/// HUD accent color, derived from a biome.
Color hudAccentFor(Biome biome) => paletteForBiome(biome).accent;

const double kGlassBlur = 10.0;
const Color kGlassFill = Color(0x24FFFFFF); // ~14% white
const Color kGlassBorder = Color(0x66FFFFFF);
