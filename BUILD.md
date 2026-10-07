# Houston BBQ Guide — build & ship

Official companion app to **houbbqguide.com** and the **Houston BBQ Festival**.
SwiftUI + XcodeGen. Data comes from `HoustonBBQGuide/Resources/Joints.json`
(bundled seed) with an optional remote refresh from GitHub Pages.

- Bundle ID: `com.compofelice.HoustonBBQGuide` (registered, resource `SUVF8ABAUU`)
- Team: `7H5T5AR2X5`  ·  Version `1.0` build `1`  ·  iOS 17+, iPhone

---

## 1. Create the app record in App Store Connect  (one-time, ~2 min, web UI)

Apple's API does not allow creating apps, so do this once by hand:

1. https://appstoreconnect.apple.com → **Apps → + → New App**
2. Platform **iOS**; Name **Houston BBQ Guide**; Primary language **English (U.S.)**
3. Bundle ID: pick **com.compofelice.HoustonBBQGuide** (already registered)
4. SKU: `houston-bbq-guide-001`; Full access
5. Create. (If the name "Houston BBQ Guide" is taken, fall back to
   "HOU BBQ Guide" and set the marketing name later.)

## 2. Push from Windows

```bash
cd /c/Users/anthony.compofelice/HoustonBBQGuide
gh repo create Compo-CF/houston-bbq-guide --private --source=. --remote=origin --push
```

(Use `--public` instead of `--private` if you want GitHub Pages data hosting on a
free account — see step 5.)

## 3. On the Mac (MacInCloud RDP): pull + generate

```bash
cd ~/houston-bbq-guide 2>/dev/null || git clone https://github.com/Compo-CF/houston-bbq-guide.git ~/houston-bbq-guide
cd ~/houston-bbq-guide && git pull
# Always generate via gen.sh (not raw xcodegen) — it stamps the git-derived
# build number. Re-run it after every pull and whenever files are added/removed.
./gen.sh
open HoustonBBQGuide.xcodeproj
```

## 4. Archive → TestFlight (Xcode)

1. In Xcode: select **Any iOS Device (arm64)** as the run destination.
2. **Product → Archive**.
3. Organizer opens → **Distribute App → App Store Connect → Upload**.
4. Automatic signing (Team `7H5T5AR2X5`). Let it upload.
5. In ASC → the app → **TestFlight**: once the build finishes processing,
   add it to Internal Testing and invite testers.

The build number is automatic: `gen.sh` stamps `CFBundleVersion` with the git
commit count (`git rev-list --count HEAD`), so every commit bumps it and it's
consistent across machines. Nothing to edit by hand — just commit and re-run
`./gen.sh` before archiving. (`CFBundleShortVersionString` / `1.0` is the public
version; bump that in `project.yml` only when you ship a new App Store version.)

## 5. (Optional) Live data updates without an app release

The app fetches `https://compo-cf.github.io/houston-bbq-guide/Joints.json` on
launch and falls back to the bundled copy. To turn it on:

1. Make the repo public (or use a Pro account), enable **Settings → Pages**,
   source = `main` branch `/docs` folder.
2. `docs/Joints.json` is already in the repo. The full data pipeline lives in
   this repo (`pipeline/build_data.py`), so refreshing from Reid's site is
   self-contained — run it anywhere with Python:
   ```bash
   python pipeline/build_data.py                 # writes joints.json in cwd
   cp joints.json docs/Joints.json
   cp joints.json HoustonBBQGuide/Resources/Joints.json   # also refresh the bundled seed
   git commit -am "Refresh joint data" && git push
   ```
   Every app picks up `docs/Joints.json` on next launch.

If you skip this, the app still ships fine on the bundled data — remote fetch
just silently no-ops.

## Data note for production
Structured hours / phone / pitmaster fields are NOT in Reid's WordPress REST
API (they're JetEngine meta). The pipeline scrapes addresses from each detail
page's map embed. For richer data, ask Reid for a JetEngine meta export and
extend `pipeline/build_data.py`.

## Suggested joints (Firestore) — LIVE as of 2026-10-07

The Guide tab has a "Know one we've missed?" card that opens a form. It writes
to a Firestore `submissions` collection with `status: "pending"`; approved tips
become real entries the normal way, through `pipeline/build_data.py` and
`docs/Joints.json`.

**The app builds and runs fine without any of this.** `FirebaseApp.configure()`
is only called when `GoogleService-Info.plist` is actually in the bundle, and
the form reports itself unavailable rather than crashing. So build 13 can ship
before Firebase exists.

### What exists

| | |
|---|---|
| Project | `houston-bbq-guide` |
| iOS app | `1:468143354893:ios:4a5f193c7489b2f242d144` |
| Bundle | `com.compofelice.HoustonBBQGuide` |
| Firestore | `(default)`, `nam5` |
| Rules | `firestore.rules`, deployed |

Console: https://console.firebase.google.com/project/houston-bbq-guide

The rules were checked against the live database, not just compiled. A
well-formed pending tip is accepted; a client-set `status: "approved"`, a
5000-character note, an undeclared extra field, a one-character name, and any
attempt to read the queue back are all refused. Re-run that check after
touching `firestore.rules` — rules take a few seconds to propagate after a
deploy, so an immediate test gives a false failure.

Redeploy rules with:

```
firebase deploy --only firestore:rules --project houston-bbq-guide
```

### App Check — DONE AND ENFORCED 2026-10-07

`GoogleService-Info.plist` IS committed, so a fresh clone builds the working
form with no manual copying.

The app now sets an App Check provider factory before `FirebaseApp.configure()`
— App Attest on device, the debug provider under `DEBUG`. **Order matters: the
factory must be set before configure(), or the first request leaves without a
token.**

Enforced on Cloud Firestore. Verified rather than assumed: the same
well-formed write that succeeded before enforcement now comes back 403 from a
plain HTTPS client holding the public key. The config in the committed plist
is no longer worth anything on its own.

Enforcing before any build shipped was safe here only because **no build in
the wild writes to Firestore** — the submission form does not exist before
commit 666d149, so there were no clients to lock out. Do not read this as a
general pattern: enforcing on a service real clients already use will reject
them until a build carrying App Check reaches everyone.

**A rejected write and a rejected rule look identical from the client** — both
are `403 PERMISSION_DENIED`, "Missing or insufficient permissions". The only
way to tell them apart is App Check -> APIs, which counts verified vs
unverified requests. Check there first when the form fails; unverified traffic
means App Check, verified-but-failing means `firestore.rules`. Unenforcing is
one click if a build turns out to be wrong.

Debug builds print an App Check debug token to the console on first launch.
Register it under **App Check → Manage debug tokens**, once per machine, or the
simulator cannot submit.

### Approving one

There is no admin screen yet, and none is needed to start: the Firebase console
bypasses the rules, so the `submissions` collection is readable there. Triage by
flipping `status` to `approved` or `rejected`, then add the joint through the
normal pipeline. If the queue gets busy enough to be annoying, that is the
moment to build a moderation view — not before.

The form already refuses obvious duplicates: it normalises the typed name
(dropping "BBQ", "Barbecue", "Co", "The" and the like) and warns when it matches
one of the joints already in the guide, so "Truth Barbeque" does not arrive as a
new tip for Truth BBQ.
