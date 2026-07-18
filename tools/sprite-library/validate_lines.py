import json, re, os
BASE=r"C:\Users\felip\Documents\DigitalTamers02_extracted"
META=os.path.join(BASE,"meta")
E=json.load(open("plan/edges.json",encoding="utf-8"))
CL=json.load(open("curated_lines.json",encoding="utf-8"))

# forward edges (evo + jogress)
import collections
fwd=set(); adj=collections.defaultdict(set)
for s,d,nm,st,k in E["evo"]: fwd.add((s,d)); adj[s].add(d)
for p,r,nm,st in E["jogress"]: fwd.add((p,r)); adj[p].add(r)
def reaches(a,b):
    q=collections.deque([a]); seen={a}
    while q:
        x=q.popleft()
        if x==b: return True
        for y in adj[x]:
            if y not in seen: seen.add(y); q.append(y)
    return b==a

# names
name={}
for line in open(os.path.join(META,"digimon-id-map.md"),encoding="utf-8"):
    m=re.match(r"^\|\s*d(\d+)\s*\|\s*(.+?)\s*\|\s*(high|med|low)\s*\|",line)
    if m: name[int(m.group(1))]=m.group(2).strip()
def nm(i): return name.get(i,f"d{i}")

# ids that have art (d-sprites or b-sprites)
art=set()
for line in open(os.path.join(META,"sprite_index.tsv"),encoding="utf-8"):
    mm=re.match(r"^([db])(\d+)_",line)
    if mm: art.add(int(mm.group(2)))

ok=True
for lname,spec in CL.items():
    print(f"\n== {lname} ==")
    miss_art=[i for i in spec["members"] if i not in art]
    print("  members: "+", ".join(f"{nm(i)}(d{i})" for i in spec["members"]))
    if miss_art:
        ok=False; print("  !! NO ART: "+", ".join(f"{nm(i)}(d{i})" for i in miss_art))
    for a,b in spec["spine"]:
        direct=(a,b) in fwd
        reach=reaches(a,b)
        mark="OK(direct)" if direct else ("OK(warp/multi)" if reach else "UNREACHABLE")
        if not reach: ok=False
        print(f"    edge {nm(a)}->{nm(b)}: {mark}")
print("\nALL GOOD" if ok else "\nISSUES FOUND (fix curated_lines.json)")
