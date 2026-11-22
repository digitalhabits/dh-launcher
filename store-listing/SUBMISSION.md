# App Store submission checklist

What is ready in this folder, and what only the owner can do.

## Ready

| Item | File |
|---|---|
| Screenshots, 6.9" iPhone (1320×2868), 5 slides in the To-Do style | `screenshots/iphone-6.9/en/` (made by `scripts/store-assets.mjs`) |
| App Preview video, 6.9" iPhone (886×1920, 30 fps, 18.9 s, silent AAC) | `app-preview/iphone-6.9-en.mp4` |
| Subtitle (29/30), promotional text (163/170), keywords (98/100), description | `subtitle.txt`, `promotional_text.txt`, `keywords.txt`, `description.txt` |
| Notes for App Review | `review-notes.txt` |
| Privacy policy (draft) | `privacy-policy.md` |
| Privacy manifests (no data, no tracking, no required-reason APIs) | `Launcher/PrivacyInfo.xcprivacy`, `LauncherWidget/PrivacyInfo.xcprivacy` |
| No export-compliance question on upload | `ITSAppUsesNonExemptEncryption: false` in `project.yml` |
| Category: Productivity | `LSApplicationCategoryType` in `project.yml` |

A Release build for devices compiles without errors (`-configuration Release -sdk iphoneos`, unsigned).

## Decided and done

- Name on the App Store and on the phone: **DH Launcher**.
- Bundle ID `org.digitalhabits.launcher`, widget `.widget`, App Group `group.org.digitalhabits.launcher`, team Centre for Digital Habits CIC (`JD647S9RT6`). Xcode registered the app IDs on the first archive.
- Version 0.1, build 2. A signed Release archive builds (`scripts/upload-app-store.sh` archives and uploads).
- The GitHub repo is public, so slide 5's "source code is open" is true.

## Still to do

1. **Create the app in App Store Connect**: Apps > + > New App. Platform iOS, name "DH Launcher", language English (UK), bundle ID `org.digitalhabits.launcher`, SKU e.g. `dh-launcher`, full access.
2. **Upload the build**: `scripts/upload-app-store.sh`.
3. **Test on a real iPhone** (via TestFlight or Xcode): Phone (`mobilephone://`, not verified on the simulator), the black flash on widget taps, and the Shortcut route.
4. **Privacy policy and support URLs**: put `privacy-policy.md` on digitalhabits.org (date and contact email to fill in).
5. **Fill in the version page**: subtitle, promotional text, description, keywords (from the `.txt` files), screenshots, App Preview video, support and privacy URLs, category Productivity, the review notes (`review-notes.txt`), and the build.
6. **App Privacy**: "Data Not Collected". **Age rating**: none of the items (4+). **Price**: Free.
7. **"Inspired by Olauncher for Android"** is in the Settings footer; keep or remove before submitting.
8. **Submit for review.**

## Remake the pictures

```bash
node scripts/store-assets.mjs
```

The app pictures are in `source-pictures/` (iPhone 17 Pro simulator, black wallpaper, only DH Launcher in the dock). Take them again when the app looks different.

The video was recorded with `xcrun simctl io booted recordVideo`, then made constant 30 fps, cut and encoded with ffmpeg:

```bash
ffmpeg -i raw.mov -vf "fps=30,scale=-2:1920,pad=886:1920:(ow-iw)/2:0:black,format=yuv420p" -an cfr.mp4
ffmpeg -i cfr.mp4 -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -filter_complex "[0:v]trim=start=1.0:end=19.9,setpts=PTS-STARTPTS[v]" -map "[v]" -map 1:a -c:v libx264 -profile:v high -r 30 -pix_fmt yuv420p -c:a aac -shortest app-preview/iphone-6.9-en.mp4
```
