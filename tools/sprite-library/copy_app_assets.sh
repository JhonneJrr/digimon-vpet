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
  [room_database]=BG_Bios_0
)
for name in "${!MAP[@]}"; do cp "$SRC/${MAP[$name]}.png" "$DST/$name.png"; done
echo "copied ${#MAP[@]} backgrounds to $DST"
ls -1 "$DST"

# --- HUD menu-button icons: real spr_MainButtons_ENG frames 0..5 (DigiVice,
#     Shop, Training, Evolution, Database, Battle). Frame 6 (Battle Items) is
#     battle-context only and not shown on home. ---
UISRC="/c/Users/felip/Documents/DigitalTamers02_extracted/organized/ui"
BTNDST="/c/Users/felip/Documents/digimon/assets/game/ui/menu_buttons"
mkdir -p "$BTNDST"
for i in 0 1 2 3 4 5; do cp "$UISRC/spr_MainButtons_ENG_$i.png" "$BTNDST/btn_$i.png"; done

# --- Care-action icons (radial menu): meat, poop, the Bandage item, a ball. ---
ORG="/c/Users/felip/Documents/DigitalTamers02_extracted/organized"
CAREDST="/c/Users/felip/Documents/digimon/assets/game/ui/care"
mkdir -p "$CAREDST"
cp "$ORG/items/spr_Meat_0.png"   "$CAREDST/feed.png"
cp "$ORG/items/spr_poop_0.png"   "$CAREDST/clean.png"
cp "$ORG/items/spr_Items_3.png"  "$CAREDST/medicine.png"
cp "$ORG/effects/spr_Ball_0.png" "$CAREDST/play.png"

echo "copied 6 menu buttons to $BTNDST and 4 care icons to $CAREDST"

# --- Need indicators (pop-ups over the Digimon, Reborn 2 style). Mapping from
#     obj_DigiWorld_HUD_Draw GML: care_mini 0=hunger(fome), 2=sick(doente);
#     poop=mess; BlackHeart=bad mood/unhappy. ---
NEEDDST="/c/Users/felip/Documents/digimon/assets/game/ui/needs"
mkdir -p "$NEEDDST"
cp "$ORG/ui/spr_care_mini_icons_0.png" "$NEEDDST/hunger.png"
cp "$ORG/items/spr_poop_0.png"         "$NEEDDST/mess.png"
cp "$ORG/ui/spr_care_mini_icons_2.png" "$NEEDDST/sick.png"
cp "$ORG/effects/spr_BlackHeart_0.png" "$NEEDDST/unhappy.png"
echo "copied 4 need indicators to $NEEDDST"
