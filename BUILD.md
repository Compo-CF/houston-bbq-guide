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
