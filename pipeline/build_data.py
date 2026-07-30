#!/usr/bin/env python3
"""HOU BBQ Guide -> joints.json pipeline.
Pulls the bbq-joints custom post type from the WordPress REST API, decodes all
JetEngine taxonomies to human names, scrapes each detail page for address /
website / press links, geocodes the address, and emits a single joints.json the
app (and the mockup) consume.
"""
import json, re, sys, time, urllib.parse, urllib.request, html

BASE = "https://houbbqguide.com"
UA = {"User-Agent": "HOUBBQ-Guide-App-Builder/1.0 (hou bbq companion app)"}
TAXES = ["styles","neighborhood","days-open","building-type","accolades",
         "catering","primary-wood","primary-pit-type","meals-served","drinks","features"]

def get(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")

def get_json(url):
    return json.loads(get(url))

def clean(s):
    s = re.sub(r"<[^>]+>", " ", s or "")
    s = html.unescape(s)
    return re.sub(r"\s+", " ", s).strip()

# 1. taxonomy term maps: id -> name
print("Fetching taxonomy terms...", file=sys.stderr)
termmap = {}
tax_terms = {}
for tax in TAXES:
    terms = get_json(f"{BASE}/wp-json/wp/v2/{tax}?per_page=100&_fields=id,name")
    tax_terms[tax] = [t["name"] for t in terms]
    for t in terms:
        termmap[(tax, t["id"])] = html.unescape(t["name"])

def names(rec, tax):
    return [termmap.get((tax, i), str(i)) for i in rec.get(tax, [])]

# 2. all joints
print("Fetching joints...", file=sys.stderr)
joints_raw = get_json(f"{BASE}/wp-json/wp/v2/bbq-joints?per_page=100&_embed=1")
print(f"  {len(joints_raw)} joints", file=sys.stderr)

def featured(rec):
    emb = rec.get("_embedded", {}).get("wp:featuredmedia", [])
    if emb and isinstance(emb, list) and emb[0].get("source_url"):
        return emb[0]["source_url"]
    return None

def scrape_detail(url):
    """Return dict with address, website, press/social links from a detail page."""
    out = {"address": None, "website": None, "phone": None, "links": {}}
    try:
        h = get(url)
    except Exception as e:
        print(f"    detail fail {url}: {e}", file=sys.stderr)
        return out
    m = re.search(r"maps\.google\.com/maps\?q=([^\"'&]+)", h)
    if m:
        out["address"] = urllib.parse.unquote(m.group(1)).replace("+", " ").strip()
    tel = re.search(r"tel:([+0-9()\s-]{7,})", h)
    if tel:
        out["phone"] = tel.group(1).strip()
    for href in re.findall(r'href="(https?://[^"]+)"', h):
        low = href.lower()
        if any(k in low for k in ["houbbqguide","gstatic","googleapis","google.com/maps",
                "gmpg","w3.org","schema.org","/sharer","twitter.com/intent","eventbrite",
                "instagram.com/bbqguides","twitter.com/bbqguides","facebook.com/bbqguides",
                "youtube.com/channel/uckshm"]):
            continue
        if "houstonchronicle.com" in low: out["links"].setdefault("chronicle", href)
        elif "texasmonthly.com" in low: out["links"].setdefault("texasmonthly", href)
        elif "youtube.com" in low or "youtu.be" in low: out["links"].setdefault("youtube", href)
        elif "facebook.com" in low: out["links"].setdefault("facebook", href)
        elif "instagram.com" in low: out["links"].setdefault("instagram", href)
        elif "twitter.com" in low or "x.com" in low: out["links"].setdefault("twitter", href)
        else: out["links"].setdefault("website", href); out["website"] = out["website"] or href
    return out

GEO = {}
def _nominatim(q):
    try:
        data = get_json(
            f"https://nominatim.openstreetmap.org/search?q={urllib.parse.quote(q)}&format=json&limit=1")
        time.sleep(1.1)  # nominatim politeness
        if data:
            return (float(data[0]["lat"]), float(data[0]["lon"]))
    except Exception as e:
        print(f"    geocode fail {q}: {e}", file=sys.stderr)
    return None

def _simplify(a):
    """Strip suite/building/unit noise that trips up the geocoder."""
    a = re.sub(r"(Suite|Ste|Bldg|Unit|#)\s*[#\w-]*", "", a, flags=re.I)
    a = re.sub(r"^\s*\d+,\s*", "", a)          # leading "3, "
    return re.sub(r"\s*,\s*,", ",", re.sub(r"\s+", " ", a)).strip(" ,")

def geocode(addr):
    """Full address → simplified address → ZIP fallback, so every joint resolves."""
    if not addr: return (None, None)
    if addr in GEO: return GEO[addr]
    result = _nominatim(addr) or _nominatim(_simplify(addr))
    if not result:
        m = re.search(r"\b(7\d{4})\b", addr)   # Houston-area ZIP
        if m:
            result = _nominatim(f"{m.group(1)}, USA")
    GEO[addr] = result or (None, None)
    return GEO[addr]

joints = []
for i, rec in enumerate(joints_raw, 1):
    name = clean(rec["title"]["rendered"])
    print(f"  [{i}/{len(joints_raw)}] {name}", file=sys.stderr)
    det = scrape_detail(rec["link"])
    lat, lng = geocode(det["address"])
    joints.append({
        "id": rec["id"],
        "slug": rec["slug"],
        "name": name,
        "url": rec["link"],
        "description": clean(rec["content"]["rendered"]),
        "excerpt": clean(rec.get("excerpt", {}).get("rendered", "")),
        "image": featured(rec),
        "address": det["address"],
        "lat": lat, "lng": lng,
        "phone": det["phone"],
        "website": det["website"],
        "links": det["links"],
        "styles": names(rec, "styles"),
        "neighborhood": names(rec, "neighborhood"),
        "daysOpen": names(rec, "days-open"),
        "buildingType": names(rec, "building-type"),
        "accolades": names(rec, "accolades"),
        "catering": names(rec, "catering"),
        "primaryWood": names(rec, "primary-wood"),
        "primaryPitType": names(rec, "primary-pit-type"),
        "mealsServed": names(rec, "meals-served"),
        "drinks": names(rec, "drinks"),
        "features": names(rec, "features"),
    })

out = {
    "source": "houbbqguide.com",
    "count": len(joints),
    "taxonomies": tax_terms,
    "joints": joints,
}
with open("joints.json", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
geocoded = sum(1 for j in joints if j["lat"])
print(f"DONE: {len(joints)} joints, {geocoded} geocoded -> joints.json", file=sys.stderr)
