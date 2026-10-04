# Multi-voice TTS architecture: how models represent, switch, blend and clone voices (as of October 2026)

Research context: Math City needs a narrator plus ten named citizen voices, fully offline, in a free Flutter app that cannot ship CC-BY-NC / non-commercial models or datasets. Notes below are organised by key question. Numbers marked **(derived)** are arithmetic from cited facts; numbers marked **(estimate)** are my own approximations. Environment note: this session's egress proxy blocked huggingface.co, arxiv.org (and mirrors), support.apple.com, Wikipedia, LDC and several other primary sites; where a fact comes from a search-engine summary of such a page rather than the page itself, the citation is to the page but flagged "(via search summary)".

---

## KQ1. For each voice mechanism, what is the marginal cost of one more voice (bytes, RAM, inference time), and can voices switch per utterance without a reload?

### Takeaway
The cost of an extra voice depends almost entirely on *where the voice lives*: in a single-speaker model it is a whole model (~60–80 MB for Piper medium); in a speaker-ID table it is one embedding row (~1 KB for VITS/Piper); in a reference-embedding model it is a small vector or pack (~0.5 MB per Kokoro voice); in a zero-shot LLM/flow model it is a few seconds of audio plus a cached latent, but the model itself is 0.5–1.7B parameters; in a LoRA it is a few MB per adapter. Every mechanism except "one model per voice" switches voices per utterance with no reload, because the acoustic weights are shared.

### Cited Findings

**(1) Single-speaker models (one model per voice): Piper / VITS checkpoints**
- Piper voices are VITS models exported to ONNX; each voice is two files, a `.onnx` model and a `.onnx.json` config, and "both files are necessary to run a voice" — [piper1-gpl docs/VOICES.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md)
- Piper quality tiers: "Low: 16,000 Hz sample rate, smaller voice model; Medium: 22,050 Hz, smaller voice model; High: 22,050 Hz, larger voice model" — [rhasspy/piper TRAINING.md](https://github.com/rhasspy/piper/blob/master/TRAINING.md)
- `en_US-lessac-medium.onnx` is 63.2 MB; `en_US-libritts_r-medium.onnx` is 78.6 MB — [rhasspy/piper-voices lessac](https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx) and [libritts_r](https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx) (via search summary; HF blocked)
- sherpa-onnx's model table lists `vits-piper-en_US-libritts_r-medium` at 75 MB, RTF 0.790 on a Raspberry Pi 4 (1 thread, 22.05 kHz); the original (non-Piper) `vits-vctk` at 116 MB, RTF 6.079; `vits-ljs` (single speaker) at 109 MB, RTF 6.057 — [k2-fsa/sherpa docs vits.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/vits.rst)
- The original VITS VCTK recipe uses `hidden_channels: 192`, `gin_channels: 256` (speaker-embedding width), `n_speakers: 109`, 22,050 Hz — [jaywalnut310/vits configs/vctk_base.json](https://github.com/jaywalnut310/vits/blob/main/configs/vctk_base.json)
- The rhasspy/piper repository was archived (read-only) on 6 Oct 2025 under MIT; development moved to OHF-Voice/piper1-gpl — [rhasspy/piper](https://github.com/rhasspy/piper)
- Piper's new home states "Piper is intended for personal use and text to speech research only" and that "the MODEL_CARD file for each voice contains important licensing information" — [piper1-gpl docs/VOICES.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md)
- English Piper voices (en_US): amy, arctic, bryce, danny, hfc_female, hfc_male, joe, john, kathleen, kristin, kusal, l2arctic, lessac (low/medium/high), libritts (high), libritts_r (medium), ljspeech, norman, reza_ibrahim, ryan (low/medium/high), sam; (en_GB): alan, alba, aru, cori, jenny_dioco, northern_english_male, semaine, southern_english_female, vctk — [rhasspy/piper VOICES.md](https://github.com/rhasspy/piper/blob/master/VOICES.md)

**(2) Multi-speaker models with a speaker-ID lookup table**
- `vits-piper-en_US-libritts_r-medium` has 904 speakers; the speaker is chosen with an integer `--sid` (examples `--sid=109`, `--sid=900`); `vits-vctk` has 109 speakers (`sid` 0–108, default 0) — [sherpa vits.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/vits.rst); also [sherpa-onnx docs](https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models/vits.html) (via search summary)
- Piper multi-speaker training: the CSV becomes `utt1.wav|speaker_1|Text`, and "Piper automatically creates a speaker-to-ID mapping saved in the config file" — [piper1-gpl docs/TRAINING.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/TRAINING.md); older recipe: `--resume_from_single_speaker_checkpoint` is "much faster than training your multi-speaker model from scratch" — [rhasspy/piper TRAINING.md](https://github.com/rhasspy/piper/blob/master/TRAINING.md)
- A community Piper-v3 fork describes widening the speaker-embedding table `emb_g` to add speakers, keeping existing rows and initialising new rows "near the mean of trained rows rather than from random normal" — [CakeByVPBank/piper-v3-vietnamese-5speakers](https://huggingface.co/CakeByVPBank/piper-v3-vietnamese-5speakers) (via search summary)

**(3) Speaker-encoder / reference-embedding models (x-vector, ECAPA, GE2E, StyleTTS2/Kokoro, Tortoise)**
- Kokoro is an 82M-parameter model under Apache-2.0, covering American/British English, Spanish, French, Hindi, Italian, Japanese, Brazilian Portuguese and Mandarin; a voice is loaded as a PyTorch tensor (`torch.load('path/to/voice.pt')`) or by name (`voice='af_heart'`) — [hexgrad/kokoro](https://github.com/hexgrad/kokoro)
- In Kokoro's forward pass the reference style vector is split: `s = ref_s[:, 128:]` feeds the duration/prosody predictor and `ref_s[:, :128]` feeds the decoder, i.e. a 256-dim style vector = 128 acoustic + 128 prosodic — [hexgrad/kokoro model.py](https://github.com/hexgrad/kokoro/blob/main/kokoro/model.py)
- Kokoro voicepacks are `[510, 1, 256]` float32 tensors: "average styles per utterance length, with 510 possible lengths", indexed by phoneme-token count — [cstr/kokoro-voices-GGUF](https://huggingface.co/cstr/kokoro-voices-GGUF) and [voirs KOKORO_EXAMPLES.md](https://github.com/cool-japan/voirs/blob/master/examples/KOKORO_EXAMPLES.md) (via search summary)
- Kokoro v1.0: 8 languages, 54 voices; trained on "a few hundred hours" of permissive / public-domain audio for about 500 A100-80GB GPU-hours (~$600); published 27 Jan 2025 — [soniqo Kokoro guide](https://soniqo.audio/guides/kokoro), [codesota model card](https://www.codesota.com/model/kokoro-v1-0), [hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) (all via search summary)
- kokoro-onnx packaging: one `kokoro-v1.0.onnx` plus one `voices-v1.0.bin`; "Lightweight: ~300MB (quantized: ~80MB)"; "near real-time on macOS M1" — [thewh1teagle/kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx)
- Speaker-verification embedding widths used as TTS conditioning: ECAPA-TDNN 192-dim (original), x-vector 512-dim — [ECAPA vs x-vector in zero-shot TTS, arXiv 2506.20190](https://www.arxiv.org/pdf/2506.20190); [ECAPA-TDNN for multi-speaker TTS, arXiv 2203.10473](https://arxiv.org/pdf/2203.10473)
- GE2E d-vectors (Resemblyzer): 256-dim L2-normalised output from a 3-layer LSTM over 40-channel log-mel; the pretrained encoder is ~15–20 MB — [Resemblyzer evaluation paper](https://ceur-ws.org/Vol-4164/paper7.pdf), [GE2E implementation](https://github.com/gkv856/speaker_embedding_GE2E_loss)
- YourTTS uses the H/ASP speaker encoder (512-dim, trained on VoxCeleb2) and reports SECS 0.864, MOS 4.21, Sim-MOS 4.16 on VCTK zero-shot — [YourTTS, arXiv 2112.02418](https://arxiv.org/pdf/2112.02418)
- Tortoise "ingests reference clips by feeding them through individually through a small submodel that produces a point latent, then taking the mean"; `get_conditioning_latents()` returns `(autoregressive_latent, diffusion_latent)` which "can be stored in .pth pickle files for later use" — [tortoise-tts Advanced_Usage.md](https://github.com/neonbjb/tortoise-tts/blob/main/Advanced_Usage.md)
- XTTS represents a speaker as `gpt_cond_latent` + `speaker_embedding` from `get_conditioning_latents()`; "Voices can be cloned with a single audio file or multiple audio files, without any effect on the runtime"; docs recommend "cache for faster inference with same speaker" — [coqui-ai/TTS xtts.md](https://github.com/coqui-ai/TTS/blob/dev/docs/source/models/xtts.md)

**(4) In-context / zero-shot cloning in LLM-codec and flow-matching models**
- Chatterbox (Resemble AI): MIT; variants Chatterbox 500M (English), Chatterbox-Turbo 350M, Chatterbox-Nano 110M, Chatterbox-Multilingual V3 500M (23 languages); built-in Perth neural watermark that "survive[s] MP3 compression"; `exaggeration` 0–1 emotion control; reference clip "approximately 10 seconds" — [resemble-ai/chatterbox](https://github.com/resemble-ai/chatterbox). Vendor page: 0.5B Llama backbone, 500K hours of audio, cloning from 5 s, ~200 ms latency on strong hardware — [resemble.ai Chatterbox](https://www.resemble.ai/learn/models/chatterbox)
- Qwen3-TTS: Apache-2.0; 0.6B and 1.7B sizes; variants Base ("3-second rapid voice clone"), CustomVoice (9 premium timbres), VoiceDesign (voice from a natural-language description); 10 languages; speaker similarity 0.788–0.829; streaming latency as low as 97 ms; en WER 1.24 (1.7B) — [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS)
- CosyVoice 3: Apache-2.0; zero-shot from ~3 s prompts; RL variant speaker-similarity cosine 0.780 vs a human same-speaker cross-recording baseline of 0.755 — [CosyVoice 3 paper](https://arxiv.org/pdf/2505.17589), [Fun-CosyVoice3-0.5B-2512](https://huggingface.co/FunAudioLLM/Fun-CosyVoice3-0.5B-2512) (via search summary); CosyVoice conditions on x-vectors concatenated at the LM input — [CosyVoice paper](https://arxiv.org/pdf/2407.05407)
- F5-TTS: code MIT, but "the pre-trained models are licensed under the CC-BY-NC license due to the training data Emilia, which is an in-the-wild dataset" — [SWivid/F5-TTS](https://github.com/SWivid/F5-TTS); maintainers state the NC base "cannot be used commercially even after finetuning"; the commercial path is training from the `F5TTS_v1_Base`/`Small` config on licensable data — [F5-TTS discussion #997](https://github.com/SWivid/F5-TTS/discussions/997); OpenF5-TTS-Base is an Apache-2.0 retrain on permissive data but "still inferior to the official NC-licensed F5-TTS" — [mrfakename/OpenF5-TTS-Base](https://huggingface.co/mrfakename/OpenF5-TTS-Base) (via search summary)
- Fish Audio OpenAudio S1 / S1-mini: code Apache, "all model weights are released under CC-BY-NC-SA-4.0"; S1 (4B) is proprietary/API-only, S1-mini is 0.5B; cloning from 10–30 s — [fishaudio/s1-mini](https://huggingface.co/fishaudio/s1-mini), [fish-speech-s1](https://github.com/ai-audio/fish-speech-s1) (via search summary)
- Coqui XTTS-v2: Coqui Public Model License (CPML), non-commercial; 16 languages — [coqui-ai/TTS xtts.md](https://github.com/coqui-ai/TTS/blob/dev/docs/source/models/xtts.md); clones from ~6 s of reference, 15–30 s gives better timbre; Coqui shut its paid services in Dec 2023 so there is "no active pathway to a commercial license" — [promptquorum XTTS/CPML guide](https://www.promptquorum.com/power-local-llm/local-tts-voice-cloning-piper-coqui-xtts), [openspeech XTTS v2](https://www.openspeech.dev/models/xtts-v2) (secondary)
- Parler-TTS (voice from text description): Apache-2.0; trained on LibriTTS-R + MLS English with auto-generated speaker descriptions (gender, pitch, speaking rate, reverberation, noise) — [parler-tts/libritts-r-filtered-speaker-descriptions](https://huggingface.co/datasets/parler-tts/libritts-r-filtered-speaker-descriptions), [parler-tts-mini-multilingual](https://huggingface.co/parler-tts/parler-tts-mini-multilingual) (via search summary)
- KittenTTS: ONNX CPU models Nano 15M params (25–56 MiB), Micro 40M (41 MiB), Mini 80M (80 MiB), 8 built-in voices selected by name string; code Apache-2.0; the larger "KittenTTS 2" (1.7B, 506–947 MiB, 47 voices + cloning) is under a separate "Stellon Labs Community License" — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS)

**(5) Fine-tuning / LoRA per voice**
- Adapter-based speaker extension of a multi-speaker TTS: LoRA on the feed-forward layers ≈ 2.8M parameters, bottleneck adapters ≈ 2.4M, with "similar speech naturalness and speaker similarity" to full fine-tuning — [Adapter-based extension for new speakers, arXiv 2211.00585](https://ar5iv.labs.arxiv.org/html/2211.00585) (via search summary)
- Orpheus-3B LoRA: trainable params ~140M at r=64 vs ~24M at r=16 — [navyaai Orpheus tutorial](https://www.navyaai.com/blog/self-knowledge-distillation) (secondary blog)
- Unsloth supports fine-tuning Sesame CSM, Orpheus and other TTS models; "since TTS models are usually small, you can train them using 16-bit LoRA, or go with FFT"; suggested ranks 8–128 — [unsloth.ai/blog/tts](https://unsloth.ai/blog/tts) (via search summary)
- Piper fine-tuning: "highly recommended" to start from an existing checkpoint ("even if the checkpoint is from a different language"); trained on A6000 48 GB / RTX 3090 24 GB, "users have reported success with as little as 8GB of VRAM"; only medium-quality checkpoints supported without config changes; training code lives in a GPL repo — [piper1-gpl docs/TRAINING.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/TRAINING.md); ~2000 epochs from scratch, +1000 when fine-tuning — [rhasspy/piper TRAINING.md](https://github.com/rhasspy/piper/blob/master/TRAINING.md)

**(6) Platform engines** — see KQ6.

### Inferences
- **Marginal bytes per voice (derived):**
  - One-model-per-voice (Piper medium): ≈ 63–79 MB per voice (lessac-medium 63.2 MB; libritts_r-medium 78.6 MB) plus a few-KB JSON. Ten citizens + narrator as separate Piper models ≈ 700 MB — far too large for a kids' app.
  - Speaker-ID table (VITS/Piper): one row of `gin_channels=256` floats = **1,024 bytes fp32** per speaker; all 904 LibriTTS-R rows ≈ **0.9 MB**. Consistent with the 904-speaker libritts_r-medium model being only ~15 MB larger than the single-speaker lessac-medium (most of that difference is unrelated architectural/export variance, not the table).
  - Kokoro voice pack: 510 × 1 × 256 × 4 bytes = **522,240 bytes (~510 KiB / 0.52 MB)** fp32 per voice; ~261 KB if stored fp16; 54 voices ≈ 27.5 MB in total. This confirms the "~0.5 MB per voice" figure. Only one 256-float row is actually used per utterance.
  - Reference-embedding models generally: a GE2E d-vector is 256 floats (1 KB), an ECAPA vector 192 floats (768 B), an x-vector 512 floats (2 KB). Tortoise/XTTS latents are larger (tens–hundreds of KB; **estimate**, size not found in sources) but still trivial next to the model.
  - LoRA per voice: 2.4–2.8M params ≈ **5–11 MB** (fp16/fp32) for FastSpeech-class models; ~24M params ≈ 48 MB fp16 for an Orpheus-3B r=16 adapter — and the adapter is useless without the (multi-GB) base model.
- **RAM:** for every shared-weights mechanism, RAM is dominated by the one model (Kokoro ≈ 80 MB int8 / 300 MB fp32 weights; Piper medium ≈ 60–80 MB; Chatterbox 0.5B ≈ 1 GB fp16 **estimate**; Qwen3-TTS 1.7B ≈ 3.4 GB fp16 **estimate**). Voice vectors add kilobytes. One-model-per-voice costs one full model per *loaded* voice; keeping ten Piper sessions resident would be ~700 MB.
- **Inference time:** a speaker row or style vector is an input tensor, so switching voices costs nothing per utterance (zero reload) in Piper multi-speaker, Kokoro, StyleTTS2, Tortoise with cached latents, XTTS with cached latents. Zero-shot models pay an extra reference-encoding pass only when the reference changes (XTTS docs say reference count has no runtime effect once latents are cached). One-model-per-voice requires a session load (tens of MB from flash, hundreds of ms to seconds on a phone — **estimate**) unless all voices stay resident.
- **Speed class:** Piper medium runs faster than real time on a Raspberry Pi 4 single-threaded (RTF 0.79); the original VITS checkpoints (RTF ~6) are not mobile-viable. Kokoro is "near real-time" on an M1 in ONNX; 0.5B+ LLM-codec models are not realistic for fully-offline synthesis on a mid-range tablet in 2026 without heavy quantisation (**inference**).

### Gaps
- Could not fetch Hugging Face file trees, so exact byte sizes for the Kokoro `.pt` voice files and `voices-v1.0.bin`, and for Piper low/high/x_low `.onnx` files, are derived or from search summaries rather than read from the listings.
- The 82M Kokoro `.pth` size (~327 MB often quoted) could not be verified; only kokoro-onnx's "~300 MB / ~80 MB quantized" is cited.
- No source gave on-device (iOS/Android) RTF numbers for Kokoro or Chatterbox; "near real-time on M1" is the only cited speed figure for Kokoro.

---

## KQ2. How do voice-pack formats work in practice (Kokoro .pt/.bin, Piper .onnx+.json, sherpa-onnx speaker ids, Coqui speaker embeddings), and which let a developer create a new voice offline and ship it as a small file?

### Takeaway
Kokoro and Piper-multi-speaker are the two formats where a *new* voice is a small file (0.5 MB tensor, or a 1 KB embedding row), but neither ships public training code for easily minting an arbitrary new voice from scratch: Kokoro's practical route is blending existing packs; Piper's is fine-tuning a (GPL-licensed) training pipeline on your own recordings and exporting a whole new `.onnx`. Zero-shot models make voice creation trivial (a WAV) but the permissively licensed ones are too large for offline mobile.

### Cited Findings
- **Kokoro**: a voice is a `.pt` tensor loaded with `torch.load(...)`, or selected by name — [hexgrad/kokoro](https://github.com/hexgrad/kokoro); shape `[510, 1, 256]` float32, row chosen by token count — [cstr/kokoro-voices-GGUF](https://huggingface.co/cstr/kokoro-voices-GGUF) (via search summary); kokoro-onnx concatenates all voices into one `voices-v1.0.bin` beside `kokoro-v1.0.onnx` — [thewh1teagle/kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx); the 256-dim vector is consumed as 128 decoder + 128 prosody dims — [kokoro model.py](https://github.com/hexgrad/kokoro/blob/main/kokoro/model.py)
- Kokoro voice grades in VOICES.md are "estimates of the quality and quantity of associated training data", with a Training Duration category where smaller durations give a lower grade — [Kokoro-82M VOICES.md](https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md) (via search summary)
- A Flutter package wrapping Kokoro exists on pub.dev (`kokoro_tts_flutter`) — [pub.dev kokoro_tts_flutter](https://pub.dev/documentation/kokoro_tts_flutter/latest/) (listing only; contents not reviewed)
- **Piper**: `.onnx` + `.onnx.json` per voice; multi-speaker voices carry a speaker-name→ID map in the JSON produced at training time — [piper1-gpl docs/VOICES.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md), [piper1-gpl docs/TRAINING.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/TRAINING.md)
- **sherpa-onnx**: speaker chosen by integer `sid` (`--sid=109`, `--sid=900`) for Piper/VITS models; provides Android APKs per model — [sherpa vits.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/vits.rst)
- **Coqui/XTTS**: speaker = `(gpt_cond_latent, speaker_embedding)` from `get_conditioning_latents()`, cacheable across utterances — [coqui-ai/TTS xtts.md](https://github.com/coqui-ai/TTS/blob/dev/docs/source/models/xtts.md); **Tortoise**: `(autoregressive_latent, diffusion_latent)` saved as `.pth` — [tortoise Advanced_Usage.md](https://github.com/neonbjb/tortoise-tts/blob/main/Advanced_Usage.md)
- **Piper fine-tuning to make a new voice**: dataset CSV `wav|text` (or `wav|speaker|text`), start from an existing medium checkpoint, export to `model.onnx` + JSON — [piper1-gpl docs/TRAINING.md](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/TRAINING.md)
- **Qwen3-TTS VoiceDesign** creates a voice purely from a text instruction describing the vocal persona — [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS); **Parler-TTS** likewise is description-conditioned — [parler-tts dataset card](https://huggingface.co/datasets/parler-tts/libritts-r-filtered-speaker-descriptions) (via search summary)

### Inferences
- "Ship a new voice as a small file" is cleanly possible with Kokoro (a 0.5 MB `.pt`/row appended to `voices.bin`) and with Piper multi-speaker (a new 1 KB row plus the JSON map entry) — **but** making the *content* of that file requires either (a) blending existing Kokoro packs (KQ3), (b) for Piper, retraining/fine-tuning the whole model with the new speaker's audio and re-exporting (the new row only means something to the weights it was trained with), or (c) a style/speaker encoder that produces a vector the acoustic model understands. Kokoro's public repo contains inference only (no training code was found in the GitHub README), so an arbitrary brand-new Kokoro voice from a recording is not an offline-creatable artefact today (**inference; see gap**).
- For Math City the lowest-cost architecture is one shared acoustic model (Kokoro-class 80 MB int8, or Piper medium ~65–80 MB) plus eleven ≤0.5 MB voice vectors, switched per letter/question by passing a different vector. Total voice overhead < 6 MB.
- A zero-shot model would make the ten citizens a folder of ten WAV clips, but the only permissively licensed candidates (Chatterbox MIT 0.5B/350M/110M, Qwen3-TTS Apache 0.6B/1.7B, CosyVoice3 Apache 0.5B) are 1–20× larger than Kokoro and have no cited mobile-offline deployments; Chatterbox-Nano at 110M is the closest to feasible (**inference**).

### Gaps
- Whether Kokoro's training code has been released (which would allow fine-tuning new voices) could not be confirmed; the GitHub README fetched contains no training section and the HF card was blocked.
- Per-voice Piper MODEL_CARD licenses (e.g. lessac, ryan, amy, hfc) could not be read; the lessac dataset's exact licence is therefore unverified.
- The exact on-disk format of `voices-v1.0.bin` (NumPy `.npz` of name→array, as commonly described) was not confirmed from the repo text fetched.

---

## KQ3. Voice blending: which models support mixing two voice vectors into a new character voice, and how usable is the result?

### Takeaway
Blending is a first-class, cheap operation wherever a voice is a vector: Kokoro (weighted average of voice tensors — its arena-topping voice *is* a 50/50 blend), Tortoise (mean of conditioning latents from two speakers), and VITS/Piper speaker embeddings (interpolation, best done spherically). Research finds same-gender interpolations keep naturalness comparable to the base voices, and interpolated identities are distinct enough to be used as "new speakers".

### Cited Findings
- Kokoro: "the voice that achieved top ranking in the TTS Spaces Arena is actually a combined voice profile created by mixing two base voices — Bella and Sarah — in equal proportions"; mixing is `torch.mean(torch.stack([...]))` or weighted `v1*0.7 + v2*0.3` — [unfoldai Kokoro-82M](https://unfoldai.com/kokoro-82m/), [Kokoro-82M on Medium](https://medium.com/@simeon.emanuilov/kokoro-82m-building-production-ready-tts-with-82m-parameters-unfoldai-98e36ff286b9)
- The nazdridoy kokoro-tts CLI exposes voice blending with per-voice weights and can save the result as a reusable voice — [nazdridoy/kokoro-tts](https://github.com/nazdridoy/kokoro-tts), [deepwiki voice-blending page](https://deepwiki.com/nazdridoy/kokoro-tts/3.2-voice-blending) (via search summary)
- Tortoise: "you can combine feed two different voices to tortoise and it will output what it thinks the 'average' of those two voices sounds like" — [tortoise Advanced_Usage.md](https://github.com/neonbjb/tortoise-tts/blob/main/Advanced_Usage.md)
- Speaker-embedding interpolation research: all pairs of 50 speakers were interpolated with polar interpolation to produce 1,225 new voice profiles, to test how embedding normalisation affects intelligibility and distinctiveness of new speakers — reported across [arXiv 2106.05762](https://arxiv.org/pdf/2106.05762) / [arXiv 2210.05979](https://arxiv.org/pdf/2210.05979) (via search summary; exact attribution uncertain)
- Slerp between two speakers' prosody and timbre embeddings with factor α∈[0,1] "preserves the geometric structure of the hypersphere and minimizes audio artifacts" — [VoxMorph, arXiv 2601.20883](https://arxiv.org/pdf/2601.20883) (via search summary)
- Model-merging interpolation study: "output of merged models between same-gender base models achieved comparable naturalness with single-speaker base models" (MOS and WER evaluated) — [Attribute interpolation by model merging, arXiv 2407.00766](https://arxiv.org/pdf/2407.00766) (via search summary)
- INSIDE (Interpolating Speaker Identities in Embedding Space) synthesises new speaker identities by interpolating embeddings; speaker-verification systems trained on the expanded data improve 5.24% relative — [INSIDE, arXiv 2508.19210](https://pith.science/paper/2508.19210) (via search summary)
- Speaker embeddings with higher intra-class variance give better naturalness; sub-center modelling adds useful variation — [Sub-center speaker embeddings, arXiv 2407.04291](https://arxiv.org/html/2407.04291) (via search summary)

### Inferences
- For a cast of ten distinct citizens, Kokoro-style blending can mint many intermediate voices from the 54 shipped ones at zero model cost; each blend is itself a 0.5 MB pack (or 1 KB if you only store one length row — **inference**: Kokoro indexes by token length, so a full 510-row pack is needed to preserve its per-length averaging behaviour).
- Expect same-gender, same-accent blends to sound natural; cross-gender or extreme-weight blends are where research reports distinctiveness/intelligibility trade-offs (**inference** from the normalisation/interpolation studies). Linear averaging works in Kokoro practice; slerp is the safer choice for L2-normalised speaker-verification embeddings.
- Blending cannot create a convincingly *child* voice from adult packs (no cited evidence that interpolation moves along an age axis; see KQ5).

### Gaps
- No published listening-test numbers specifically for Kokoro blends (only the arena ranking anecdote).
- No source found quantifying how far one can push blend weights (e.g. extrapolation beyond [0,1]) before artefacts.

---

## KQ4. Zero-shot cloning: how much reference audio, what quality/similarity numbers, what ethical and legal constraints, and what ethically sourced voice datasets exist (incl. child speech)?

### Takeaway
Modern zero-shot models clone from 3–10 s of audio with speaker-similarity scores now at or above the human same-speaker baseline (CosyVoice3 0.78 vs 0.755; Qwen3-TTS 0.79–0.83), which is exactly why consent has become a legal issue: Tennessee's ELVIS Act (eff. 1 July 2024) makes unauthorised commercial voice replicas and the tools that make them actionable, EU AI Act Article 50 (applies Aug 2026) requires machine-readable marking of synthetic audio and disclosure of deepfakes, and major vendors ban cloning minors outright. Permissively licensed adult corpora (LibriTTS-R, VCTK, Hi-Fi TTS CC BY 4.0; Jenny attribution-only; Common Voice CC0) are plentiful; open child-speech corpora with commercial-compatible licences are scarce.

### Cited Findings

**Reference length and quality**
- VALL-E lineage/XTTS/F5/Fish/CosyVoice/Chatterbox prompt lengths: XTTS ~6 s (15–30 s better) — [openspeech XTTS v2](https://www.openspeech.dev/models/xtts-v2) (secondary); Chatterbox 5 s (original), ≥10 s (Multilingual) — [resemble.ai](https://www.resemble.ai/learn/models/chatterbox) and ~10 s in the README — [resemble-ai/chatterbox](https://github.com/resemble-ai/chatterbox); Fish/OpenAudio S1 10–30 s — [fishaudio/s1-mini](https://huggingface.co/fishaudio/s1-mini) (via search summary); CosyVoice3 ~3 s — [CosyVoice 3 paper](https://arxiv.org/pdf/2505.17589) (via search summary); Qwen3-TTS "3-second rapid voice clone" (reference audio + transcript) — [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS)
- Similarity numbers: YourTTS SECS 0.864 / Sim-MOS 4.16 on VCTK (2021) — [YourTTS](https://arxiv.org/pdf/2112.02418); CosyVoice3-RL cosine 0.780 vs human cross-recording 0.755 — [CosyVoice 3](https://arxiv.org/pdf/2505.17589) (via search summary); Qwen3-TTS 0.788–0.829 across languages — [Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS)
- Watermarking: Chatterbox bakes in Perth watermarks — [resemble-ai/chatterbox](https://github.com/resemble-ai/chatterbox)

**Vendor consent policies**
- ElevenLabs: users are "strictly prohibited from uploading ... Voice Data from children under the age of 18" and under-18s may not submit personal data — [ElevenLabs privacy policy](https://elevenlabs.io/privacy-policy) (via search summary); cloning requires owning the voice or explicit consent; professional voice cloning is limited to the account holder's own voice; violators are permanently banned — [terms.law ElevenLabs guide](https://terms.law/ai-output-rights/elevenlabs/), [licenseorg ElevenLabs guide](https://www.licenseorg.com/blog/elevenlabs-licensing-guide-ai-voices) (secondary); Consumer Reports audited six cloning companies' safeguards — [Consumer Reports Innovation Lab](https://innovation.consumerreports.org/?p=10509)
- StyleTTS2's pretrained LibriTTS weights carry two conditions: deployments must disclose the audio is synthetic, and cloning a real person requires their consent — [yl4579/StyleTTS2](https://github.com/yl4579/StyleTTS2) (via search summary)
- Chatterbox's stated responsible-use guidance is only "Don't use this model to do bad things" — [resemble-ai/chatterbox](https://github.com/resemble-ai/chatterbox)

**Law and regulation**
- Tennessee ELVIS Act, effective 1 July 2024, updates the 1984 Personal Rights Protection Act to cover AI voice replicas; unlawful to use AI to replicate a person's voice commercially without consent; civil remedies; "making available a service or algorithm whose primary purpose is producing a particular person's voice without authorisation carries liability of its own" — [ELVIS Act (Wikipedia)](https://en.wikipedia.org/wiki/ELVIS_Act), [spirelight voice-cloning laws guide](https://www.spirelight.ai/guides/voice-cloning-laws) (via search summary)
- EU AI Act Article 50: obligations live August 2026; providers must mark synthetic audio in a machine-readable way; deployers producing audio resembling a real person must disclose it is artificial "even without intent to deceive"; fines up to €15M / 3% turnover — [transparentaudio 2025 Transparency Rulebook](https://www.transparentaudio.ai/resources/the-2025-transparency-rulebook-for-voice-ai), [anyvoice regulation tracker](https://anyvoice.io/blog/ai-voice-cloning-regulation-news) (secondary; primary text blocked)
- FTC finalised a rule on 16 Feb 2024 against AI impersonation of governments and businesses and proposed extending it to individuals — [FTC press release](https://www.ftc.gov/news-events/news/press-releases/2024/02/ftc-proposes-new-protections-combat-ai-impersonation-individuals); FTC Voice Cloning Challenge winners announced 8 Apr 2024 (detection, anti-cloning watermark, liveness scoring) — [FTC press release](https://www.ftc.gov/news-events/news/press-releases/2024/04/ftc-announces-winners-voice-cloning-challenge)

**Ethically sourced / permissive datasets**
- LibriTTS-R: CC BY 4.0, ~585 h, 2,456 speakers, 24 kHz, restored audio — [OpenSLR 141](https://www.openslr.org/141/), [Google LibriTTS-R page](https://google.github.io/df-conformer/librittsr/)
- VCTK: 109 native English speakers, ~400 sentences each, ~44 h, 48 kHz, CC BY 4.0 — reported in [Hi-Fi TTS paper](https://arxiv.org/pdf/2104.01497) / [GLOBE paper](https://arxiv.org/pdf/2406.14875) (via search summary)
- Hi-Fi TTS: ~291.6 h, 10 speakers (≥17 h each), 44.1 kHz, CC BY 4.0 — [Hi-Fi Multi-Speaker English TTS Dataset](https://arxiv.org/pdf/2104.01497)
- Jenny (Dioco): ~30 h single Irish female speaker; attribution required in software that generates audio ("Jenny", where practical "Jenny (Dioco)"), not required on distributed clips; commercial use permitted — [Kaggle Jenny dataset](https://www.kaggle.com/datasets/noml4u/jenny-tts-dataset), [reach-vb/jenny_tts_dataset](https://huggingface.co/datasets/reach-vb/jenny_tts_dataset) (via search summary). A Piper voice `en_GB-jenny_dioco` exists — [rhasspy/piper VOICES.md](https://github.com/rhasspy/piper/blob/master/VOICES.md)
- Common Voice: CC0, >30,000 h, with age metadata buckets including "teens" (<19) — [Common Voice (Wikipedia)](https://en.wikipedia.org/wiki/Common_Voice), [Mozilla CV18 release](https://www.mozillafoundation.org/en/blog/common-voice-18-dataset-release/); a filtered English teen subset has 2,166 teenage contributors — [cryptolock/common-voice-22-en-teens](https://huggingface.co/datasets/cryptolock/common-voice-22-en-teens) (via search summary)
- Parler's LibriTTS-R speaker-description annotations (gender, pitch, rate, quality) — [parler-tts dataset](https://huggingface.co/datasets/parler-tts/libritts-r-filtered-speaker-descriptions) (via search summary)
- Kokoro itself was trained on permissive / public-domain audio — [hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) (via search summary)

**Child-speech corpora**
- MyST Children's Conversational Speech: ~470 h, 1,371 students in grades 3–5, distributed by LDC (LDC2021S05) under the "MyST Children's Conversational Speech Agreement" — [LDC2021S05](https://catalog.ldc.upenn.edu/LDC2021S05) (via search summary)
- CMU Kids: ~9 h read American-English child speech, LDC97S63, LDC individual/organisation agreements — [LDC97S63](https://catalog.ldc.upenn.edu/LDC97S63) (via search summary)
- Samrómur Children (Icelandic): CC BY 4.0, 86,503 rows, 6.81 GB — [language-and-voice-lab/samromur_children](https://huggingface.co/datasets/language-and-voice-lab/samromur_children) (via search summary)
- "Children speech recording (English, spontaneous + pre-defined sentences)": CC BY 4.0, ~607.5 MB — [Zenodo 200495](https://zenodo.org/records/200495) (via search summary)
- TTS-SCFChilSC (Mandarin, one 5-year-old girl, 15 min): CC BY-NC-ND 4.0 — excluded for this project — [MagicHub](https://magichub.com/datasets/mandarin-chinese-speech-corpus-for-tts-children-speech/) (via search summary)

### Inferences
- The permissive-model shortlist for a commercial-compatible, offline app is: Kokoro (Apache-2.0, trained on permissive audio), Piper voices whose MODEL_CARD dataset is CC BY/public domain (libritts_r, vctk, jenny_dioco at minimum — verify each), KittenTTS ONNX (Apache code; check model licence), Chatterbox (MIT), Qwen3-TTS and CosyVoice3 (Apache-2.0, but server-class). **Excluded**: F5-TTS official weights (CC-BY-NC), Fish/OpenAudio S1 weights (CC-BY-NC-SA), XTTS-v2 (CPML non-commercial, no licence path), KittenTTS 2 (custom community licence — read before use), any OpenAudio/ElevenLabs output used contrary to their terms.
- Cloning any real child is off the table on every axis: vendors prohibit under-18 voice data, the ELVIS/EU regimes centre on consent that a minor cannot meaningfully give, and the open child corpora are research-agreement (MyST, CMU Kids) or tiny. Fictional citizen voices should therefore be *designed* (blended/described/trained on consenting adult actors), not cloned.
- If the team records its own voice actors, the ELVIS-style right-of-publicity logic implies getting a written release that explicitly covers synthetic reproduction, and the EU Article 50 logic implies labelling the audio as synthetic in-app (e.g. a credits/"voices are computer-generated" line).

### Gaps
- Primary texts of the ELVIS Act, EU AI Act Article 50 and ElevenLabs' policies could not be fetched (blocked); facts rest on search summaries of those pages and on secondary legal explainers.
- MyST's licence terms regarding commercial use were not readable (LDC blocked); the LDC listing names a bespoke agreement, which should be assumed research-only until read.
- LJSpeech's public-domain status could not be verified (keithito.com blocked) — widely reported but unsourced here.
- The exact VALL-E ethics statement and F5-TTS/Chatterbox published SIM/WER tables were not retrievable (arXiv blocked; GitHub README lacks tables).

---

## KQ5. Child and teen voices: which open models/voice packs include young-sounding voices, and what does pitch- or formant-shifting an adult voice do to naturalness?

### Takeaway
No open, permissively licensed TTS model or voice pack with a genuine child voice was found: Kokoro's 54 voices and Piper's English catalogue are adult, and child-TTS research is bottlenecked by the lack of open child corpora. Pitch shifting is used as a data-augmentation trick that makes speech sound like "a different speaker", and commercial sites fake child voices by raising pitch on adult voices, but no controlled naturalness study of pitch-/formant-shifted adult TTS was located.

### Cited Findings
- Piper's English voice list (en_US/en_GB) contains no voice labelled as a child or young speaker — [rhasspy/piper VOICES.md](https://github.com/rhasspy/piper/blob/master/VOICES.md)
- Kokoro's voice catalogue is graded by training-data quantity/quality; voices are named by language/gender prefix (af_, am_, bf_, bm_, …) — [Kokoro-82M VOICES.md](https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md), [soniqo voice-code guide](https://soniqo.audio/guides/kokoro) (via search summary); no child voice is listed in any summary seen
- Child TTS research: FastPitch has been fine-tuned for child speech synthesis — [Improved Child TTS, arXiv 2311.04313](https://arxiv.org/pdf/2311.04313) (via search summary); "a huge challenge involves the limited publicly available children's speech datasets" — [Child speech synthesis pipeline, arXiv 2203.11562](https://arxiv.org/pdf/2203.11562) (via search summary)
- Pitch-shift augmentation (in cents) "mak[es] it sound as if the speech is spoken by a different speaker" and is used to synthesise child-like training data for child ASR — [Improving child ASR with augmented child-like speech, arXiv 2406.10284](https://arxiv.org/pdf/2406.10284) (via search summary)
- Commercial practice: "for languages without native child voices, pitch can be adjusted on an adult character to mimic a child sound" — [speechgen.io child TTS](https://speechgen.io/en/child-tts/) (vendor page)
- Text-described voices: Qwen3-TTS VoiceDesign accepts descriptions like "A young cheerful female with a warm tone" — [Qwen3-TTS guides](https://ocdevel.com/blog/20260302-qwen-tts-voice-cloning) (secondary) and [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS); MOSS-VoiceGenerator likewise creates voices from natural-language descriptions — [MOSS-VoiceGenerator, arXiv 2603.28086](https://arxiv.org/html/2603.28086v1) (title/abstract via search only)
- Common Voice's "teens" bucket (CC0) is the largest permissively licensed source of adolescent speech found, though it is crowd-sourced ASR-grade read speech, not studio TTS data — [Common Voice (Wikipedia)](https://en.wikipedia.org/wiki/Common_Voice), [common-voice-22-en-teens subset](https://huggingface.co/datasets/cryptolock/common-voice-22-en-teens) (via search summary)

### Inferences
- For Math City's ten citizens, "young-sounding" will realistically mean: (a) pick the highest-pitched, lighter adult Kokoro/Piper voices and blend toward them; (b) apply modest pitch + formant shifting in post (a time-domain pitch shift alone raises pitch but keeps adult formants, which is the classic "chipmunk" artefact — **inference from vocal-acoustics basics, not from a cited study**); or (c) commission adult voice actors doing character voices under a written release and fine-tune a Piper multi-speaker model. Fine-tuning on real children's speech is blocked by both data licences and consent norms (KQ4).
- Teen voices are more tractable than young-child voices: Common Voice CC0 teen speech exists in volume, and pitch ranges overlap adult female ranges.

### Gaps
- No open TTS model, voice pack, or dataset offering a permissively licensed *child* (≤12) English TTS voice was found.
- No controlled study of MOS/naturalness for pitch- or formant-shifted adult TTS output was found (arXiv blocked; search surfaced only augmentation-for-ASR uses).
- Whether Qwen3-TTS VoiceDesign or Parler-TTS reliably render convincing child voices from a description was not evaluated in any source seen.

---

## KQ6. How do Apple and Google implement voice downloads, and can a third-party app add a voice to the system engine?

### Takeaway
Both platforms ship system voices as separately downloaded packs: Apple's enhanced/premium Siri and Spoken Content voices run ~80–220 MB each, Google's standard packs were historically 6–30 MB with high-quality packs 200+ MB. Both platforms *do* let third parties add system-wide voices — Apple via an `AVSpeechSynthesisProviderAudioUnit` app extension (iOS 16+), Android via a `TextToSpeechService` engine — and open-source engines (eSpeak NG on iOS; sherpa-onnx-based VoxEngine on Android) already use these paths. But the voice then belongs to the engine the user selects, not to your app alone.

### Cited Findings
- Apple: "In iOS 16 and macOS Ventura you'll be able to create speech synthesizers that are usable through AVSpeechSynthesizer"; the audio unit is offline-only, receives SSML, and voices registered as `AVSpeechSynthesisProviderVoice` (name, age, gender, languages) appear automatically as `AVSpeechSynthesisVoice` system-wide — [Apple engineer announcement thread](https://twitter-thread.com/t/1560067672334733312) (via search summary); class reference exists — [AVSpeechSynthesisProviderAudioUnit](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisprovideraudiounit)
- eSpeak NG shipped an iOS beta built on `AVSpeechSynthesisProviderAudioUnit` that works with VoiceOver — [AppleVis eSpeak NG iOS beta](https://applevis.com/forum/ios-ipados/first-espeak-ng-beta-ios-now-available?page=1) (via search summary)
- A sherpa-onnx issue requests packaging Piper/VITS voices as iOS system voices via the provider audio unit, citing Apple's "Creating a custom speech synthesizer" guide, the WWDC23 "Extend speech synthesis" session, the espeak-ng iOS app and a third-party `piper-ios-app`; status unresolved in the issue body — [sherpa-onnx issue #984](https://github.com/k2-fsa/sherpa-onnx/issues/984)
- Apple Personal Voice (iOS 17): user reads 150 phrases; voice is generated and stored encrypted on-device; third-party apps can use it only if the user enables "Allow Apps to Request to Use" and grants the request; apps "can't capture speech from Personal Voice" — [AssistiveWare Personal Voice guide](https://www.assistiveware.com/support/proloquo2go/speech/apple-personal), [Apple support HT213878](https://support.apple.com/HT213878) (via search summary)
- Apple voice sizes: "Enhanced-quality voices can be 100 MB or larger"; downloads require Wi-Fi; managed under Settings > Accessibility > Spoken Content > Voices — [Apple support 111798](https://support.apple.com/en-us/111798) (via search summary); user-reported enhanced Siri voices Aaron 148 MB, Nicky 189 MB, Yu-shu 217 MB; US Siri Voice 3 listed at 79.9 MB in Spoken Content — [AppleVis enhanced Siri voice thread](https://www.applevis.com/forum/ios-ipados/enhanced-quality-siri-voice) (forum, secondary)
- Android: a third-party engine subclasses `TextToSpeechService`, implementing `onSynthesizeText`, `onGetVoices`, `onLoadVoice`, `onIsValidVoiceName`, declares the `android.intent.action.TTS_SERVICE` intent filter with `BIND_TEXT_TO_SPEECH_SERVICE` permission and `android.speech.tts.SERVICE_META_DATA`, and then appears in Settings > Text-to-speech > Preferred engine — [TextToSpeechService reference](https://developer.android.com/reference/android/speech/tts/TextToSpeechService); client apps enumerate `getVoices()` per engine — [TextToSpeech reference](https://developer.android.com/reference/android/speech/tts/TextToSpeech)
- Working Android third-party engines: VoxEngine ("Android system-level TTS speech synthesis engine ... free offline sherpa-onnx voices ... Once set as the system TTS service, any app ... can call it") — [Vaizer0/VoxEngine](https://github.com/Vaizer0/VoxEngine); an OpenAI-API-backed engine — [Alec-FW/android-custom-tts-engine](https://github.com/Alec-FW/android-custom-tts-engine); Play-store engines include CereProc, Acapela, eSpeak NG, VoxSherpa — [Organic Maps TTS FAQ](https://organicmaps.app/faq/voice/text-to-speech-tts-and-voice-directions-on-android/)
- Google voice packs: "Standard Google Text-to-Speech language packs range from about 6MB up to 30MB each"; high-quality voices "200+MB" (2014 data) — [Android Police 2014 TTS v3.0](https://www.androidpolice.com/2014/03/05/google-releases-huge-text-to-speech-tts-for-android-update-v3-0-with-high-quality-voices-new-languages-and-ui-changes-apk-download/), [Android Authority TTS guide](https://www.androidauthority.com/google-text-to-speech-engine-659528/) (via search summary; dated); the "Speech Recognition & Synthesis" APK itself is ~78 MB — [AppBrain listing](https://www.appbrain.com/app/speech-services-by-google/com.google.android.tts)

### Inferences
- Why platform voices are tens–hundreds of MB: they are self-contained per-voice acoustic models (plus lexicon/prosody data) in the "one model per voice" pattern of KQ1(1), the same reason a Piper medium voice is ~63 MB. (**inference**; neither vendor documents internals.)
- A third-party app *cannot* inject a voice into Apple's or Google's own engine, but it *can* ship its own engine that the OS lists beside them. For Math City that is the wrong tool: it requires the user to switch system TTS engines, puts the model in an audio-unit extension process with tight memory limits (**estimate**; limits not documented in fetched sources), and buys nothing over bundling sherpa-onnx/Kokoro inside the Flutter app. The in-app route (Kokoro or Piper via ONNX Runtime) is strictly simpler.
- Google's current Wavenet-class offline voice-pack sizes are undocumented publicly; treat "tens to ~200 MB" as the working range (**estimate**).

### Gaps
- Apple's developer page content and the WWDC22/23 sessions could not be fetched; memory/time limits for synthesizer extensions are unknown here.
- Current (2025–2026) Google offline voice-pack sizes were not found in any fetched source.

---

## KQ7. Practical numbers to verify or correct (Kokoro ~330 MB fp32 / ~80 MB int8 with 54 voices at ~0.5 MB; Piper medium ~60 MB; etc.), plus a licence matrix

### Takeaway
The headline numbers mostly hold: Kokoro is 82M params, ~300 MB fp32 ONNX / ~80 MB int8, 54 voices (v1.0) at 522 KB each; a Piper medium voice is 63–79 MB (not "~60"), with multi-speaker libritts_r-medium (904 speakers) at 75–79 MB; original VITS checkpoints are 109–116 MB and ~8× slower than Piper on a Pi 4.

### Cited Findings
- Kokoro: 82M params, Apache-2.0 — [hexgrad/kokoro](https://github.com/hexgrad/kokoro); "~300MB (quantized: ~80MB)" — [kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx); 54 voices / 8 languages in v1.0, ~few hundred training hours, ~500 A100-hours — [soniqo](https://soniqo.audio/guides/kokoro), [codesota](https://www.codesota.com/model/kokoro-v1-0) (via search summary); voicepack `[510,1,256]` fp32 — [cstr/kokoro-voices-GGUF](https://huggingface.co/cstr/kokoro-voices-GGUF) (via search summary)
- Piper: lessac-medium 63.2 MB; libritts_r-medium 78.6 MB — [piper-voices](https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx) (via search summary); sherpa lists libritts_r-medium 75 MB, RTF 0.790 (Pi 4, 1 thread) — [sherpa vits.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/vits.rst)
- Original VITS: vits-vctk 116 MB (109 spk) RTF 6.079; vits-ljs 109 MB RTF 6.057 — [sherpa vits.rst](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/pretrained_models/vits.rst)
- KittenTTS ONNX: Nano 15M / 25–56 MiB; Micro 40M / 41 MiB; Mini 80M / 80 MiB — [KittenML/KittenTTS](https://github.com/KittenML/KittenTTS)
- Chatterbox: 500M / 350M (Turbo) / 110M (Nano), MIT — [resemble-ai/chatterbox](https://github.com/resemble-ai/chatterbox); Qwen3-TTS 0.6B/1.7B Apache-2.0 — [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS); Fish S1-mini 0.5B CC-BY-NC-SA — [fishaudio/s1-mini](https://huggingface.co/fishaudio/s1-mini) (via search summary); F5-TTS weights CC-BY-NC — [SWivid/F5-TTS](https://github.com/SWivid/F5-TTS); XTTS-v2 CPML — [coqui xtts.md](https://github.com/coqui-ai/TTS/blob/dev/docs/source/models/xtts.md)
- Speaker embedding widths: VITS `gin_channels` 256 — [vctk_base.json](https://github.com/jaywalnut310/vits/blob/main/configs/vctk_base.json); GE2E 256 — [Resemblyzer eval](https://ceur-ws.org/Vol-4164/paper7.pdf); ECAPA 192, x-vector 512 — [arXiv 2506.20190](https://www.arxiv.org/pdf/2506.20190); H/ASP 512 — [YourTTS](https://arxiv.org/pdf/2112.02418); Kokoro 256 (128+128) — [kokoro model.py](https://github.com/hexgrad/kokoro/blob/main/kokoro/model.py)
- LoRA/adapter sizes: 2.4–2.8M params — [arXiv 2211.00585](https://ar5iv.labs.arxiv.org/html/2211.00585) (via search summary)

### Inferences (corrections and derived figures)
- "Kokoro ~330 MB fp32": the ONNX fp32 export is documented as ~300 MB; the ~330 MB figure plausibly refers to the PyTorch `.pth` but is unverified. "~80 MB int8" **confirmed**. "54 voices at ~0.5 MB": **confirmed and sharpened** — 522,240 bytes each (derived), ≈27.5 MB for all 54; a single utterance uses one 256-float row (1 KB).
- "Piper medium ~60 MB each": **slightly low** — 63 MB (lessac) to 79 MB (libritts_r) per `.onnx`; the 904-speaker model is the better per-voice deal by three orders of magnitude (~87 KB per speaker amortised, ~1 KB marginal).
- Per-voice marginal cost summary (derived):

| Mechanism | +1 voice on disk | +1 voice in RAM | Switch per utterance? | Offline-creatable by dev? | Licence posture (permissive examples) |
|---|---|---|---|---|---|
| One model per voice (Piper single) | 63–79 MB | one more model if resident | needs session load | yes (GPL training code, GPU hours) | MIT code; per-voice MODEL_CARD |
| Speaker-ID table (Piper/VITS multi) | ~1 KB row | ~1 KB | yes, integer `sid` | only by retraining whole model | libritts_r/vctk voices from CC BY data |
| Reference/style vector (Kokoro, StyleTTS2) | 0.52 MB pack (1 KB used) | ~0.5 MB | yes, pass tensor | blend existing packs; no public training path confirmed | Kokoro Apache-2.0 |
| Zero-shot prompt (Chatterbox, Qwen3-TTS, CosyVoice3) | 3–10 s WAV + cached latent | cached latent (KB–MB est.) | yes if latent cached | yes (a recording) | MIT / Apache; but 0.1–1.7B params |
| LoRA per voice | ~5–50 MB adapter | adapter + base | adapter swap (fast, not free) | yes (GPU fine-tune) | depends on base |
| Platform voice pack (Apple/Google) | 80–220 MB / 6–200+ MB | engine-managed | yes, choose voice id | no (only by shipping own engine) | n/a |

### Gaps
- Exact file sizes for Kokoro `.pth`/`.onnx` variants and Piper low/high tiers remain unverified due to blocked Hugging Face listings.
- No fetched source gives Chatterbox/Qwen3-TTS on-disk sizes in bytes; parameter counts only.
