# Platform TTS ceiling (iOS / Android) and the reality of shipping a neural TTS model in a Flutter app — as of October 2026

Scope: what the built-in engines Math City already uses through `flutter_tts` (pinned `^4.2.0` in `pubspec.yaml`) can and cannot do, and what it would take to embed a Piper/Kokoro/Supertonic-class model instead. English-only, fully offline, no backend, kids on hand-me-down iPads.

Research caveat: several primary pages were unreachable from this environment (support.google.com, huggingface.co, picovoice.ai, eist.app, speechcentral.net, learn.microsoft.com, k2-fsa.github.io, getstream.io, heyneo.com, nimbleedge.com, xdaforums.com, bendodson.com). Where a fact comes only from a search-engine snippet of such a page, the citation still points at the page and the note says "(snippet)". Numbers reported from a vendor's own benchmark are flagged as such.

---

## Q1. iOS built-in TTS: voice quality tiers, offline availability, download sizes, what the app can trigger, style/emotion, word-boundary callbacks

### Takeaway
iOS has exactly three public quality tiers (`default` ships on-device; `enhanced` and `premium` must be downloaded by the *user* in Settings, typically 100 MB+ each). There is no public API to list or trigger downloads of not-yet-installed voices, no Siri voice access, no style/emotion API, and a Personal Voice that is restricted to AAC use. Word-boundary callbacks exist (`willSpeakRangeOfSpeechString`, iOS 7+) and are what `flutter_tts` surfaces. iOS 26.0/26.1 shipped a voice-selection regression that matters if you rely on `AVSpeechSynthesisVoice(language:)`.

### Cited Findings
- `AVSpeechSynthesisVoiceQuality` has three cases: `default` ("a basic quality voice that's available on the device by default"), `enhanced` ("an enhanced quality voice that you must download to use") and `premium` ("a premium quality voice that you must download to use"); all three exist since iOS 9 — [Apple: AVSpeechSynthesisVoiceQuality](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality)
- `AVSpeechSynthesisVoice` (iOS 7+) exposes `speechVoices()` (all voices available on the device), `identifier`, `audioFileSettings` and a `Traits` option set; the class docs list no download API — [Apple: AVSpeechSynthesisVoice](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice)
- Developers asking for an API to detect voices that are downloadable-but-not-installed got no public API; `speechVoices()` returns only the voices currently on the device, and downloads are manual via Settings — [Apple Developer Forums thread 758460](https://developer.apple.com/forums/thread/758460)
- Enhanced and premium voices were added in iOS 16 and "you have to manually download them as they are each over 100MB"; the download UI is Settings > Accessibility > Live Speech > Voices (snippet) — [Ben Dodson, "Using your Personal Voice ... in an iOS app"](https://bendodson.com/weblog/2024/04/03/using-your-personal-voice-in-an-ios-app/)
- Apple Support: enhanced-quality voices "can be 100 MB or larger" and the device must be on Wi‑Fi to download them (snippet) — [Apple Support 111798](https://support.apple.com/en-us/111798); a secondary guide puts Enhanced/Premium packs at "100 MB to 500 MB" (snippet, lower-quality source) — [aidictation.com](https://aidictation.com/blog/text-to-speech-iphone)
- The user-facing path on iOS 18/26 is Settings > Accessibility > Spoken Content > Voices — [AbilityNet, iOS 26 guide](https://mcmw.abilitynet.org.uk/how-to-customise-the-voice-used-by-screen-readers-in-ios-26-on-your-iphone-or-ipad)
- Siri voices are not available to third-party apps through `AVSpeechSynthesizer`; the stated reason is anti-impersonation/privacy, and there is no official workaround — [Apple Developer Forums thread 682438](https://developer.apple.com/forums/thread/682438)
- Personal Voice (iOS 17): apps call `AVSpeechSynthesizer.requestPersonalVoiceAuthorization()`, then filter `speechVoices()` by `voiceTraits.contains(.isPersonalVoice)`; Apple restricts its use to augmentative and alternative communication (AAC) apps — [WWDC23 session 10033](https://developer.apple.com/videos/play/wwdc2023/10033/)
- The same session introduced custom speech-synthesizer *extensions* (`AVSpeechSynthesisProviderAudioUnit`, iOS 17+): a third-party app can ship its own voices that become usable system-wide (VoiceOver, other apps); the extension receives an SSML representation of the request and may optionally emit word markers; the system handles audio playback — [WWDC23 session 10033](https://developer.apple.com/videos/play/wwdc2023/10033/)
- `AVSpeechSynthesisMarker` (iOS 16+) carries word / sentence / paragraph / phoneme / bookmark marks with byte-sample offsets, and is the marker type a provider extension hands back via `speechSynthesisOutputMetadataBlock` — [Apple: AVSpeechSynthesisMarker](https://developer.apple.com/documentation/avfaudio/avspeechsynthesismarker)
- Word-boundary callback: `speechSynthesizer(_:willSpeakRangeOfSpeechString:utterance:)` is "called once for each unit of speech in the utterance's text, which is generally a word", available since iOS 7, and Apple explicitly suggests it for highlighting words as they are spoken — [Apple: willSpeakRangeOfSpeechString](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate/speechsynthesizer(_:willspeakrangeofspeechstring:utterance:))
- SSML in `AVSpeechUtterance` exists (developers discuss `<sub>` tag handling and the synthesizer inserting short pauses around some tags) — [Apple Developer Forums thread 712411](https://developer.apple.com/forums/thread/712411)
- iOS 26.0 and 26.1 regression: `AVSpeechSynthesisVoice(language:)` returns the system default instead of the voice the user picked in Accessibility > Spoken Content > Voices (worked in iOS 18.6.2); most visible with third-party voices (CereProc, Grammatek); workaround is addressing a voice by explicit `identifier`; filed as FB20271264, Apple initially could not reproduce — [Apple Developer Forums thread 804648](https://developer.apple.com/forums/thread/804648)
- iOS 26 beta also had a Personal Voice bug (voice's language changing after a while) — [Apple Developer Forums thread 792409](https://developer.apple.com/forums/thread/792409)
- Older but recurring class of bug: after an iOS upgrade `speechVoices()` can list voices that are no longer actually present — [Apple Developer Forums thread 735893](https://developer.apple.com/forums/thread/735893); and a long "AVSpeechSynthesizer is broken on iOS 17" thread exists — [thread 738048](https://developer.apple.com/forums/thread/738048)
- A community gist enumerates the full `speechVoices()` output on a real device (useful to see identifiers like `com.apple.voice.compact.en-US.Samantha` vs `...enhanced...` / `...premium...`) — [Koze gist](https://gist.github.com/Koze/d1de49c24fc28375a9e314c72f7fdae4)

### Inferences
- For Math City the realistic iOS ceiling is: whatever `default` (compact) voices the device ships with, plus any Enhanced/Premium voice the *parent* has manually downloaded. The app can detect (via `getVoices` → quality field, see Q4) and politely ask, but cannot install.
- The custom-synthesizer extension path (iOS 17+) is the "official" way to ship your own neural voice on iOS. It is heavy (an Audio Unit extension process, app-group UserDefaults, SSML parsing) but it would make a Math City voice usable by `flutter_tts` unchanged. It is almost certainly more work than driving an ONNX model directly from Dart (Q5). Both are feasible.
- Because of the iOS 26 regression, pin voices by `identifier`, never by language alone.
- No evidence of any "style"/"emotion" parameter in `AVSpeechUtterance`; control is limited to rate, pitchMultiplier, volume, pre/post delays and SSML prosody.

### Gaps
- Exact per-voice download sizes for current English Enhanced/Premium voices (Ava, Zoe, Evan, etc.) are not published by Apple; only "100 MB or larger" is official. Treat 100–500 MB as an estimate.
- Whether iOS 26 added new neural voice tiers beyond default/enhanced/premium: no evidence found; the public enum is unchanged (still three cases).
- I could not fetch the `AVSpeechUtterance` reference page, so the rate range constants (`AVSpeechUtteranceMinimumSpeechRate` etc.) and `AVSpeechUtterance(ssmlRepresentation:)` availability are unverified here (from memory: iOS 16; verify before relying on it).
- Whether the user's "allow cellular downloads over 200 MB" App Store setting changes the 200 MB rule (training knowledge says iOS 13+ offers "Always Allow") — not re-verified.

---

## Q2. Android built-in TTS: Google TTS catalog, quality tiers, offline packs and sizes, OEM variation (Samsung, no-Google devices, Fire tablets), and bundling your own engine

### Takeaway
Android's `Voice` API gives you a quality integer (up to `QUALITY_VERY_HIGH` = 500), a latency hint and `isNetworkConnectionRequired()`, and Google's engine ships a small compact voice per language with optional "high quality" offline packs the user installs from Settings (historically 200+ MB vs 5–6 MB). Fragmentation is real: Samsung TTS became inaccessible to third-party apps on Android 15 / One UI 7–8, Fire tablets ship Amazon's own engine with no Google TTS by default, and quality varies by OEM. The good news: any app *can* register itself as a system TTS engine (`TextToSpeechService`), and sherpa-onnx ships a working example of exactly that.

### Cited Findings
- `Voice.QUALITY_VERY_HIGH` is defined as "very high, almost human-indistinguishable quality of speech synthesis", constant 500; `isNetworkConnectionRequired()` tells whether a voice needs network — [Android: Voice](https://developer.android.com/reference/android/speech/tts/Voice)
- The old `KEY_FEATURE_EMBEDDED_SYNTHESIS` / network-synthesis keys were deprecated in API 21 in favour of calling `getVoices()`, picking an embedded voice via `Voice.isNetworkConnectionRequired()` and passing it to `setVoice(Voice)` — [Android: TextToSpeech.Engine](https://developer.android.com/reference/android/speech/tts/TextToSpeech.Engine)
- Google TTS high-quality voice files are "200+MB" versus "5–6MB for standard voices" (en-GB female 276 MB in that release) and "loading large voice packs could take up to 10 seconds even on a Nexus 5" after reboot (2014 article; sizes and devices are dated) — [Android Police, Google TTS v3.0](https://www.androidpolice.com/2014/03/05/google-releases-huge-text-to-speech-tts-for-android-update-v3-0-with-high-quality-voices-new-languages-and-ui-changes-apk-download/)
- User flow to get better offline voices: Settings > Accessibility > Text-to-speech output > gear next to Preferred engine > Install voice data; the default compact voice "is low quality to save storage" and higher-quality offline voices are separate downloads (snippet) — [Android Police how-to](https://www.androidpolice.com/google-text-to-speech-android-how-to/)
- The Google "Speech Recognition & Synthesis" app itself is ~40 MB (September 2026 build; third-party mirror listing, voice packs excluded) — [Uptodown listing](https://google-text-to-speech.en.uptodown.com/android)
- Samsung: "Third-party apps can no longer access Samsung TTS directly as of Android 15/One UI 7–8" and common fixes (reinstalling voices, clearing cache, switching engines) do not restore it (snippet) — [Speech Central, March 2026](https://speechcentral.net/2026/03/22/samsung-tts-missing-on-android-15-one-ui-7-8-whats-really-happening/)
- Fire tablets ship a "Fire internal" TTS engine; switching to Google Text-to-Speech requires side-loading per an XDA how-to (title/snippet) — [XDA thread](https://xdaforums.com/t/how-to-switch-fire-tablet-tts-engine-from-fire-internal-to-google-text-to-speech.3950193/); Amazon acquired IVONA (the Kindle Fire voices) in 2013 — [PhoneArena](https://www.phonearena.com/news/Text-to-speech-outfit-IVONA-is-snapped-up-by-Amazon_id39068)
- Apps can be a system TTS engine: sherpa-onnx's `SherpaOnnxTtsEngine` Android app configures VITS/Matcha/Kokoro/Kitten/Supertonic models and copies model assets to external storage at first run — [sherpa-onnx TtsEngine.kt](https://github.com/k2-fsa/sherpa-onnx/blob/master/android/SherpaOnnxTtsEngine/app/src/main/java/com/k2fsa/sherpa/onnx/tts/engine/TtsEngine.kt); VoxSherpa is a GPL-3 Android app that exposes Piper/VITS/Kokoro to *system* text-to-speech (Android 11+, arm64, ~500 MB storage recommended) — [VoxSherpa-TTS](https://github.com/CodeBySonu95/VoxSherpa-TTS), [Speech Central write-up](https://speechcentral.net/2026/05/03/android-piper-tts-voxsherpa-brings-offline-neural-voices-to-system-text-to-speech/)
- Prebuilt sherpa-onnx "TTS engine" APKs per Piper voice are published (e.g. `sherpa-onnx-1.10.24-arm64-v8a-en-tts-engine-vits-piper-en_US-libritts-high.apk`) — [HF csukuangfj/sherpa-onnx-apk](https://huggingface.co/csukuangfj/sherpa-onnx-apk/commits/c7cdf2261ad6f29ed37af4140ee37ca595a55cdf/tts-engine-new/1.10.24/sherpa-onnx-1.10.24-arm64-v8a-en-tts-engine-vits-piper-en_US-libritts-high.apk); the Piper project tracked these — [rhasspy/piper issue 257](https://github.com/rhasspy/piper/issues/257)

### Inferences
- On Android the app cannot trigger a Google voice-pack install either; the standard trick (`ACTION_INSTALL_TTS_DATA` intent) just opens the engine's install UI. `flutter_tts` exposes `isLanguageInstalled`/`areLanguagesInstalled` to detect, nothing to install (see Q4).
- A kid on a Fire tablet or a de-Googled phone will hear whatever OEM engine is present, possibly none. A bundled engine is the only way to guarantee a consistent voice across Android devices.
- Registering as a `TextToSpeechService` is attractive only if you want other apps to see the voice; for Math City's own use, direct FFI inference is simpler and avoids the external-storage copy step.

### Gaps
- Current (2025–2026) Google voice-pack sizes and the list of English voices (`en-us-x-...` identifiers, "natural"/neural tier) could not be verified from a primary page; the 2014 sizes above are the only measured numbers found.
- Primary Play Console size-limit page (support.google.com/googleplay/android-developer/answer/9859372) was blocked; see Q6 for the secondary sources used.
- No measured data on Google TTS quality tiers across OEM devices beyond the Samsung access regression.

---

## Q3. Child voices / explicit age or style control on either platform

### Takeaway
Neither Apple's nor Google's public voice catalogues offer a child voice or an age/style knob; genuine children's TTS voices exist only commercially (Acapela, via AssistiveWare). The open models considered here (Piper, Kokoro, Supertonic, KittenTTS) ship adult speakers; pitch-shifting an adult voice is the only built-in lever.

### Cited Findings
- Acapela, with AssistiveWare, has produced "genuine text to speech children's voices" since 2012 and now markets an AI voice that "grows with the child" — commercial licensing — [Acapela children's voices](https://www.acapela-group.com/voices/children-voices/)
- Apple's public voice `Traits` are `isNoveltyVoice` and `isPersonalVoice`; there is no age or style trait in the documented API — [Apple: AVSpeechSynthesisVoice](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice), [WWDC23 10033](https://developer.apple.com/videos/play/wwdc2023/10033/)
- Android's `Voice` describes name, locale, quality, latency, network requirement and a free-form feature set; no age field — [Android: Voice](https://developer.android.com/reference/android/speech/tts/Voice)
- KittenTTS ships "eight voices: four male and four female" (adult) — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS); Supertonic ships preset voice styles and its custom Voice Builder closed on 31 Aug 2026 — [supertone-inc/supertonic](https://github.com/supertone-inc/supertonic)
- `flutter_tts` exposes `setPitch` on all platforms — [pub.dev flutter_tts](https://pub.dev/packages/flutter_tts)

### Inferences
- "Ten named citizens" can only be differentiated on platform TTS by (a) picking distinct installed voices per character and (b) pitch/rate offsets. Pitch-shifting platform voices up to sound "younger" is the standard hack and the only one available without a custom model.
- A custom model is the only route to real age/style control, and even then only if a suitably licensed child-voice dataset exists (none found in the open-model catalogues searched).

### Gaps
- I found no authoritative statement from Apple or Google saying "no child voices"; the absence is inferred from the documented API surface and voice lists.
- No open (non-NC) child-speaker TTS dataset or checkpoint surfaced in this research.

---

## Q4. What `flutter_tts` exposes vs. hides (voice selection, voice-switch latency, progress callbacks, SSML, synth-to-file)

### Takeaway
`flutter_tts` 4.2.5 (MIT) exposes voice listing/selection, rate/pitch/volume, word-progress callbacks on iOS/Android/web, `synthesizeToFile` on iOS/Android, iOS audio-session category control and Android engine selection/queue mode. It hides SSML, voice download/installation, the Android `Voice` quality/latency fields beyond what `getVoices` returns, and any style parameter. Per-utterance voice-switch latency is not measured anywhere I could find.

### Cited Findings
- Latest release 4.2.5, MIT licence; feature matrix: `speak/stop/pause`, `getVoices/setVoice`, `getLanguages/setLanguage`, `setSpeechRate/setVolume/setPitch` on all platforms; `synthesizeToFile` iOS (13+) and Android; speech marks/progress on iOS, Android and web; `awaitSpeakCompletion`, `setSharedInstance`, `setIosAudioCategory` on iOS; Android-only `getEngines/setEngine`, `getDefaultEngine`, `getDefaultVoice`, `isLanguageInstalled`, `areLanguagesInstalled`, `setSilence`, `setQueueMode`, `getMaxSpeechInputLength`; Android pause is a workaround built on `onRangeStart()` and needs SDK 26+; minSdk 21 — [pub.dev flutter_tts](https://pub.dev/packages/flutter_tts)
- Changelog: 4.2.0 added web progress events via `onboundary`; 4.1.0 improved `synthesizeToFile` on Android/iOS; 3.8.4 fixed `synthesizeToFile` on iOS 17+; 3.2.0 added `awaitSynthCompletion` — [flutter_tts changelog](https://pub.dev/packages/flutter_tts/changelog)
- Word-level progress was a long-standing feature request mapping Android `onRangeStart` and iOS `willSpeakRangeOfSpeechString` — [issue #41](https://github.com/dlutton/flutter_tts/issues/41); a reported bug: `setProgressHandler` stops firing after ". ", "! " or "? " — [issue #228](https://github.com/dlutton/flutter_tts/issues/228)
- A fork carries an upstream fix for an iOS `synthesizeToFile` crash when `AVSpeechSynthesizer.write(_:toBufferCallback:)` emits Int16 PCM buffers instead of Float32 — [Persie0/flutter_tts PR #7 (upstream #632)](https://github.com/Persie0/flutter_tts/pull/7)
- `synthesizeToFile` saving to external storage on Android has its own issue thread — [issue #492](https://github.com/dlutton/flutter_tts/issues/492)
- SSML is not listed in the plugin's feature set; a separate (online, Microsoft Edge-backed) package advertises SSML synthesis as the differentiator — [flutter_edge_tts](https://github.com/Moosphan/flutter_edge_tts)
- A fork exists whose purpose is better use of the native utterance progress reporters on both platforms — [flutter_tts_improved](https://github.com/loushou/flutter_tts_improved)

### Inferences
- Hidden but reachable: `getVoices` on iOS returns `name`, `locale`, `identifier`, `quality`, `gender` maps (quality strings `default/enhanced/premium`), so Math City can already prefer an installed Enhanced/Premium voice and fall back; on Android the quality integer and `isNetworkConnectionRequired` are what you want to filter on. (Field names from memory of the plugin source; verify.)
- No API for voice-pack install on either side, so the best UX is a one-time "Tip: install a better voice" screen deep-linking to Settings where the platform allows.
- Expect the first `speak()` after a `setVoice()` to a not-yet-loaded Google HQ voice pack to stall (the 2014 "up to 10 s" report is the only number found; modern devices are faster but the cold-load phenomenon persists). Pre-warm by speaking an empty/silent utterance at app start.

### Gaps
- No measurement of per-utterance voice-switch latency on iOS or Android was found; this needs an in-app timer experiment.
- Whether `flutter_tts` passes raw SSML through unchanged on Android (where Google TTS accepts a `<speak>` subset) is undocumented; it would need a source read.
- The exact map keys returned by `getVoices` per platform were not re-verified from the current source.

---

## Q5. Embedding a neural model in Flutter: runtimes with working Flutter integration, what real projects report (RTF, first-audio latency, RAM, size), model licences, and how multi-hundred-MB voice data ships

### Takeaway
sherpa-onnx (Apache-2.0) is the de-facto Flutter path: its `sherpa_onnx` Dart package (1.13.8) bundles ONNX Runtime for Android/iOS and runs Piper/VITS, Matcha, Kokoro, Kitten, Supertonic, Pocket TTS and ZipVoice. Measured phone numbers cluster as: Piper-class ≈ RTF 0.08–0.33 (flagship→budget Android), Kokoro-82M ≈ RTF 0.3–3 on CPU (≈0.9× real-time on flagship Android per a 360k-run field dataset; ≈1.4× on iPhone CPU, ~3–4× with MLX/Metal; RTF 0.26 with Qualcomm NPU on an S24 Ultra), model data ≈ 60–80 MB (Piper medium / Kokoro int8) to ~300 MB (Kokoro fp32) to 1.4 GB (NPU-compiled bundle). Licensing is the trap: Piper's current repo is GPL-3 because of espeak-ng, and Kokoro's English G2P also falls back to espeak-ng; Supertonic's model is OpenRAIL-M (use-restricted, not NC); KittenTTS and Kokoro weights are Apache-2.0.

### Cited Findings — runtimes and Flutter packages
- sherpa-onnx is Apache-2.0; TTS engines listed: Piper, Matcha, Kokoro, Pocket TTS, ZipVoice, Supertonic; targets Android, iOS, Flutter (examples for Android/iOS/desktop), React Native — [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)
- `sherpa_onnx` Dart package: 1.13.8, Apache-2.0, Android (arm64, arm32, x86, x86_64), iOS (arm64), macOS, Windows, Linux, web; native libs via `sherpa_onnx_android_*`, `sherpa_onnx_ios`, etc. — [pub.dev sherpa_onnx](https://pub.dev/packages/sherpa_onnx); iOS binary changelog — [sherpa_onnx_ios changelog](https://pub.dev/packages/sherpa_onnx_ios/changelog)
- `flutter_onnxruntime` 1.8.5 (verified publisher masic.ai) wraps ONNX Runtime 1.23.0; Android needs ≥1.5.1 for Google Play's 16 KB page-size requirement; iOS requires iOS 16 minimum and static linkage — [pub.dev flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)
- `flutter_litert` (LiteRT, formerly TFLite) is a fork of `tflite_flutter` with bundled native runtimes for Android/iOS/desktop/web — [pub.dev flutter_litert](https://pub.dev/packages/flutter_litert); `flutter_gemma_speech` runs TTS models (Qwen3-TTS, Inflect-Nano-v2) through the LiteRT C API via `dart:ffi` — [pub.dev flutter_gemma_speech](https://pub.dev/packages/flutter_gemma_speech)
- Supertonic's own repo lists Swift/iOS and Flutter among supported runtimes — [supertone-inc/supertonic](https://github.com/supertone-inc/supertonic)
- Kokoro on iOS via Apple MLX (Swift package, MIT, iOS 18+/macOS 15+) — [mlalma/kokoro-ios](https://github.com/mlalma/kokoro-ios); a Core ML conversion also exists — [FluidInference/kokoro-82m-coreml](https://huggingface.co/FluidInference/kokoro-82m-coreml)

### Cited Findings — measured performance on phones/tablets
- Field data from the Éist reader app: across 895 Android device models and >360,000 synthesis runs, Kokoro runs at "roughly 0.9x" real-time on flagship-class Android; the standard Kokoro engine reaches ~1.4× on iPhone, and "Fast Kokoro" (iOS-only, MLX on the Metal GPU) ~4× (snippet; blog page blocked) — [Éist blog](https://eist.app/blog/neural-tts-speed-across-800-android-devices)
- Galaxy S24 Ultra (Snapdragon 8 Gen 3) with ONNX Runtime + Qualcomm QNN 2.48 HTP: generator RTF 0.2644 (3.78× real-time), mean 0.2911 in production; first-audio latency 306 ms in native self-test but median 949.8 ms through the Android TTS callback path; the APK is ~1.40 GiB because it bundles 28 English voices plus 11 pre-compiled HTP contexts; other arm64 phones fall back to q8 CPU with "significantly degraded performance"; licences: project Apache-2.0, Kokoro Apache-2.0, eSpeak NG GPL-3.0-or-later, QNN proprietary — [cedgeremek/kokoro-offline-tts-android](https://github.com/cedgeremek/kokoro-offline-tts-android)
- iPhone 13 Pro, MLX, release build, after warm-up: Kokoro "~3.3 times faster than real-time" — [mlalma/kokoro-ios](https://github.com/mlalma/kokoro-ios)
- VoxSherpa (sherpa-onnx, CPU) device tiers — Kokoro: flagship (SD 8 Gen 3) ~20–40 s per minute of audio (RTF ≈0.33–0.67), mid-range 8-core ~60–90 s/min (RTF ≈1–1.5), budget 6-core ~2–3 min/min (RTF ≈2–3); Piper/VITS: ~5 s/min flagship (RTF ≈0.08), ~10 s/min mid (≈0.17), ~20 s/min budget (≈0.33); needs Android 11+, arm64, ~500 MB free storage — [VoxSherpa-TTS](https://github.com/CodeBySonu95/VoxSherpa-TTS)
- Piper via sherpa-onnx on a "midrange 2024 Android device": first inference ≈400 ms including cold model load (snippet) — [Medium, "Running Neural TTS On-Device with Piper and sherpa-onnx"](https://medium.com/@patare.vivek/running-neural-text-to-speech-on-device-with-piper-and-sherpa-onnx-58f4eed29247)
- Piper `en_US-lessac-high` RTF 0.20 on a Raspberry Pi 4 (secondary blog) — [FreeVoiceReader comparison](https://www.freevoicereader.com/blog/offline-tts-local-ai-2026-comparison)
- Picovoice's (vendor) benchmark lists Kokoro at 341 MB model, 2.0 GB peak memory, 3,658 ms first-time-to-speech on desktop and notes Kokoro has no official mobile SDK (snippet; page blocked; Picovoice sells a competing engine) — [Picovoice on-device TTS benchmark](https://picovoice.ai/blog/on-device-tts/)
- Supertonic 3 on an M4 Pro CPU: 912–1,263 characters/s (RTF 0.015–0.012); WebGPU 996–2,509 chars/s; no phone numbers published (snippet) — [mer.vin write-up](https://mer.vin/2026/06/supertonic-3-99m-on-device-tts-with-onnx-31-languages-and-1200-chars-sec/)
- KittenTTS: smallest model 15M params, <25 MB, int8+fp16 ONNX; on an i9-14900HX loads in ~710 ms and synthesises ~5× real-time; designed for "raspberry pi, low-end smartphones, wearables" — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS)

### Cited Findings — model sizes and licences
- Kokoro-82M: 82M parameters, 24 kHz, code and weights Apache-2.0; G2P is `misaki`, with espeak-ng as fallback for English out-of-distribution text — [hexgrad/kokoro](https://github.com/hexgrad/kokoro); ONNX export ≈300 MB fp32, ≈80 MB quantized, `kokoro-onnx` wrapper MIT — [thewh1teagle/kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx)
- Piper: original `rhasspy/piper` is MIT but was archived 6 Oct 2025 — [rhasspy/piper](https://github.com/rhasspy/piper); its successor `OHF-Voice/piper1-gpl` is GPL-3.0 because it embeds espeak-ng for phonemization; per-voice dataset licences live in `docs/VOICES.md` — [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl)
- Supertonic 3: ~99M params, 31 languages, code MIT, model OpenRAIL-M; Voice Builder (custom voices) no longer accessible after 31 Aug 2026 — [supertone-inc/supertonic](https://github.com/supertone-inc/supertonic); the F-Droid Android app wrapping it is GPL-3.0 — [F-Droid Supertonic TTS](https://f-droid.org/en/packages/com.brahmadeo.supertonic.tts/)
- KittenTTS: Apache-2.0 — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS)
- sherpa-onnx: Apache-2.0 — [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx); `flutter_soloud`: MIT — [pub.dev flutter_soloud](https://pub.dev/packages/flutter_soloud); `flutter_tts`: MIT — [pub.dev flutter_tts](https://pub.dev/packages/flutter_tts)

### Cited Findings — shipping voice data
- The S24-Ultra Kokoro engine bundles everything (1.4 GiB APK, "no network permission") — [kokoro-offline-tts-android](https://github.com/cedgeremek/kokoro-offline-tts-android); VoxSherpa downloads models at runtime and recommends ~500 MB free — [VoxSherpa-TTS](https://github.com/CodeBySonu95/VoxSherpa-TTS); sherpa-onnx's engine example copies model assets from the APK to external storage on first launch — [TtsEngine.kt](https://github.com/k2-fsa/sherpa-onnx/blob/master/android/SherpaOnnxTtsEngine/app/src/main/java/com/k2fsa/sherpa/onnx/tts/engine/TtsEngine.kt)
- A Flutter plugin wraps Play Asset Delivery (Android, minSdk 24, `com.google.android.play:asset-delivery:2.2.2`) and iOS On-Demand Resources behind one `fetch`/`watch` API with progress — [asset_delivery on pub.dev](https://pub.dev/documentation/asset_delivery/latest/); alternatives: [flutter_play_asset](https://github.com/chasing/flutter_play_asset), [play_asset_delivery](https://github.com/st1llsane/play_asset_delivery)

### Inferences
- Rough "what it costs" for Math City, English only, one or two voices (estimates, derived from the sources above): sherpa-onnx native libs (ONNX Runtime + sherpa) tens of MB per ABI; a Piper medium voice ≈60–80 MB with espeak-ng data; Kokoro int8 ≈80 MB + ~27 MB voices; Kokoro fp32 ≈300 MB. A Piper-class voice fits under both stores' 200 MB cellular/base thresholds (Q6) if bundled; Kokoro fp32 does not.
- Speed on hand-me-down iPads: no direct measurements exist. Extrapolating from the Android tiers (budget 6-core ≈ RTF 2–3 for Kokoro, ≈0.33 for Piper) and the iPhone 13 Pro MLX number, an A10/A12-class iPad on CPU is likely RTF >1 for Kokoro (unusable for interactive prompts without pre-rendering) and comfortably <0.5 for Piper/Kitten (estimate). Math City's prompts are short, so pre-synthesising the next question's audio while the current one plays would hide most latency.
- The licensing picture for this project (no NC, free-software friendly): Kokoro (Apache-2.0 weights) is cleanest *if* you avoid the espeak-ng GPL fallback or accept GPL in the app (the project is already open source, so GPL may be acceptable — a decision, not a blocker); Piper current branch is GPL-3; Supertonic's OpenRAIL-M has use-based restrictions that need reading before shipping in a kids' app; KittenTTS is Apache-2.0 and tiny but quality is unproven in the sources found.
- Memory: the only hard number is Picovoice's 2.0 GB peak for Kokoro on desktop (fp32, Python). An int8 ONNX Kokoro on-device will be far lower but no phone RAM measurement was found; treat 300–600 MB as an estimate for Kokoro and <150 MB for Piper. Older 2 GB iPads make Kokoro fp32 risky.

### Gaps
- No RTF/latency/RAM measurements for any neural TTS on iPads (any generation) or on iPhones older than the 13 Pro were found.
- No phone numbers at all for Supertonic 3 or KittenTTS (only desktop/M4 Pro and a Cortex-A77 relative speed-up claim).
- Picovoice and Éist pages were blocked; their numbers come from search snippets and should be re-verified before quoting externally.
- ExecuTorch: no Flutter plugin or Flutter TTS example surfaced; I found no evidence of a working Flutter integration as of Oct 2026.
- Core ML path from Flutter: no package found; it would need a hand-written platform channel or FFI around the FluidInference Core ML model.
- Per-voice Piper dataset licences (`docs/VOICES.md`) were not fetched; several Piper voices are known to derive from datasets with non-commercial terms, so each voice must be checked individually.

---

## Q6. Store constraints: App Store and Google Play size limits, cellular thresholds, Play Asset Delivery tiers, iOS On-Demand Resources (and their deprecation)

### Takeaway
Both stores allow 4 GB apps, but both treat ~200 MB as the practical threshold (iOS cellular download, Android base-module limit/large-size warning). Android's Play Asset Delivery and iOS's On-Demand Resources (now deprecated in favour of Background Assets) let a voice pack ship outside the base download; a Flutter plugin exists for both.

### Cited Findings
- iOS: maximum uncompressed app size 4 GB (iOS 9+), executable `__TEXT` limit 80 MB; Apple points to Background Assets for hosting large assets outside the build — [App Store Connect: Maximum build file sizes](https://developer.apple.com/help/app-store-connect/reference/maximum-build-file-sizes/)
- iOS On-Demand Resources (iOS 18+): app bundle 4 GB, 8 GB per asset-pack tag, 1,000 packs, 70 GB hosted; **ODR is deprecated as of iOS 27 / iPadOS 27**, with Background Assets as the replacement — [App Store Connect: ODR size limits](https://developer.apple.com/help/app-store-connect/reference/app-uploads/on-demand-resources-size-limits)
- App Store cellular download limit raised from 150 MB to 200 MB in 2019 — [iDownloadBlog](https://www.idownloadblog.com/2019/05/31/app-store-cellular-download-limit-200-mb/); earlier raise to 150 MB — [GSMArena](https://www.gsmarena.com/apple_increases_its_app_store_download_limit_over_cellular_to_150mb-news-27364.php)
- Android app bundles: total compressed download (base + config APKs) ≤ 4 GB; asset packs do not count toward it but have their own limits — [Android: About app bundles](https://developer.android.com/guide/app-bundle)
- Play Asset Delivery: install-time packs count toward the listed store size and need ~2× their size in free space at install; fast-follow and on-demand packs do not count toward the listed size; "games larger than 200MB" are the stated use case; higher limits for Play Partner Program for Games members — [Android: Play Asset Delivery](https://developer.android.com/guide/playcore/asset-delivery)
- Secondary sources state the Play base-module compressed limit is 200 MB and that apps over 200 MB trigger a non-blocking "large app" dialog on mobile data (snippets; primary support page blocked) — [vmobify](https://vmobify.com/blog/app-size-affect-installs), [ptkd](https://ptkd.com/journal/android-play-store-app-bundle-size-limit-fix)
- Flutter: `asset_delivery` plugin covers Play Asset Delivery (on-demand) and iOS ODR tags with progress streaming — [asset_delivery docs](https://pub.dev/documentation/asset_delivery/latest/)

### Inferences
- Math City's safest shape: keep the base app <200 MB on both stores and treat any neural voice >~50 MB as a download-on-first-run pack. On Android use an on-demand or fast-follow asset pack; on iOS, ODR still works today but is deprecated from iOS 27, so new work should target Background Assets (Apple-hosted) or a plain HTTPS download to the app's Application Support directory (which needs a server or a static CDN — a mild tension with "no backend").
- A Piper/Kitten-class voice (<80 MB) could simply be bundled and stay under both 200 MB thresholds; Kokoro fp32 cannot.

### Gaps
- Exact current Play numbers (base module 200 MB; install-time pack limit; fast-follow/on-demand per-pack and total limits — historically 1.5 GB install-time / 4 GB total) could not be read from the primary page (blocked); verify at support.google.com/googleplay/android-developer/answer/9859372 before relying on them.
- Background Assets per-pack limits were not fetched.

---

## Q7. Flutter-specific gotchas: isolates for inference, playing generated PCM, iOS audio session categories

### Takeaway
The tooling exists (sherpa_onnx is FFI; flutter_soloud / flutter_pcm_sound / audio_stream_player play raw PCM), but nothing in the sources measures the Dart-side integration cost, and the only concrete platform gotcha documented is iOS audio-session category handling (which `flutter_tts` already exposes).

### Cited Findings
- `flutter_soloud` 5.1.6 (MIT; Android/iOS/macOS/Windows/Linux/web) supports buffer streaming with raw PCM, MP3, Opus/Vorbis/FLAC input — [pub.dev flutter_soloud](https://pub.dev/packages/flutter_soloud), [streaming docs](https://docs.page/alnitak/flutter_soloud_docs/advanced/streaming)
- `flutter_pcm_sound` feeds real-time 16-bit PCM to the speaker with a `setFeedCallback` pull model, intended for audio generated "a few milliseconds before you hear it" — [pub.dev flutter_pcm_sound](https://pub.dev/packages/flutter_pcm_sound); `audio_stream_player` is a low-latency PCM chunk player aimed at TTS/realtime voice output — [audio_stream_player](https://github.com/adrianczuczka/audio_stream_player)
- `flutter_tts` exposes `setIosAudioCategory` and `setSharedInstance` for iOS session configuration — [pub.dev flutter_tts](https://pub.dev/packages/flutter_tts)
- The iOS custom-synthesizer extension route hands audio playback and session management to the system instead of the app — [WWDC23 10033](https://developer.apple.com/videos/play/wwdc2023/10033/)
- `flutter_onnxruntime` on iOS requires static linkage and iOS 16+ — [pub.dev flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)
- Kokoro's Android TTS-callback path adds ~650 ms median over the native self-test latency (306 → 950 ms) — [kokoro-offline-tts-android](https://github.com/cedgeremek/kokoro-offline-tts-android)

### Inferences
- sherpa_onnx is `dart:ffi`; a synchronous `generate()` on the main isolate will freeze Flame's game loop for the whole RTF×duration. Run synthesis in a dedicated isolate (or use the callback/streaming generation API) and hand PCM chunks to a streaming player; the Flutter 3.x `Isolate.run` + `TransferableTypedData` pattern applies. (Inference; no source measured this.)
- Math City already plays SFX via `flame_audio` (audioplayers); adding a second audio engine (SoLoud) for TTS PCM means two libraries configuring the iOS `AVAudioSession`. Pick one: flutter_soloud can also play the game's SFX, which would let `flame_audio` go. (Inference.)
- Pre-render: since question prompts are generated from seeds, synthesise the next prompt's PCM to a cache while the current screen is up; cache by text hash in the app's cache directory. This neutralises RTF >1 on old devices for everything except the very first prompt. (Inference.)

### Gaps
- No source measured isolate-transfer overhead or Flame + SoLoud + ONNX co-existence on iOS; this is engineering risk to prototype, not research.
- No source on `flame_audio`/audioplayers vs. `flutter_tts` audio-session conflicts specifically.
