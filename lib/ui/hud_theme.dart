// lib/ui/hud_theme.dart
import 'package:flutter/widgets.dart';
import '../state/pet.dart';
import '../state/biome.dart';
import '../game/biome_palette.dart';

/// HUD accent color, derived from the pet's current biome (Plan 1 default;
/// Plan 2 adds an optional player override).
Color hudAccentFor(Pet pet) => paletteForBiome(biomeForStage(pet.stage)).accent;

const double kGlassBlur = 10.0;
const Color kGlassFill = Color(0x24FFFFFF); // ~14% white
const Color kGlassBorder = Color(0x66FFFFFF);
