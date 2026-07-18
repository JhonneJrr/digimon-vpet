#!/usr/bin/env bash
# Copies the selected real backgrounds from the organized/ library into the app's
# committed assets. Source is git-ignored (IP); only this subset ships in the APK.
set -euo pipefail
SRC="/c/Users/felip/Documents/DigitalTamers02_extracted/organized/backgrounds"
DST="/c/Users/felip/Documents/digimon/assets/game/backgrounds"
mkdir -p "$DST"
declare -A MAP=(
  [biome_nursery]=bg_AgumonHouse_0
  [biome_meadow]=bg_Btl_Dina_Plains_0
  [biome_jungle]=bg_Btl_Boot_Jungle_0
  [biome_savanna]=bg_Btl_Drive_Savanna_0
  [biome_chrome]=bg_Btl_Chrome_Mines_0
  [biome_wasteland]=bg_Btl_Magma_Mountain_0
  [room_training]=BG_TrainingRoom_0
  [room_battle]=bg_Btl_Magma_Mountain_0
  [room_map]=BG_SelectMap_0
  [room_shop]=BG_Loja_0
  [room_evo]=BG_EvoRoom_0
)
for name in "${!MAP[@]}"; do cp "$SRC/${MAP[$name]}.png" "$DST/$name.png"; done
echo "copied ${#MAP[@]} backgrounds to $DST"
ls -1 "$DST"
