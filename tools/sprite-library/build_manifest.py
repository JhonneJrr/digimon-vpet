#!/usr/bin/env python3
"""Build the organized/ sprite-library plan (hybrid name + curated lines).

Deterministic. Emits into OUT:
  hardlinks.tsv  source_abs <TAB> target_rel   (canonical home for every frame)
  junctions.tsv  link_rel   <TAB> target_rel   (curated line member -> digimon/<slug>)
  docs/README.md, docs/LINES.md, docs/lines/<line>/_line.md
  line_data.json, coverage.json, spr_residual.txt
Report-only: touches nothing under organized/. Materialization is separate.
"""
import os, re, sys, json, collections

BASE = r"C:\Users\felip\Documents\DigitalTamers02_extracted"
SPRITES = os.path.join(BASE, "sprites")
META = os.path.join(BASE, "meta")
CE = os.path.join(META, "dump", "CodeEntries")
IDMAP = os.path.join(META, "digimon-id-map.md")
EVO = os.path.join(CE, "gml_Object_obj_EvoCards_Step_0.gml")
JOG = os.path.join(CE, "gml_Object_obj_JogressOptions_Step_0.gml")
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
CURATED = json.load(open(os.path.join(os.path.dirname(__file__) or ".", "curated_lines.json"), encoding="utf-8"))

STAGE_NAME = {0:"baby",1:"baby",2:"in-training",3:"rookie",4:"champion",
              5:"ultimate",6:"mega",7:"armor",8:"extra",9:"extra",10:"extra"}

def slug(name):
    s = name.strip().lower().replace("&"," and ")
    s = re.sub(r"[^a-z0-9]+","-",s)
    return s.strip("-") or "unnamed"

# 1. id-map
idmap={};
for line in open(IDMAP,encoding="utf-8"):
    m=re.match(r"^\|\s*d(\d+)\s*\|\s*(.+?)\s*\|\s*(high|med|low)\s*\|",line)
    if m: idmap[int(m.group(1))]=m.group(2).strip()

# 2. real sprite inventory
sprites=collections.defaultdict(list); n_files=0
for e in os.scandir(SPRITES):
    if not e.is_file() or not e.name.endswith(".png"): continue
    n_files+=1
    m=re.match(r"^(.*)_(\d+)\.png$",e.name)
    sprites[m.group(1) if m else "__NOFRAME__"].append(e.name)

d_re=re.compile(r"^d(\d+)_(.+)$"); b_re=re.compile(r"^b(\d+)_(.+)$"); bg_re=re.compile(r"^(bg_|BG)")
d_sprites={}; b_sprites={}; spr_names={}; bg_names={}; other={}
for name,files in sprites.items():
    if name=="__NOFRAME__": continue
    md=d_re.match(name); mb=b_re.match(name)
    if md: d_sprites.setdefault(int(md.group(1)),{})[md.group(2)]=files
    elif mb: b_sprites.setdefault(int(mb.group(1)),{})[mb.group(2)]=files
    elif name.startswith("spr_"): spr_names[name]=files
    elif bg_re.match(name): bg_names[name]=files
    else: other[name]=files

# 3. evolution graph
edges=[]; stage={}; name_from_evo={}
def pstage(t):
    m=re.search(r"Value_(\d+)",t); return int(m.group(1)) if m else None
cur=None
for line in open(EVO,encoding="utf-8"):
    ms=re.search(r"global\.digi\[DA\]\s*==\s*(\d+)",line)
    if ms: cur=int(ms.group(1)); continue
    me=re.search(r'evo_card_att\(\s*"([^"]*)"\s*,\s*(\d+)\s*,\s*d\d+_idle\s*,\s*[^,]+,\s*(UnknownEnum\.Value_\d+)',line)
    if me and cur is not None:
        dn=me.group(1); dd=int(me.group(2)); st=pstage(me.group(3))
        edges.append((cur,dd,dn,st));
        if st is not None: stage[dd]=st
        name_from_evo[dd]=dn
curp=None
for line in open(JOG,encoding="utf-8"):
    mp=re.search(r"global\.JogressMatSelected\[0\]\s*==\s*(-?\d+)",line)
    if mp: curp=int(mp.group(1)); continue
    me=re.search(r'evo_card_att\(\s*"([^"]*)"\s*,\s*(\d+)\s*,\s*d\d+_idle\s*,\s*[^,]+,\s*(UnknownEnum\.Value_\d+)',line)
    if me and curp is not None and curp>=0:
        rn=me.group(1); rd=int(me.group(2)); st=pstage(me.group(3))
        edges.append((curp,rd,rn,st))
        if st is not None and rd not in stage: stage[rd]=st
        name_from_evo.setdefault(rd,rn)

def rname(did): return idmap.get(did) or name_from_evo.get(did) or f"d{did}"

# 4. canonical slug per id (lowest id keeps clean slug on collision)
all_ids=set(d_sprites)|set(b_sprites)|set(stage)|{s for s,_,_,_ in edges}|{d for _,d,_,_ in edges}
by_slug=collections.defaultdict(list)
for did in all_ids: by_slug[slug(rname(did))].append(did)
slug_by_id={}
for base,ids in by_slug.items():
    for i,did in enumerate(sorted(ids)):
        slug_by_id[did]= base if i==0 else f"{base}-d{did}"

# 5. non-digimon heuristic classification
def classify_spr(name):
    n=name.lower()
    ui=["btn","button","_yes","_no","confirm","arrow","slider","checkbox","toggle","tab_","icon","hud",
        "bar_","gauge","meter","frame_","window","panel","cursor","menu","popup","shop","seller","sign",
        "keyboard","teclado","plugs","trainingbar","achievement","_ui","letter","number","font","digitnum",
        "vendor_ui","store","emoji","stamp","dialog"]
    eff=["fx","effect","_hit","slash","explos","impact","flash","spark","smoke","aura","beam","fire","flame",
         "wave","shock","burst","crest","exp","ball","bullet","ice","power","spirit","laser","wind","thorn",
         "breath","dot","barr","galaxy","heart","shine","glow","dust","cloud_fx","boom","ray","bolt",
         "groundshake","musicatk","charge","poison","heal_fx","buff","debuff","cone","projectile"]
    bg=["deco","placeable","scenery","tree","rock","house","building","mural","backdrop","dungeom","dungeon",
        "city","wall","cacto","escombros","coloseum","galaxy0","minecart","solid_block","ruin","plant","flower",
        "rafflesi","machine","gatheringpoint","tile","ground","bg_","floor","bridge","fence","door","chest",
        "grass","water_","lava","platform","pillar","statue","lamp","barrel","crate","sign_post"]
    itm=["item","chip","medal","food","meat","potion","disk","drive","cake","nut","egg","poop","gift_box",
         "special_ball","fruit","berry","card_","ticket","key_item","consumable","ration"]
    npc=["npc","owner","clerk","tamer","human","_boy","_girl","_man","_woman","hina","exoticseller"]
    for k in npc:
        if k in n: return "npcs"
    for k in ui:
        if k in n: return "ui"
    for k in itm:
        if k in n: return "items"
    for k in eff:
        if k in n: return "effects"
    for k in bg:
        if k in n: return "backgrounds"
    return None

spr_class={}; spr_residual=[]
for nm in spr_names:
    c=classify_spr(nm)
    (spr_class.__setitem__(nm,c) if c else spr_residual.append(nm))

# 6. hardlink plan (canonical homes)
hardlinks=[]
def add(files,td):
    for fn in files: hardlinks.append((os.path.join(SPRITES,fn), td+"/"+fn))
digimon_ids=set()
for did,poses in d_sprites.items():
    ds=slug_by_id.get(did,f"d{did}"); digimon_ids.add(did)
    for pose,files in poses.items(): add(files,f"digimon/{ds}/{pose}")
for bid,poses in b_sprites.items():
    ds=slug_by_id.get(bid,f"d{bid}"); digimon_ids.add(bid)
    for pose,files in poses.items(): add(files,f"digimon/{ds}/battle/{pose}")
for nm,files in bg_names.items(): add(files,"backgrounds")
for nm,files in spr_names.items(): add(files, spr_class.get(nm,"misc"))
for nm,files in other.items(): add(files,"misc")

# 7. curated line junctions + validation
junctions=[]; line_report={}
adj=collections.defaultdict(set)
for s,d,_,_ in edges: adj[s].add(d)
def reaches(a,b):
    q=collections.deque([a]); seen={a}
    while q:
        x=q.popleft()
        if x==b: return True
        for y in adj[x]:
            if y not in seen: seen.add(y); q.append(y)
    return a==b
for lname,spec in CURATED.items():
    members=spec["members"]; missing=[m for m in members if m not in digimon_ids]
    for m in members:
        if m in digimon_ids:
            ms=slug_by_id.get(m,f"d{m}")
            junctions.append((f"lines/{lname}/{ms}", f"digimon/{ms}"))
    line_report[lname]={"members":members,"missing_art":missing,
        "spine_ok":all(reaches(a,b) for a,b in spec["spine"])}

# 8. write plan
os.makedirs(OUT,exist_ok=True)
with open(os.path.join(OUT,"hardlinks.tsv"),"w",encoding="utf-8") as f:
    for s,t in hardlinks: f.write(s+"\t"+t+"\n")
with open(os.path.join(OUT,"junctions.tsv"),"w",encoding="utf-8") as f:
    for l,t in junctions: f.write(l+"\t"+t+"\n")
with open(os.path.join(OUT,"spr_residual.txt"),"w",encoding="utf-8") as f:
    f.write("\n".join(sorted(spr_residual)))

# 9. docs
DOCS=os.path.join(OUT,"docs"); os.makedirs(os.path.join(DOCS,"lines"),exist_ok=True)
def stg(i): return STAGE_NAME.get(stage.get(i),"baby/?")
with open(os.path.join(DOCS,"README.md"),"w",encoding="utf-8") as f:
    f.write(f"""# organized/ — Digital Tamers Reborn sprite library

Curated from the raw `../sprites/` dump ({n_files} frames). **Read-only reference** — the
files here are hardlinks/junctions into `../sprites/`; editing one edits the source. Do game
edits in the Flutter `assets/` tree, never here. Regenerate anytime from `build_manifest.py`.

## Layout
- `digimon/<name>/` — every Digimon, once. `<pose>/` = overworld/vpet frames; `battle/<pose>/`
  = battle frames (from the `b###` set). Say a name -> open its folder.
- `lines/<rookie>/<member>/` — hand-curated evolution families (junctions into `digimon/`).
  Each line carries its **canonical predisposed baby chain** (e.g. agumon = Botamon->Koromon->Agumon).
  See `LINES.md`.
- `ui/ effects/ backgrounds/ items/ npcs/ misc/` — non-Digimon art (heuristic-sorted; `misc/`
  = unclassified, logged in `../plan/spr_residual.txt`).

## Why curated lines (not automatic)
The game's evolution data is one dense 522-node mesh (shared babies + shared megas connect nearly
everything), so "everything reachable from a rookie" is ~120 members and meaningless. Lines here
are hand-authored spines, each edge verified reachable in the game's own evolution graph.
""")
# LINES.md + per-line
lines_md=["# Curated evolution lines\n"]
for lname,spec in CURATED.items():
    rep=line_report[lname]
    mem=spec["members"]
    lines_md.append(f"- **{lname}** — "+ " -> ".join(f"{rname(m)}" for m in mem))
    with open(os.path.join(DOCS,"lines",lname+"__line.md"),"w",encoding="utf-8") as f:
        f.write(f"# {lname} line\n\nSpine (each edge reachable in-game):\n\n")
        f.write("  " + " -> ".join(f"{rname(a)}" for a,_ in spec["spine"]) + f" -> {rname(spec['spine'][-1][1])}\n\n")
        f.write("Members:\n\n")
        for m in mem:
            f.write(f"- **{rname(m)}** (d{m}, {stg(m)}){'  [NO ART]' if m in rep['missing_art'] else ''}\n")
with open(os.path.join(DOCS,"LINES.md"),"w",encoding="utf-8") as f:
    f.write("\n".join(lines_md)+"\n")

# 10. coverage + report
cov={"source_frames":n_files,"hardlinks":len(hardlinks),"junctions":len(junctions),
     "digimon_folders":len(digimon_ids),"curated_lines":len(CURATED),
     "spr_classified":len(spr_class),"spr_residual":len(spr_residual),
     "spr_categories":dict(collections.Counter(spr_class.values()))}
json.dump(cov,open(os.path.join(OUT,"coverage.json"),"w"),indent=1)
json.dump({"lines":line_report},open(os.path.join(OUT,"line_report.json"),"w"),indent=1)

assert len(hardlinks)==n_files, f"hardlink count {len(hardlinks)} != source frames {n_files}"
print("=== PLAN BUILT ===")
print(json.dumps(cov,indent=1))
print("\nline validation:")
for lname,rep in line_report.items():
    print(f"  {lname}: {len(rep['members'])} members, spine_ok={rep['spine_ok']}, missing_art={rep['missing_art']}")
print("\nsample slugs:", {rname(i):slug_by_id[i] for i in [1,2,3,5,85,87,151,4,677] if i in slug_by_id})
