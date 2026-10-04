# Open-source on-device TTS models that could replace the OS TTS in Math City (state as of October 2026)

Scope note for the report writer: this note covers open-weights text-to-speech models small enough to bundle in a phone/tablet app (roughly under ~500 MB, ideally under ~100 MB), with licensing of code, weights and training data separated wherever a source states them. Research constraints that affected coverage: huggingface.co, hf-mirror.com, k2-fsa.github.io, artificialanalysis.ai, picovoice.ai, offlinetts.com, tts.ai, texttolab.com, kyutai.org and news.ycombinator.com were all blocked by the network proxy, so model-card text is cited through GitHub READMEs, PyPI pages, GitHub-hosted docs, and search-result snippets (flagged as such). Numbers from search snippets that I could not open on the primary page are marked "(snippet)". Project uses Flutter; sherpa-onnx has a Dart/Flutter binding, which is relevant throughout.

## Key Question 0: Model-by-model dossier — architecture, size, voices, licenses, status

### Takeaway
As of October 2026 the realistic shortlist for a sub-500 MB, CPU-only, English kids' game is: Kokoro-82M (Apache-2.0, ~80–340 MB, 50+ voices, needs espeak-ng fallback unless you restrict to the misaki dictionary), KittenTTS nano/micro/mini (Apache-2.0 small models, 25–80 MB, 8 voices, espeak/phonemizer dependency), Kyutai Pocket TTS (MIT code / CC-BY-4.0 weights, ~242 MB, 100M params, no phonemizer, voice cloning, actively maintained), Supertonic 3 (MIT code / OpenRAIL-M model, 99M params, 31 languages, fastest CPU RTF, but archived Sept 2026), Piper (GPL-3.0 code since the OHF move, MIT voices mostly, 10–114 MB per voice, espeak-ng), and Matcha-TTS/MeloTTS (MIT research models with narrow voice sets). Everything LLM-based above ~350M params (NeuTTS Air, Chatterbox Turbo, Orpheus 3B, Qwen3-TTS, VibeVoice, Dia, Zonos, OuteTTS, Fish S1-mini) is either over the size budget on disk, GPU-oriented, or carries a non-commercial/custom license.

### Cited Findings

**Kokoro-82M (hexgrad)**
- Architecture: "built on StyleTTS 2 architecture with ISTFTNet"; 82M parameters; 24 kHz output; G2P is the misaki library with "espeak-ng for English out-of-distribution cases and some non-English languages"; languages: American English, British English, Spanish, French, Hindi, Italian, Japanese, Brazilian Portuguese, Mandarin — [hexgrad/kokoro README](https://github.com/hexgrad/kokoro)
- License: Apache-2.0 for both model weights and code — [hexgrad/kokoro README](https://github.com/hexgrad/kokoro); "Apache-licensed weights" — [kokoro on PyPI](https://pypi.org/project/kokoro/)
- Training data: the README thanks "everyone who contributed synthetic training data" but gives no hours or dataset list — [kokoro on PyPI](https://pypi.org/project/kokoro/); [hexgrad/kokoro README](https://github.com/hexgrad/kokoro). (The HF model card's fuller statement about "permissive/non-copyrighted" audio could not be fetched — see Gaps.)
- Voices: HF model card v1.0 (Jan 27 2025) lists 54 voices across 8 languages (snippet) — [Kokoro TTS review, VisionStory](https://www.visionstory.ai/open-source/kokoro-tts); sherpa-onnx packages "kokoro-multi-lang-v1_0 (53 speakers)", "kokoro-multi-lang-v1_1 (103 speakers, Chinese+English, int8 option)", and "kokoro-en-v0_19 (11 speakers)" — [sherpa docs kokoro.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/kokoro.rst)
- On-disk: kokoro-onnx describes itself as "Lightweight: ~300MB (quantized: ~80MB)"; kokoro-onnx code is MIT, model Apache-2.0 — [thewh1teagle/kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx); the sherpa-onnx v1_0 archive has a ~310 MB model.onnx plus voices.bin, tokens.txt, lexicon files and an espeak-ng-data directory — [sherpa docs kokoro.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/kokoro.rst); Picovoice's benchmark lists Kokoro at 341 MB model size — [Picovoice text-to-speech-benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md); kokoro-e2e.onnx ~330 MB and voices-v1.0.bin 27 MB (snippet) — [soniqo Kokoro Android guide](https://soniqo.audio/guides/kokoro/android)
- Maintenance: PyPI latest release 0.9.4 on April 5 2025 — [kokoro on PyPI](https://pypi.org/project/kokoro/); kokoro-onnx shows 230 commits and "model-files-v1.1" releases — [thewh1teagle/kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx)
- Quality: ranked 6th among open-weight models with 1,060 Elo (Aug 2026 snapshot) and 32nd overall at 1056.2 Elo / 54.4% win rate (snippet) — [offlinetts TTS Arena leaderboard 2026](https://www.offlinetts.com/blog/tts-arena-leaderboard-2026/)

**Supertonic 1/2/3 (Supertone Inc.)**
- Versions: Supertonic 3 ~99M params, 31 languages; Supertonic 2 ~66M, 5 languages; Supertonic 1 ~66M, English only; 44.1 kHz 16-bit output; 10 inline expression tags; 6 preset voice styles (M3, M4, M5, F3, F4, F5) plus earlier styles; "Voice Builder" produced custom voice JSON profiles — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)
- A third-party Android app describes the Supertonic bundle as "30 languages × 10 speakers in one bundle" — [HayaiTTS README](https://github.com/HayaiApp/HayaiTTS/tree/main)
- License: code MIT (LICENSE file is plain MIT, copyright Supertone Inc. 2025) — [supertonic LICENSE](https://github.com/supertone-oss-archive/supertonic/blob/main/LICENSE); model "OpenRAIL-M License" per the model LICENSE on Hugging Face (HF README front-matter `license: openrail`) — [Supertone/supertonic HF README](https://huggingface.co/Supertone/supertonic/blob/main/README.md); "MIT License (sample code) and OpenRAIL-M License (models)" — [dev.to writeup](https://dev.to/wonderlab/open-source-project-of-the-day-part-11-supertonic-lightning-fast-on-device-multilingual-tts-50hp)
- Quality: Supertonic 3 WER/CER on the Minimax-MLS-test benchmark ranges 0.86–5.40 across languages, English 2.06 WER — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)
- Speed: "average RTF of 0.3× on Onyx Boox Go 6 e-reader" in airplane mode; Raspberry Pi real-time demo; official benchmark "5.00x real-time on a 16-thread CPU across 30 samples" (snippet) — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic); [offlinetts May 2026 news](https://offlinetts.com/blog/tts-stt-news-may-2026/); Picovoice lists Supertonic-TTS-2 at 262 MB model size — [Picovoice benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md)
- SDKs: Python, Node.js, browser (WebGPU), Java, C++, C#, Go, Swift/iOS, Rust, Flutter — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)
- Status: "This repository was archived by the owner on Sep 9, 2026"; "Development and support have ended"; "Voice Builder will no longer be accessible after August 31, 2026"; "No updates, bug fixes, security patches, or support will be provided"; code preserved under the supertone-oss-archive org — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)
- Training data: no statement found in the GitHub README — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)

**KittenTTS (KittenML / Stellon Labs)**
- Small ONNX models: kitten-tts-nano 15M params, 56 MB (25 MB int8); kitten-tts-micro 40M params, 41 MB; kitten-tts-mini 80M params, 80 MB; large model "KittenTTS 2" 1.7B params, 506 MiB quantized ("emb4") / 947 MiB default, 47 built-in voices + voice cloning, 20 languages — [KittenTTS README (raw)](https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md)
- Licenses: "Code licensed under Apache 2.0; models licensed separately"; KittenTTS 2 under the "Stellon Labs Community License" — [KittenTTS README (raw)](https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md); the nano 0.8 int8 HF repo is tagged apache-2.0 and lists 8 voices (Bella, Jasper, Luna, Bruno, Rosie, Hugo, Kiki, Leo) (snippet) — [KittenML/kitten-tts-nano-0.8-int8](https://huggingface.co/KittenML/kitten-tts-nano-0.8-int8)
- Stellon Labs Community License: commercial use "requires registration" and "exceeding its revenue or funding limits requires a separate license" (snippet) — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS)
- Phonemizer: the browser port runs text "through eSpeak WASM to get phonemes" (snippet) — [codeandlife KittenTTS browser port](https://codeandlife.com/2026/02/26/kittentts-browser-port-with-codex/); HN commenters noted the code uses the GPL-3.0 `phonemizer` package despite the Apache-2.0 repo license (snippet) — [HN thread](https://news.ycombinator.com/item?id=44809541)
- Picovoice lists Kitten-TTS-Nano at 42 MB, English only — [Picovoice benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md)
- Quality evidence: README gives a speaker-similarity score (0.81) for KittenTTS 2 cloning and an A100 throughput number; no MOS/Elo for the small models — [KittenTTS README (raw)](https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md)

**Piper (rhasspy → Open Home Foundation, OHF-Voice/piper1-gpl)**
- Status/licensing: the original rhasspy/piper repo was archived read-only on October 6 2025 with its README pointing to OHF-Voice/piper1-gpl; license "flipped from MIT in the archived repository to GPL-3.0 in the successor"; releases v1.4.2 (April 2026) and v1.6.0 (July 2026) (snippet) — [offlinetts self-hosted TTS guide](https://offlinetts.com/blog/self-hosted-tts-guide-2026/); [piper-tts on libraries.io](https://libraries.io/pypi/piper-tts)
- The successor repo is GPL-3.0 and "embeds espeak-ng for phonemization"; "The Open Home Foundation is looking for maintainers for Piper!" — [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl)
- Voices: "Voices are trained with VITS and exported to the onnxruntime"; 43 languages listed; two files per voice (.onnx + .onnx.json); "The MODEL_CARD file for each voice contains important licensing information... Some voices may have restrictive licenses" — [piper1-gpl VOICES.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md)
- Sizes: high ≈ 114 MB ONNX (~28M params), medium ≈ 63 MB (~15M params), low ≈ 20 MB, x_low ≈ 10 MB; en_US-lessac trained on the Blizzard 2013 Lessac dataset (Catherine Byers), lessac-high tagged MIT (snippet) — [Trelis/piper-en-us-lessac-high](https://huggingface.co/Trelis/piper-en-us-lessac-high); Picovoice lists Piper at 61 MB, 37 languages — [Picovoice benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md)

**Kyutai Pocket TTS**
- 100M parameters; ~200 ms to first audio chunk; "~6x real-time on a CPU of MacBook Air M4"; uses only 2 CPU cores; languages English, French, German, Portuguese, Italian, Spanish, Dutch plus community models (Czech, Hindi, Korean, Persian, Indonesian, Estonian, Welsh, Polish, Greek); 24 pre-made voices stored as safetensors embeddings; cloning from a plain WAV; ports: WebAssembly (Rust, JAX-JS, ONNX), Android (ToBe SAID, Pocket-TTS-LiteRT), iOS/macOS, Rust/candle, sherpa-onnx; code MIT — [kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts)
- Weights: CC-BY-4.0 (snippet; stated by ONNX/GGUF re-uploaders) — [Vincweb/pocket-tts-english-onnx](https://huggingface.co/Vincweb/pocket-tts-english-onnx); [rleo/pocket-tts-GGUF](https://huggingface.co/rleo/pocket-tts-GGUF); Kyutai terms of use: no voice impersonation or cloning without consent, no deceptive content (snippet) — [agentwiki Pocket TTS](https://agentwiki.org/pocket_tts_kyutai)
- Release cadence: v2.0.0 Apr 21 2026 (Italian/German/Spanish/Portuguese/French, quantization ~30% faster), v2.1.0 May 4 2026, v3.0.0 Aug 25 2026 (training code, 24-layer English variant), v3.1.0 Sep 3 2026, v3.2.0 Sep 23 2026 ("english_2026-09: robustness fine-tune"), v3.3.0 Sep 24 2026 — [pocket-tts releases](https://github.com/kyutai-labs/pocket-tts/releases)
- Architecture (snippet): Continuous Audio Language Model (CALM) processing text and audio in parallel — [nahornyi.ai](https://nahornyi.ai/en/news/kyutai-pocket-tts-open-source-lightweight-tts); Picovoice lists Pocket-TTS at 242 MB, English only (at benchmark time) — [Picovoice benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md)
- Quality (snippet): Kyutai retrained PocketTTS with a one-step "drifting" objective "hitting 0.90% WER on LibriSpeech test-clean" — [alphasignal](https://alphasignal.ai/news/kyutai-retrains-pockettts-with-simpler-loss-hitting-0-90-word-error-rate)

**NeuTTS (Neuphonic)**
- NeuTTS-Air ~360M active params (~552M with embeddings), Apache 2.0; NeuTTS-Nano ~120M active (~229M with embeddings) and NeuTTS-2E ~125M active, both under "NeuTTS Open License 1.0"; NeuCodec at 50 Hz single codebook; cloning from "as little as 3 seconds"; every output carries a Perth watermark by default; Galaxy A25 5G CPU: Nano 45 tokens/s, Air 20 tokens/s — [neuphonic/neutts](https://github.com/neuphonic/neutts)
- Air GGUF sizes: Q4 ~400–600 MB, Q8 ~800 MB, BF16 1.5 GB (snippet) — [neuphonic/neutts-air-q4-gguf](https://huggingface.co/neuphonic/neutts-air-q4-gguf); originally announced as a 748M-param Qwen2-architecture model (Oct 2025) — [MarkTechPost](https://www.marktechpost.com/2025/10/02/neuphonic-open-sources-neutts-air-a-748m-parameter-on-device-speech-language-model-with-instant-voice-cloning/)

**Soprano (ekwek1)**
- 80M params, Apache-2.0, LLM-based with Vocos vocoder, English only, single voice, no cloning; CPU "up to 20x real-time" with "<250 ms latency"; 32 kHz; "trained on only 1,000 hours of audio"; v1.1-80M Jan 14 2026 — [ekwek1/soprano](https://github.com/ekwek1/soprano)

**LuxTTS (ysharma3501)**
- Apache-2.0; ZipVoice-based, distilled to 4 steps, custom 48 kHz vocoder; cloning from ≥3 s reference; "150x realtime" on GPU, faster than real time on CPU; no built-in voices; params and training data not disclosed — [ysharma3501/LuxTTS](https://github.com/ysharma3501/LuxTTS)

**ZipVoice (k2-fsa)**
- 123M params flow-matching zero-shot TTS, Chinese+English, Apache-2.0, Vocos vocoder, ONNX + sherpa-onnx deployment; released Jun 16 2025; ZipVoice-Distill variant — [k2-fsa/ZipVoice](https://github.com/k2-fsa/ZipVoice)

**MOSS-TTS-Nano (OpenMOSS)**
- ~0.1B params, Apache-2.0 code and weights, multilingual voice cloning, "realtime generation on just 4 CPU cores", announced April 13 2026; no predefined voice library — [OpenMOSS/MOSS-TTS](https://github.com/OpenMOSS/MOSS-TTS)

**Matcha-TTS**
- Conditional flow-matching acoustic model + HiFi-GAN vocoder, MIT, trained on LJ Speech (public-domain texts, single female speaker) — [shivammehta25/Matcha-TTS](https://github.com/shivammehta25/Matcha-TTS); [Matcha-TTS paper](https://arxiv.org/html/2309.03199v2); sherpa-onnx matcha-icefall-en_US-ljspeech is 71 MB, APK 143 MB, RTF 0.941/0.561/0.451/0.411 at 1/2/3/4 threads (snippet, hardware unspecified) — [deepwiki sherpa TTS models](https://deepwiki.com/k2-fsa/sherpa/3.2-tts-models); [csukuangfj/sherpa-onnx-apk](https://huggingface.co/csukuangfj/sherpa-onnx-apk)

**MeloTTS (MyShell)**
- MIT, "free for both commercial and non-commercial use"; English accents American/British/Indian/Australian/Default; "CPU real-time inference" — [myshell-ai/MeloTTS](https://github.com/myshell-ai/MeloTTS); English model components (Qualcomm AI Hub export): BERT wrapper 360 MB, decoder 55.5 MB, encoder 31.8 MB, flow 76.9 MB, plus T5 parts (snippet) — [Qualcomm AI Hub MeloTTS-EN](https://aihub.qualcomm.com/models/melotts_en)

**StyleTTS 2 / VITS / VITS2**
- StyleTTS 2 code MIT; "surpasses human recordings on LJSpeech" and LibriTTS zero-shot; the pip package notes inference "depends on a GPL-licensed package, though a fully MIT-licensed package using gruut is also available" (snippet) — [yl4579/StyleTTS2](https://github.com/yl4579/styletts2); [styletts2 on PyPI](https://pypi.org/project/styletts2/)
- VITS is the architecture behind Piper and MeloTTS; sherpa-onnx groups "VITS: Fast, high-quality TTS (Piper, Coqui, MeloTTS, MMS)" (snippet) — [react-native-sherpa-onnx](https://github.com/XDcobra/react-native-sherpa-onnx)

**Larger / out-of-budget or license-blocked models (size check)**
- Chatterbox (Resemble): 0.5B, MIT, 23 languages (snippet) — [offlinetts leaderboard](https://www.offlinetts.com/blog/tts-arena-leaderboard-2026/); Chatterbox Turbo: 350M params, English, MIT, "75ms latency and runs 6x real-time" on a modern GPU — [Resemble Chatterbox Turbo](https://www.resemble.ai/chatterbox-turbo/)
- Dia (Nari Labs): 1.6B, Apache 2.0 — [Modal open-source TTS roundup](https://modal.com/blog/open-source-tts)
- Orpheus (Canopy Labs): 3B Llama-based, Apache 2.0, March 2025; 1B/400M/150M sizes are on the README checklist, with a transformers.js issue tracking the promised 150M "nano" — [canopyai/Orpheus-TTS](https://github.com/canopyai/Orpheus-TTS); [transformers.js issue #1252](https://github.com/huggingface/transformers.js/issues/1252); as of mid-2026 "treat the smaller sizes as announced, not yet your daily driver" (snippet) — [localaimaster Orpheus guide](https://localaimaster.com/blog/orpheus-tts-setup-guide)
- OuteTTS 1.0: Llama-OuteTTS-1.0-1B and OuteTTS-1.0-0.6B, license CC-BY-NC-SA-4.0 (snippet) — [OuteAI blog](https://outeai.com/blog/outetts-1-0-release); [promptlayer](https://www.promptlayer.com/models/llama-outetts-10-1b/)
- Zonos (Zyphra): 1.6B, Apache-2.0, GPU required (snippet) — [clore.ai Zonos guide](https://docs.clore.ai/guides/audio-and-voice/zonos-tts) (one roundup says 0.4B — [pinggy roundup](https://pinggy.io/blog/best_open_source_self_hosted_text_to_speech_models/); the 1.6B figure matches Zyphra's own release and should be preferred)
- VibeVoice-Realtime-0.5B (Microsoft): 0.5B, MIT, ~300 ms first audible latency, released Dec 3 2025, 11 English style voices plus 9-language experimental voices, "intended for research and development purposes only" — [microsoft/VibeVoice](https://github.com/microsoft/VibeVoice)
- Qwen3-TTS 0.6B (Alibaba, Jan 22 2026): Apache 2.0; 1.81 GB bf16 safetensors + 0.68 GB codec; no official CPU path as of Aug 2026 (snippet) — [Simon Willison](https://simonwillison.net/2026/Jan/22/qwen3-tts/); [Medium long-form TTS](https://medium.com/data-science-collective/high-quality-long-form-tts-with-qwen3-open-weight-models-cdd6e3d00df0)
- Fish Audio OpenAudio S1-mini: 0.5B, cc-by-nc-sa-4.0 (snippet) — [fishaudio/s1-mini](https://huggingface.co/fishaudio/s1-mini)
- Voxtral TTS (Mistral, Mar 26 2026): 4B params, open weights, 9 languages (snippet) — [VentureBeat](https://venturebeat.com/orchestration/mistral-ai-just-released-a-text-to-speech-model-it-says-beats-elevenlabs-and)
- Kyutai TTS 1.6B / 0.75B (the non-pocket models): weights CC-BY-4.0 (snippet) — [kyutai/tts-0.75b-en-public](https://huggingface.co/kyutai/tts-0.75b-en-public)

**Apple / Google**
- No open-weights on-device TTS release from Google or Apple surfaced in 2026 searches; Google's litert-community hosts third-party conversions (Kokoro-82M, Matcha-TTS) rather than its own TTS model (snippet) — [litert-community/Kokoro-82M](https://huggingface.co/litert-community/Kokoro-82M); [litert-community/Matcha-TTS](https://huggingface.co/litert-community/Matcha-TTS)

### Inferences
- The field split in 2025–26 into (a) tiny non-autoregressive models (Piper/VITS, Kokoro/StyleTTS2, Supertonic, Kitten small, Matcha) that are 15–100M params and 20–340 MB, and (b) small speech-LMs (Pocket TTS, MOSS-TTS-Nano, NeuTTS-Nano, Soprano) that add voice cloning and streaming at 80–230M params. Only group (a) plus Pocket TTS and Soprano currently have mobile deployments documented.
- Supertonic's archival in Sept 2026 and OHF's call for Piper maintainers mean two of the three fastest small models are now in maintenance-risk territory; Kokoro's Python package has not released since April 2025 even though its ecosystem (sherpa-onnx, kokoro-onnx) is active.

### Gaps
- Could not open the Kokoro-82M, Supertonic, Pocket TTS, or KittenTTS Hugging Face model cards (host blocked), so the verbatim training-data statements, the exact voice list, and the OpenRAIL-M "Attachment A" use restrictions for Supertonic are not quoted here; the Supertonic GitHub LICENSE is only the MIT code license.
- Exact sherpa-onnx archive sizes per model (release `tts-models` assets) could not be listed: the GitHub API was gated for this session and the docs host was blocked.
- No training-data statement was found for Supertonic, KittenTTS, Pocket TTS, MOSS-TTS-Nano, LuxTTS or NeuTTS in the sources reached.

## Key Question 1: Which models produce "good enough for a kids' game" English on a phone CPU with sub-second time-to-first-audio, and what is the evidence?

### Takeaway
Measured phone numbers exist mainly for Kokoro (Pixel 8a RTF ≈0.6; Galaxy S24 Ultra first-audio 1.25 s on CPU, 0.78 s with the Qualcomm NPU) and for Supertonic (RTF 0.3 on a low-end Android e-reader), while Pocket TTS and KittenTTS have CPU-desktop latency claims (~200 ms, "realtime") and Android ports but no published phone RTFs; Kokoro and Supertonic are the only small models with arena/WER quality evidence, so Supertonic 3 (fastest) and Kokoro (best-rated) are the two with both quality and speed evidence, with Kokoro's first-audio latency on CPU being borderline for "sub-second" on sentence-length prompts.

### Cited Findings
- Kokoro on Pixel 8a CPU: RTF 0.60 (3.9 s of audio in 2.4 s) (snippet) — [soniqo Kokoro Android guide](https://soniqo.audio/guides/kokoro/android); another measurement found fp32 CPU 4 threads RTF ≈1.8 (6.6 s to synthesize 3.7 s) with "quantization is the path to realtime" (snippet) — [zoe-ai-assistant PR #1715](https://github.com/jason-easyazz/zoe-ai-assistant/pull/1715); Android emulator arm64 no NNAPI: 1,075 ms inference, RTF 0.58 for 1.9 s output (snippet) — [soniqo Android benchmarks](https://soniqo.audio/benchmarks/android)
- Kokoro on Galaxy S24 Ultra (Snapdragon 8 Gen 3): first-PCM latency 1,252 ms with q8 CPU vs 779 ms with QNN HTP; generator RTF 0.31 after optimization (3.44x real-time); misaki/eSpeak 1.52 frontend; the APK is ~1.4–1.5 GB because it bundles 28 voices, QNN runtimes and 11 AOT contexts — [cedgeremek/kokoro-offline-tts-android](https://github.com/cedgeremek/kokoro-offline-tts-android)
- Kokoro-82M fp32 TFLite on Snapdragon 8 Elite Gen 5 NPU: median inference 1150 ms, load 3037 ms (snippet) — [litert-community/Kokoro-82M](https://huggingface.co/litert-community/Kokoro-82M)
- Kokoro on Raspberry Pi 4 (4 threads): RTF 3.19 (v1_0) and 2.77 (v0_19), i.e. slower than real time on that class of ARM CPU — [sherpa docs kokoro.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/kokoro.rst)
- Supertonic 3: "average RTF of 0.3× on Onyx Boox Go 6 e-reader" and a Raspberry Pi real-time demo; English WER 2.06 — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic); desktop CPU: Supertonic-3 2-step RTF mean 0.165 vs Kokoro-82M RTF 0.45–0.51 (snippet, vendor-adjacent blog) — [heyneo Kokoro vs Supertonic 3](https://heyneo.com/blog/kokoro-tts-vs-supertonic-3-tts)
- Pocket TTS: "~200ms to get the first audio chunk", "~6x real-time on a CPU of MacBook Air M4", 2 CPU cores; Android ports exist (ToBe SAID, Pocket-TTS-LiteRT) — [kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts)
- Soprano: CPU "<250 ms latency", "up to 20x real-time"; no mobile port listed — [ekwek1/soprano](https://github.com/ekwek1/soprano)
- NeuTTS on a budget phone (Galaxy A25 5G CPU): Nano 45 tokens/s, Air 20 tokens/s; at the 50 Hz codec rate that is ~0.9x and ~0.4x real-time respectively — [neuphonic/neutts](https://github.com/neuphonic/neutts)
- A GPL-3.0 Android system-TTS app that ships Piper/Kokoro/Kitten/Matcha/Supertonic/ZipVoice/Pocket voices through sherpa-onnx says "Synthesis is sub-second on a 2020+ phone" (no RTF table) — [HayaiTTS README](https://github.com/HayaiApp/HayaiTTS/tree/main)
- Picovoice (a competitor selling Orca) measured on a Ryzen 7 5700X desktop: first-token-to-speech latency Orca 106 ms, Piper 1,720 ms, Supertonic 2,612 ms, Kokoro 3,658 ms; peak memory Kokoro 2.0 GB, Piper 2.6 GB, Supertonic 450 MB (snippet) — [Picovoice on-device TTS comparison](https://picovoice.ai/blog/on-device-tts/); methodology: FTTS is measured from an LLM's first token, so engines that wait for a full sentence are penalized; models are Kokoro, Chatterbox-Turbo, Kitten-Nano, Pocket-TTS, Neu-TTS-Nano, Piper, Soprano, Supertonic-2, eSpeak-NG — [Picovoice benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md)
- Quality rankings (snippet, Aug 2026): Kokoro 82M v1.0 1,060 Elo, 6th among open-weight models; Chatterbox 1,020 Elo, 9th — [offlinetts TTS Arena leaderboard 2026](https://www.offlinetts.com/blog/tts-arena-leaderboard-2026/)
- Matcha-TTS (LJSpeech) RTF 0.41 at 4 threads in sherpa-onnx (snippet, hardware unstated) — [deepwiki sherpa TTS models](https://deepwiki.com/k2-fsa/sherpa/3.2-tts-models)

### Inferences
- For a math game, utterances are short (one sentence). With Kokoro at RTF ≈0.3–0.6 on a 2023–24 flagship CPU, a 2-second prompt costs 0.6–1.2 s before audio starts unless streamed by sentence chunk; Supertonic at RTF 0.3 on a low-end e-reader SoC should be comfortably sub-second on any 2020+ phone; Piper medium (15M params) is the safest bet for old tablets but has the lowest naturalness of the group.
- Pocket TTS's ~200 ms first-chunk figure is on an M4 laptop; scaling to a mid-range phone CPU (roughly 3–5x slower single-thread) suggests ~0.6–1 s, plausible but unmeasured (estimate).
- None of the small models has a published child-listener or kids-content MOS; "good enough" has to be judged by the developer's own listening tests on the target iPads.

### Gaps
- No published RTF or time-to-first-audio on an actual iPad/iPhone for any model surfaced; iOS evidence is limited to the existence of Supertonic Swift/iOS and sherpa-onnx iOS/Flutter builds.
- No phone-measured latency for Pocket TTS, KittenTTS or Soprano.
- The TTS Arena / Artificial Analysis leaderboards themselves could not be opened; Elo figures above are from a secondary summary and should be re-verified before publication.

## Key Question 2: How does on-disk size break down, and which models avoid the espeak-ng GPLv3 dependency?

### Takeaway
Across the small models the acoustic model dominates (Kokoro ~310–330 MB fp32 / ~80 MB int8 plus a 27 MB voice file and an espeak-ng-data folder; Piper 10–114 MB per voice; Kitten nano 25–56 MB; Supertonic 3 ~99M params in ONNX; Matcha 71 MB incl. HiFi-GAN), and the GPL risk comes entirely from the text frontend: Piper, Kitten and Kokoro's default pipelines link espeak-ng/phonemizer, while Pocket TTS, Soprano, MOSS-TTS-Nano, NeuTTS and (per its SDK design) Supertonic take raw text, and Kokoro can be run espeak-free only by restricting English to misaki's dictionary.

### Cited Findings
- Kokoro: sherpa-onnx v1_0 archive = ~310 MB model.onnx + voices.bin + tokens.txt + lexicon-us-en.txt/lexicon-zh.txt + espeak-ng-data directory + optional FST rule files; config flags `--kokoro-data-dir` (espeak-ng-data) and `--kokoro-lexicon` — [sherpa docs kokoro.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/kokoro.rst); kokoro-onnx "~300MB (quantized: ~80MB)" — [thewh1teagle/kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx); voices-v1.0.bin 27 MB (snippet) — [soniqo Kokoro Android guide](https://soniqo.audio/guides/kokoro/android)
- misaki (Kokoro's G2P) is Apache-licensed and dictionary-based; the espeak fallback is an optional extra install ("To fallback to espeak"), and "without fallback support, unfamiliar words would fail"; non-English misaki pipelines for ja/ko/zh/vi use language-specific tokenizers rather than espeak — [misaki on PyPI](https://pypi.org/project/misaki/); the kokoro package lists espeak-ng as "required for English fallback and some non-English languages" — [kokoro on PyPI](https://pypi.org/project/kokoro/)
- The GPL question has been raised directly to the Kokoro maintainer (issue asking whether Kokoro can run without espeak-ng and whether g2p-en alternatives are supported); no maintainer answer was visible in the fetched page — [hexgrad/kokoro issue #247](https://github.com/hexgrad/kokoro/issues/247)
- Downstream projects have hit the conflict: "kokoro-onnx pulls in phonemizer (GPLv3+), a real licence conflict" — [askwell issue #619](https://github.com/Rumeasiyan/askwell/issues/619); "piper-phonemize/espeak-ng (GPL-3.0) forces the bundled installer under GPL terms" — [nox issue #21](https://github.com/Crackxsy/nox/issues/21)
- Piper: the successor repo is GPL-3.0 because it "embeds espeak-ng for phonemization" — [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl); "piper-phonemize is linked with the espeak-ng library which has the GPL license, meaning piper-phonemize is also under the GPL license when distributed" (snippet) — [rhasspy/piper-phonemize issue #17](https://github.com/rhasspy/piper-phonemize/issues/17)
- Piper voice sizes: high ≈114 MB, medium ≈63 MB, low ≈20 MB, x_low ≈10 MB (snippet) — [Trelis/piper-en-us-lessac-high](https://huggingface.co/Trelis/piper-en-us-lessac-high)
- KittenTTS small models: nano 56 MB / 25 MB int8, micro 41 MB, mini 80 MB — [KittenTTS README (raw)](https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md); its pipeline phonemizes via eSpeak (WASM in the browser port) (snippet) — [codeandlife KittenTTS browser port](https://codeandlife.com/2026/02/26/kittentts-browser-port-with-codex/)
- Matcha-TTS: acoustic model + HiFi-GAN vocoder; the sherpa-onnx LJSpeech package is 71 MB and the APK 143 MB (snippet) — [deepwiki sherpa TTS models](https://deepwiki.com/k2-fsa/sherpa/3.2-tts-models); [csukuangfj/sherpa-onnx-apk](https://huggingface.co/csukuangfj/sherpa-onnx-apk)
- MeloTTS English breakdown (Qualcomm export): BERT wrapper 360 MB, decoder 55.5 MB, encoder 31.8 MB, flow 76.9 MB, T5 decoder 21.8 MB, T5 encoder 57.5 MB (snippet) — [Qualcomm AI Hub MeloTTS-EN](https://aihub.qualcomm.com/models/melotts_en)
- Supertonic: ONNX models (OnnxSlim-optimized), 44.1 kHz native output with "no upsampler required"; Picovoice lists Supertonic-TTS-2 at 262 MB — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic); [Picovoice benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md)
- Pocket TTS: Picovoice lists 242 MB; the project takes plain text and lists no phonemizer dependency — [Picovoice benchmark README](https://github.com/Picovoice/text-to-speech-benchmark/blob/main/README.md); [kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts)
- Soprano: documentation suggests converting numbers/special characters to phonetic spelling manually rather than using an automatic phonemizer — [ekwek1/soprano](https://github.com/ekwek1/soprano)
- Permissive espeak replacements: piper-plus-g2p (Rust, MIT, "eSpeak-ng free") — [piper-plus-g2p on crates.io](https://crates.io/crates/piper-plus-g2p); OpenPhonemizer (BSD-3-Clause Clear, DeepPhonemizer-based, "drop-in replacement for espeak's GPL phonemizer") — [OpenPhonemizer](https://github.com/strjoedfuva-web/OpenPhonemizer); piper-without-espeak (English-only fork kept MIT) — [gudrob/piper-without-espeak](https://github.com/gudrob/piper-without-espeak); StyleTTS2 pip package offers "a fully MIT-licensed package using gruut" (snippet) — [styletts2 on PyPI](https://pypi.org/project/styletts2/)
- A shipped Android Kokoro app lists its bundled licenses as Kokoro/Misaki Apache-2.0, ONNX Runtime MIT, "eSpeak NG (GPL-3.0-or-later)" — [cedgeremek/kokoro-offline-tts-android](https://github.com/cedgeremek/kokoro-offline-tts-android)

### Inferences
- For Math City the text domain is closed (numbers, operators, a few hundred UI strings), so Kokoro's misaki dictionary alone, or a precomputed phoneme table generated offline with espeak-ng (GPL obligations attach to distributing espeak-ng, not to data produced by running it), would avoid shipping GPL code. This is an inference about licensing practice, not legal advice, and the Kokoro maintainer's position on it could not be confirmed.
- Kokoro int8 (~80 MB) + voices (27 MB) + lexicon fits the ~100 MB target; Piper medium (63 MB) fits too but at GPL cost for the frontend; Kitten nano int8 (25 MB) is the only option under 50 MB that is Apache-licensed end to end if the espeak step is replaced.
- Since Math City is itself open source, the GPL frontend is not necessarily fatal for the project's own distribution; the stated concern (app-store "commercial-use risk") is about non-commercial clauses, which GPL does not have. The actual GPL hazard is App Store distribution terms and any closed-source dependencies, which is a separate decision.

### Gaps
- Could not verify Supertonic's text frontend from its README (no statement of grapheme vs phoneme input found), so "no espeak" for Supertonic is inferred from the absence of any such dependency in its multi-language SDK list, not stated.
- Exact sherpa-onnx int8 Kokoro archive size and the size of espeak-ng-data in it were not obtainable (docs host blocked, release API gated).

## Key Question 3: Which ship multiple voices, and does adding voices cost model size?

### Takeaway
Kokoro (53–103 speakers), Supertonic (6 preset styles, reportedly ~10 speakers per language in bundles), Pocket TTS (24 premade voices) and KittenTTS (8 voices) represent voices as small embedding/style vectors or JSON profiles, so extra voices cost kilobytes; Piper, Matcha and MeloTTS are one-model-per-voice (or per small multi-speaker set), so each voice is another 10–114 MB file.

### Cited Findings
- Kokoro: sherpa-onnx archives bundle a single `voices.bin` of speaker embeddings covering 53 (v1_0) or 103 (v1_1) speakers alongside one model.onnx — [sherpa docs kokoro.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/kokoro.rst); the whole voice file is 27 MB for 54 voices (snippet) — [soniqo Kokoro Android guide](https://soniqo.audio/guides/kokoro/android)
- Supertonic: 6 preset voice styles (M3, M4, M5, F3, F4, F5) plus earlier styles, and Voice Builder "permanent custom voice profile" JSON files — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic); third-party bundle description "30 languages × 10 speakers in one bundle" — [HayaiTTS README](https://github.com/HayaiApp/HayaiTTS/tree/main)
- Pocket TTS: 24 pre-made voices stored as safetensors embeddings, plus cloning from a WAV, with per-language default voices added in v2.1.0 — [kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts); [pocket-tts releases](https://github.com/kyutai-labs/pocket-tts/releases)
- KittenTTS small models: 8 voices (4 male, 4 female) selected as a "voice style vector from the loaded embeddings" (snippet) — [KittenML/kitten-tts-nano-0.8-int8](https://huggingface.co/KittenML/kitten-tts-nano-0.8-int8); [codeandlife browser port](https://codeandlife.com/2026/02/26/kittentts-browser-port-with-codex/); KittenTTS 2 (1.7B) has 47 voices — [KittenTTS README (raw)](https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md)
- Piper: two files per voice (.onnx + .onnx.json), 43 languages; each voice is a separate VITS export of 10–114 MB — [piper1-gpl VOICES.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md); [Trelis/piper-en-us-lessac-high](https://huggingface.co/Trelis/piper-en-us-lessac-high)
- Matcha-TTS in sherpa-onnx is a single LJSpeech female voice with a vocoder "trained on a single female voice" (snippet) — [deepwiki sherpa TTS models](https://deepwiki.com/k2-fsa/sherpa/3.2-tts-models)
- MeloTTS English offers five accents in one model (American, British, Indian, Australian, Default) — [myshell-ai/MeloTTS](https://github.com/myshell-ai/MeloTTS)
- Soprano: single voice, no cloning — [ekwek1/soprano](https://github.com/ekwek1/soprano); VibeVoice-Realtime-0.5B: 11 English style voices — [microsoft/VibeVoice](https://github.com/microsoft/VibeVoice)
- A Kokoro Android app bundling 28 voices still weighs ~1.4 GiB, but attributes the size to QNN runtimes and 11 AOT-compiled contexts, not the voices — [cedgeremek/kokoro-offline-tts-android](https://github.com/cedgeremek/kokoro-offline-tts-android)

### Inferences
- Kokoro's 27 MB / 54 voices ≈ 0.5 MB per voice; Pocket TTS and Kitten voice embeddings are likely smaller still (estimate); so a game could offer a voice picker at negligible cost with Kokoro, Pocket TTS, Kitten or Supertonic, but would pay 60–110 MB per additional Piper voice.

### Gaps
- Exact byte sizes of Supertonic style files, Pocket TTS voice safetensors and Kitten voice embeddings were not found.

## Key Question 4: Which support zero-shot cloning from a short sample at this size class, and what is the trade-off?

### Takeaway
At ≤~250M parameters, zero-shot cloning is offered by Pocket TTS (any WAV), MOSS-TTS-Nano, ZipVoice/LuxTTS (≥3 s), NeuTTS-Nano (3 s, watermarked, custom license) and KittenTTS 2 (5–30 s, but 1.7B params); the trade-off is that these are speech-LM/flow models with higher memory and latency than Kokoro/Piper/Supertonic, none of which clone, and cloning brings consent/impersonation clauses in Kyutai's and Neuphonic's terms.

### Cited Findings
- Pocket TTS: "plain wav file as input for voice cloning" or exported safetensors embeddings; "Audio quality of the sample is reproduced", cleaning recommended; prohibited-use clause forbids "voice impersonation or cloning without explicit and lawful consent" — [kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts)
- MOSS-TTS-Nano: ~0.1B params with multilingual voice cloning, Apache-2.0, real time on 4 CPU cores — [OpenMOSS/MOSS-TTS](https://github.com/OpenMOSS/MOSS-TTS)
- ZipVoice: 123M params, zero-shot cloning, Chinese+English, Apache-2.0, sherpa-onnx integration — [k2-fsa/ZipVoice](https://github.com/k2-fsa/ZipVoice); LuxTTS (ZipVoice-based) clones from ≥3 s and outputs 48 kHz — [ysharma3501/LuxTTS](https://github.com/ysharma3501/LuxTTS)
- NeuTTS: cloning from "as little as 3 seconds"; every output carries a Perth watermark by default; Nano/2E are under "NeuTTS Open License 1.0" rather than Apache — [neuphonic/neutts](https://github.com/neuphonic/neutts)
- KittenTTS 2: voice cloning from "5-30 seconds of audio", speaker similarity 0.81 on an unseen speaker, but 1.7B params / 506–947 MiB — [KittenTTS README (raw)](https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md)
- No cloning: Kokoro (voice-embedding library only — misaki/StyleTTS2 lineage, no reference-audio path in the README) — [hexgrad/kokoro README](https://github.com/hexgrad/kokoro); Soprano "does not support voice cloning" — [ekwek1/soprano](https://github.com/ekwek1/soprano); Supertonic used a now-closed Voice Builder service instead of in-model cloning — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)
- Chatterbox Turbo (350M) clones zero-shot but its stated speed figures are GPU-based — [Resemble Chatterbox Turbo](https://www.resemble.ai/chatterbox-turbo/)
- Picovoice's desktop memory figures show the cost of the larger designs: Kokoro 2.0 GB and Piper 2.6 GB peak RAM in their Python harness vs Supertonic 450 MB (snippet) — [Picovoice on-device TTS comparison](https://picovoice.ai/blog/on-device-tts/)

### Inferences
- For a kids' game, cloning is mainly useful to create a distinctive narrator voice from a consenting voice actor; Pocket TTS is the only cloning model with permissive weights (CC-BY-4.0), an active release train and documented Android/iOS ports, so it is the natural candidate if cloning matters; otherwise a non-cloning model avoids the consent clauses entirely.

### Gaps
- No published speaker-similarity or MOS comparisons between cloned and preset voices for Pocket TTS or MOSS-TTS-Nano were found.

## Key Question 5: Which have child or young-sounding voices under an acceptable license?

### Takeaway
No model in this size class advertises a child voice: Kokoro, Piper, Kitten, Supertonic and Pocket TTS voice lists are adult male/female, and the only openly licensed children's speech corpora found (e.g., MyST) are ASR corpora, not TTS-ready; a young-sounding narrator would have to come from a cloning model plus a consenting child or child-sounding adult voice actor.

### Cited Findings
- Piper VOICES.md names no child or young voice and warns some voices "may have restrictive licenses" — [piper1-gpl VOICES.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md)
- Supertonic's documented presets are M3/M4/M5/F3/F4/F5 — adult male/female labels — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)
- KittenTTS small models list 8 adult-named voices (snippet) — [KittenML/kitten-tts-nano-0.8-int8](https://huggingface.co/KittenML/kitten-tts-nano-0.8-int8)
- Pocket TTS lists 24 named premade voices with samples (no age descriptors) — [kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts)
- The MyST Children's Speech Corpus (393 h, grades 3–5) and the CHILDES-Aligned dataset are children's speech resources, but presented for ASR research (snippet) — [CHILDES-Aligned (arXiv)](https://arxiv.org/pdf/2607.03670)
- VCTK is CC-BY-4.0 and LJSpeech is public domain — common permissive TTS datasets, adult speakers (snippet) — [free-voice-clone list](https://github.com/0xSojalSec/free-voice-clone)

### Inferences
- Kokoro's 54-voice set is the best place to look for a lighter/younger-timbred adult voice without any cloning, but this is a listening judgement, not documented.

### Gaps
- No open-weights TTS model with a labelled child voice, and no CC-BY/CC0 child TTS dataset, was found; a dedicated search of HF voice packs (blocked) might still turn one up.

## Key Question 6: Licensing traps — code vs weights vs training data, GPL phonemizers, cloned voices

### Takeaway
The traps that matter here are: Supertonic's weights are OpenRAIL-M (use-restricted, not OSI) under MIT code; KittenTTS 2 and NeuTTS-Nano use custom "community/open" licenses with commercial registration or revenue limits; OuteTTS 1.0 and Fish S1-mini are CC-BY-NC-SA; VibeVoice is MIT but labelled research-only; Pocket TTS's CC-BY-4.0 weights carry Kyutai's no-impersonation terms; Piper, Kitten and default Kokoro pipelines pull GPL-3.0 espeak-ng/phonemizer; and almost no small model publishes a training-data provenance statement.

### Cited Findings
- Supertonic: MIT code, model under "OpenRAIL-M License" (`license: openrail` on HF) — [Supertone/supertonic HF README](https://huggingface.co/Supertone/supertonic/blob/main/README.md); [supertonic LICENSE (MIT, code)](https://github.com/supertone-oss-archive/supertonic/blob/main/LICENSE)
- KittenTTS: Apache-2.0 code; "models are licensed separately and their terms may differ"; KittenTTS 2 under the Stellon Labs Community License — [KittenTTS README (raw)](https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md); under that license "commercial use requires registration" and "exceeding its revenue or funding limits requires a separate license" (snippet) — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS); the small nano model is tagged apache-2.0 (snippet) — [KittenML/kitten-tts-nano-0.8-int8](https://huggingface.co/KittenML/kitten-tts-nano-0.8-int8); but the code depends on GPL-3.0 phonemizer (snippet) — [HN thread](https://news.ycombinator.com/item?id=44809541)
- NeuTTS: Air Apache 2.0; Nano and 2E "NeuTTS Open License 1.0"; all output watermarked — [neuphonic/neutts](https://github.com/neuphonic/neutts)
- Pocket TTS: MIT code — [kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts); weights CC-BY-4.0 (snippet) — [Vincweb/pocket-tts-english-onnx](https://huggingface.co/Vincweb/pocket-tts-english-onnx); terms: no impersonation/cloning without consent, no deceptive content (snippet) — [agentwiki Pocket TTS](https://agentwiki.org/pocket_tts_kyutai)
- Kokoro: Apache-2.0 weights and code, training data described only as contributed "synthetic training data" — [hexgrad/kokoro README](https://github.com/hexgrad/kokoro); [kokoro on PyPI](https://pypi.org/project/kokoro/)
- Piper: GPL-3.0 code (espeak-ng embedded) — [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl); per-voice MODEL_CARD licenses vary and "Piper is intended for personal use and text to speech research only... Some voices may have restrictive licenses" — [piper1-gpl VOICES.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md); lessac-high voice tagged MIT (snippet) — [Trelis/piper-en-us-lessac-high](https://huggingface.co/Trelis/piper-en-us-lessac-high)
- OuteTTS 1.0: CC-BY-NC-SA-4.0 (snippet) — [promptlayer Llama-OuteTTS-1.0-1B](https://www.promptlayer.com/models/llama-outetts-10-1b/); Fish S1-mini: cc-by-nc-sa-4.0 (snippet) — [fishaudio/s1-mini](https://huggingface.co/fishaudio/s1-mini)
- VibeVoice: MIT, but "This model is intended for research and development purposes only" with a deepfake warning — [microsoft/VibeVoice](https://github.com/microsoft/VibeVoice)
- Soprano: Apache-2.0, "trained on only 1,000 hours of audio" (source of audio unstated) — [ekwek1/soprano](https://github.com/ekwek1/soprano)
- Matcha-TTS: MIT code, trained on LJ Speech (public-domain texts, single speaker) — [shivammehta25/Matcha-TTS](https://github.com/shivammehta25/Matcha-TTS); [Matcha-TTS paper](https://arxiv.org/html/2309.03199v2)
- MeloTTS: MIT, "free for both commercial and non-commercial use" — [myshell-ai/MeloTTS](https://github.com/myshell-ai/MeloTTS)
- sherpa-onnx runtime: Apache-2.0 — [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx); but Android apps built on it list "Individual voice licenses vary... (most are MIT or Apache-2.0)" — [HayaiTTS README](https://github.com/HayaiApp/HayaiTTS/tree/main)
- Downstream license conflicts were filed in real projects over kokoro-onnx → phonemizer (GPLv3+) and piper-phonemize → espeak-ng (GPL-3.0) — [askwell issue #619](https://github.com/Rumeasiyan/askwell/issues/619); [nox issue #21](https://github.com/Crackxsy/nox/issues/21)

### Inferences
- Models that are clean on all three axes (permissive code, permissive weights, no GPL frontend) with a documented mobile path: Pocket TTS (CC-BY-4.0 weights require attribution in the app), MOSS-TTS-Nano (Apache, but no documented mobile port), Soprano (Apache, no mobile port), ZipVoice/LuxTTS (Apache). Kokoro becomes clean if the espeak fallback is dropped. Supertonic's OpenRAIL-M is use-restricted but not non-commercial; whether its restrictions are acceptable needs the actual license text (blocked here).
- Training-data provenance is the weakest documentation area across the board; only Matcha (LJSpeech) and Piper (per-voice cards) name their corpora, and Kokoro only characterises its data as synthetic.

### Gaps
- OpenRAIL-M Attachment A restrictions for Supertonic, the Stellon Labs Community License revenue thresholds, and the NeuTTS Open License 1.0 text were not readable (hosts blocked); the report should flag these as "read before adopting".
- No source confirmed whether Kokoro's or Supertonic's voices derive from identifiable real people with consent.

## Key Question 7: Maintenance — active vs abandoned in 2026, and the sherpa-onnx deployment umbrella

### Takeaway
Active in 2026: Kyutai Pocket TTS (six releases Apr–Sep 2026), sherpa-onnx (Apache-2.0, packages VITS/Piper, MeloTTS, MMS, Matcha, Kokoro, Kitten, ZipVoice, Pocket TTS and Supertonic for Android/iOS/Flutter), KittenTTS (KittenTTS 2 release), NeuTTS (Nano family), MOSS-TTS (Nano, Apr 2026), Soprano (Jan 2026), LuxTTS. Archived or at risk: Supertonic (archived Sep 9 2026), rhasspy/piper (archived Oct 2025; OHF successor seeking maintainers), Kokoro's Python package (last release Apr 2025, though the model remains the most-deployed small model), Orpheus small checkpoints (never shipped).

### Cited Findings
- sherpa-onnx supports TTS model families Piper, Matcha, Kokoro, VITS, ZipVoice, Pocket TTS and Supertonic; platforms Android (pre-built APKs), iOS, Flutter (Android, iOS, Windows, macOS, Linux, Web), HarmonyOS, desktop; bindings include Dart and Swift; Apache-2.0 — [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx); a third party summarises it as "7 model families (VITS, Matcha, Kokoro, Kitten, Zipvoice, PocketTTS, Supertonic) across 80+ languages" (snippet) — [react-native-sherpa-onnx](https://github.com/XDcobra/react-native-sherpa-onnx)
- Shipping sherpa-onnx TTS apps on Android: HayaiTTS (GPL-3.0, 600+ voices over Piper/VITS/Matcha/Kokoro/Kitten/Supertonic/ZipVoice/Pocket) — [HayaiTTS README](https://github.com/HayaiApp/HayaiTTS/tree/main); VoxSherpa TTS (Kokoro-82M, offline) — [VoxSherpa-TTS](https://github.com/CodeBySonu95/VoxSherpa-TTS); Unity plugin — [Unity-Sherpa-ONNX](https://github.com/Ponyu-dev/Unity-Sherpa-ONNX)
- Pocket TTS release train: v2.0.0 (Apr 21 2026) through v3.3.0 (Sep 24 2026), including training code and quantization — [pocket-tts releases](https://github.com/kyutai-labs/pocket-tts/releases)
- Supertonic archived Sep 9 2026, "Development and support have ended" — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)
- Piper: original repo archived Oct 6 2025; successor GPL-3.0 with v1.4.2 (Apr 2026) and v1.6.0 (Jul 2026) (snippet) — [offlinetts self-hosted guide](https://offlinetts.com/blog/self-hosted-tts-guide-2026/); "looking for maintainers" — [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl)
- Kokoro PyPI last release 0.9.4, April 5 2025 — [kokoro on PyPI](https://pypi.org/project/kokoro/); kokoro-onnx active with 230 commits — [thewh1teagle/kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx)
- KittenTTS: 15.5k stars, recent activity, KittenTTS 2 released — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS)
- MOSS-TTS-Nano announced April 13 2026 — [OpenMOSS/MOSS-TTS](https://github.com/OpenMOSS/MOSS-TTS); Soprano v1.1-80M Jan 14 2026 with roadmap for cloning and multilingual — [ekwek1/soprano](https://github.com/ekwek1/soprano); LuxTTS roadmap v1.5/float16 — [ysharma3501/LuxTTS](https://github.com/ysharma3501/LuxTTS)
- Orpheus 1B/400M/150M remain roadmap items — [canopyai/Orpheus-TTS](https://github.com/canopyai/Orpheus-TTS); [transformers.js issue #1252](https://github.com/huggingface/transformers.js/issues/1252)
- MeloTTS repo shows 94 commits, 213 open issues, 20 PRs (activity level, not dates) — [myshell-ai/MeloTTS](https://github.com/myshell-ai/MeloTTS)
- Flutter specifically: sherpa-onnx lists Flutter support across Android/iOS/desktop/Web — [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx); Supertonic "Added Flutter SDK support with macOS compatibility" before archival — [supertone-oss-archive/supertonic](https://github.com/supertone-oss-archive/supertonic)

### Inferences
- For a Flutter app the lowest-risk integration path is sherpa-onnx's Dart binding, which decouples the model choice (Kokoro, Kitten, Matcha, Piper, Pocket TTS, Supertonic) from the runtime; Supertonic's own Flutter SDK is frozen with the archive.
- Supertonic's archive is not a code-rot problem (ONNX files keep working) but it means no fixes, no new voices, and the custom-voice tooling is gone, so it should be treated as a frozen asset if chosen.

### Gaps
- Release dates for sherpa-onnx's addition of Pocket TTS and Supertonic, and the current sherpa-onnx version, were not captured (docs host blocked).
- Whether OHF has found Piper maintainers, or announced a Piper 2 architecture, could not be determined from reachable sources.
