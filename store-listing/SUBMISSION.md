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

## Decisions and steps for the owner

1. **App Store name.** The listing text uses "Digital Habits: Launcher", following "Digital Habits: To-Do". The name on the phone stays "DH Launcher" (`APP_DISPLAY_NAME`). Change both if you want something else.
2. **Bundle ID, team, App Group.** In `project.yml`, set `BUNDLE_PREFIX` and `DEVELOPMENT_TEAM`. Register the app ID, the widget ID (`<prefix>.widget`) and the App Group `group.<prefix>` in the developer account. Run `xcodegen generate`.
3. **Version.** `MARKETING_VERSION` is 0.1.0. Set 1.0.0 for the first release if you prefer.
4. **Test on a real iPhone first.** Not done yet:
   - **Phone** (`mobilephone://`) is not verified: the simulator has no Phone app. App Review will tap it, because it is a starter app.
   - The black flash when a widget tap opens an app.
   - The Shortcut route from start to end.
5. **Source code claim.** Slide 5 says the source code is open (MIT). The GitHub repo `digitalhabits/dh-launcher` is private. Make it public before release, or change the slide (`scripts/store-assets.mjs`) and the README.
6. **"Inspired by Olauncher for Android"** is in the Settings footer. Other apps' names are not in the store text or keywords (App Review guideline 2.3.7). Keep or remove the footer.
7. **Privacy policy and support URL.** Put `privacy-policy.md` on digitalhabits.org (fill in the date and contact email). App Store Connect needs a privacy policy URL and a support URL.
8. **App Privacy answers** in App Store Connect: "Data Not Collected".
9. **Age rating:** answer "None" to every question (4+). **Price:** Free.
10. **Upload:** archive in Xcode (Product > Archive) and upload, or add an iOS lane to fastlane like To-Do's.

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
