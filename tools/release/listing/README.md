# Store listing text

The text pasted into App Store Connect, kept here so it has history and one
place to edit. App Store Connect is the live copy: after changing a file,
paste it there too (TestFlight → Test Information, or the Play Console release).

| file | App Store Connect field |
|---|---|
| `testflight_beta_description.txt` | Beta App Description (4000 characters max) |
| `testflight_review_notes.txt` | Beta App Review Information → Review Notes |
| `play_short_description.txt` | Play Console → Main store listing → Short description (80 characters max) |
| `play_full_description.txt` | Play Console → Main store listing → Full description (4000 characters max) |
| `play/` | Play Console → Main store listing graphics: `icon_512.png` (app icon), `feature_1024x500.png` (feature graphic), and two screenshot sets, still undecided: `phone_1–5.png` (portrait 1080×1920, phone slot only) and the landscape set (2560×1440, 16:9, accepted in the phone, 7-inch and 10-inch tablet slots): `landscape_1–2.png` are Newton's city by day and at night with the real widgets (Pixel 7 captures), then the protractor, fraction-bar and scratch-pad questions as `landscape_phone_3–5.png` (Pixel 7 in landscape) or `landscape_tablet_3–5.png` (Pixel Tablet emulator; the tablet layout is untuned, see #137) |
| `play_release_notes.txt` | Play Console → the testing track's release → Release notes (500 characters max, keep the `<en-US>` tags; rewrite the body per build) |

Keep the claims true of the current build. In particular, "progress carries
over between updates" holds only while every release follows CLAUDE.md
*Preserving player data across updates*, and "no ads or purchases, collects
no data" must change if add-on packs or any networking arrive. The credit
line for the avatar art is required by its CC BY 4.0 licence.

The app's public contact address is **quarup.mc@gmail.com**: use it for every
store field a tester or parent can see (App Store Connect feedback and
support email, Play Console contact email, the flyer, PRIVACY.md). Apple's
reviewer contact can stay personal.

For store fields that ask for a website, marketing or privacy-policy URL, use
the public website: **https://quarup.github.io/math_city/** (website,
marketing and support URL) and **https://quarup.github.io/math_city/privacy/**
(privacy policy URL). The privacy page is rendered from PRIVACY.md on each
deploy, so it always matches the repo.
