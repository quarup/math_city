# Hosted TTS services and what GPU compute buys in TTS quality (as of 2026-10-04)

Research method note: WebSearch worked throughout; direct fetches of artificialanalysis.ai, elevenlabs.io, platform.openai.com, azure.microsoft.com, hume.ai, arxiv.org, huggingface.co, vllm.ai, docs.vllm.ai, marktechpost.com, inworld.ai, cekura.ai, silma.ai and openbenchmarks.com were all blocked by the sandbox's egress proxy. Where a figure comes from a vendor page quoted via search-engine snippets or from a secondary comparison site rather than the primary page, it is marked "(secondary)". Everything dated before mid-2026 carries its date. Dollar figures are USD list prices unless stated.

## Q1. Survey of the leading hosted TTS APIs: pricing, free tiers, latency, catalog, cloning, style control, languages

### Takeaway
List prices in October 2026 span three orders of magnitude: hosted Kokoro at ~$0.62–0.80 per million characters, cloud-provider "neural" tiers at $4–16/M, the 2025–26 generation of expressive models at $22–50/M (Azure Neural HD $22, Inworld $25, Google Chirp 3 HD / Polly Generative / Deepgram Aura-2 $30, ElevenLabs v4 Turbo $40, Cartesia ~$49), and the premium expressive tier at $80–160/M (ElevenLabs v4 $80, ElevenLabs v3 / MiniMax HD $100, Google Studio $160). The arena leader (Eleven v4, Elo ~1319) costs ~130x more per character than the best cheap open model served as an API (Kokoro, Elo ~1060).

### Cited Findings

**ElevenLabs**
- API list prices (secondary, mid-2026): $0.10 per 1,000 characters ($100/M) for Eleven v3 and Multilingual v2; $0.05 per 1,000 ($50/M) for Flash v2.5 and Turbo v2.5. On subscription plans Flash/Turbo bill 0.5 credit per character versus 1 credit for v2/v3. — [Puter ElevenLabs API pricing breakdown, Jun 2026](https://developer.puter.com/tutorials/elevenlabs-api-pricing/); [modelslab](https://modelslab.com/elevenlabs-api-pricing)
- Eleven v4 and Eleven v4 Turbo launched 28 Sep 2026; ElevenLabs calls v4 "our most emotive text-to-speech model yet". Features: inline tags and unspoken context direct emotion, pacing, reactions, sound effects and style; natural-language "staging" of how a line should be delivered; instant voice clone from 10 seconds of audio; 90+ languages (up from 70+ in v3). — [runtimewire](https://runtimewire.com/article/elevenlabs-eleven-v4-turbo-launch); [digitalapplied](https://www.digitalapplied.com/blog/eleven-v4-turbo-voice-agents-latency-pricing)
- v4 list price $0.08 per 1,000 characters ($80/M); v4 Turbo $0.04 per 1,000 ($40/M). Launch discount (72%, until 12 Oct 2026): $22/M for v4 and $11/M for v4 Turbo. v4 Turbo median inference latency ~100 ms. — [cellcog](https://cellcog.ai/blog/eleven-v4/); [dailyaipedia](https://dailyaipedia.com/eleven-v4-elevenlabs-launch-pricing-voice-cloning-audio-tags/)
- Eleven v3 expressiveness is controlled by in-script audio tags such as [whispers], [laughs], [sighs]. Voice Design generates a new voice from a text description of age, gender, accent and style ("a young Indian female voice, soft and calm"). — [sureprompts voice-model comparison 2026](https://sureprompts.com/blog/voice-generation-models-compared-2026); [speechslide listening comparison](https://speechslide.com/en/blog/tts-engine-listening-comparison)
- Vendor-claimed Flash v2.5 TTFA ~75 ms; independently measured p50 208 ms (Coval, earlier 2026) and 185 ms (Sep 2026). — [futureagi best TTS providers 2026](https://futureagi.com/blog/best-tts-providers-voice-agents-2026/); [gradium TTS latency benchmark 2026](https://gradium.ai/content/tts-latency-benchmark-2026)

**OpenAI**
- tts-1 $15/M characters; tts-1-hd $30/M characters. gpt-4o-mini-tts (released 20 Mar 2025) is billed per token: $0.60/M text-input tokens and $12/M audio-output tokens (as of Jul 2026); third parties estimate this at roughly $15/M characters. Max input 2,000 tokens. — [texttolab OpenAI TTS pricing](https://texttolab.com/blog/openai-tts-pricing); [cloudprice gpt-4o-mini-tts](https://cloudprice.net/models/openai-gpt-4o-mini-tts); [OpenAI community thread on gpt-4o-mini-tts pricing](https://community.openai.com/t/understanding-gpt-4o-mini-tts-pricing-input-characters-cost/1151816)
- gpt-4o-mini-tts takes free-text `instructions` for tone/style (the "steerable" voice). Measured TTFA p50 636 ms (Coval); vendor streams over SSE at roughly 350–500 ms. — [futureagi](https://futureagi.com/blog/best-tts-providers-voice-agents-2026/)
- Newer 2026 audio models are speech-to-speech, not TTS: gpt-realtime-2 (8 May 2026, "GPT-5-class reasoning in a live voice loop", 128k context), gpt-realtime-2.1 and gpt-realtime-2.1-mini (Jul 2026). Pricing: gpt-realtime-2.1 audio $32/M input, $0.40/M cached, $64/M output; mini $10 / $0.30 / $20. gpt-realtime-translate $0.034/min, gpt-realtime-whisper $0.017/min (7 May 2026). — [layer3labs OpenAI Realtime pricing](https://www.layer3labs.io/guides/openai-realtime-api-pricing); [tokenmix](https://tokenmix.ai/blog/openai-realtime-voice-api-2026-cost-latency); [OpenAI: Advancing voice intelligence with new models in the API](https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api/)

**Google Cloud TTS**
- Standard $4/M, WaveNet $4/M, Neural2 $16/M, Studio $160/M, Chirp 3 HD $30/M, Chirp 3 Instant Custom Voice $60/M. Ongoing free tier: 4M chars/month Standard and WaveNet; 1M/month each for Neural2, Studio and Chirp 3 HD. Studio voices are "only available for a limited set of languages." (secondary; cloud.google.com/text-to-speech/pricing is the primary page) — [diyai Google Cloud TTS pricing 2026](https://diyai.io/ai-tools/audio-generation/google-cloud-text-to-speech-pricing/); [costbench](https://costbench.com/software/ai-voice-tools/google-cloud-text-to-speech/); [Google pricing page](https://cloud.google.com/text-to-speech/pricing)
- Gemini TTS is token-billed: Gemini 2.5 Flash TTS $0.50/M text-input tokens and $10/M audio-output tokens, where audio = 25 tokens per second. Gemini 3.8 Flash TTS (Preview) $0.50/M input and $9/M audio-output tokens through 31 Dec 2026, rising to $1/M and $18/M from 1 Jan 2027; Gemini 3.8 Flash-Lite TTS (Preview) $0.50/M input, $6/M audio output. — [Google pricing page via search snippet](https://cloud.google.com/text-to-speech/pricing)
- Gemini TTS takes a natural-language style prompt ("speak in a cheerful, positive tone") and 200+ audio tags ([excited], [whisper], [sigh]). — [speechslide](https://speechslide.com/en/blog/tts-engine-listening-comparison); [nemovideo Gemini 3.1 Flash TTS vs ElevenLabs](https://www.nemovideo.com/blog/gemini-3-1-flash-tts-vs-elevenlabs)

**Microsoft Azure Speech**
- Neural $16/M characters; Neural HD $22/M from March 2026 (down from $30/M); Custom Neural Voice from $24/M ($48/M HD). Free tier 500K characters/month, no expiry. (secondary) — [texttolab Azure pricing](https://texttolab.com/blog/azure-text-to-speech-pricing); [Microsoft Tech Community: Azure Speech Neural HD recent voice updates](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/azure-speech-%E2%80%93-neural-hd-text-to-speech-recent-voice-updates/4505380)
- Catalog: 600+ neural voices (700+ with Dragon HD Omni) across 150+ languages/locales; tiers are Neural, Neural HD, Dragon HD Omni, plus OpenAI voices inside Azure Speech. — [blipradar Azure TTS review](https://blipradar.com/microsoft-azure-tts); [notevibes Azure review 2026](https://notevibes.com/alternative/azure-speech)

**Amazon Polly**
- Standard $4/M, Neural $16/M, Generative $30/M. Free tier (first 12 months only): 5M chars/month Standard, 1M Neural, 100K Generative. — [costbench Polly pricing 2026](https://costbench.com/software/ai-voice-tools/amazon-polly/); [texttolab Polly](https://texttolab.com/blog/amazon-polly-pricing)

**Cartesia Sonic**
- Sonic 3 is a State Space Model architecture with vendor-claimed 40 ms TTFA (Sonic 3.5 "sub-90 ms over WebSocket"); independent p50 for Sonic 3.5 was 270 ms (Coval) and 269 ms (Sep 2026). Artificial Analysis normalizes Sonic 3.6 at $49.00/M characters; plans start free with a $4/month Pro plan. Sonic 3.6 shipped Aug 2026 and led both AA speech arenas at the time. — [invideo Cartesia Sonic 3/3.5](https://invideo.io/blog/cartesia-sonic-ai-voice/); [MarkTechPost on Sonic 3.6, 18 Aug 2026](https://www.marktechpost.com/2026/08/18/cartesia-ships-sonic-3-6-a-streaming-tts-model-that-now-leads-both-artificial-analysis-speech-arenas/); [gradium](https://gradium.ai/content/tts-latency-benchmark-2026)

**Hume Octave**
- Octave 2 preview: ~100 ms latency (200 ms TTFT streaming). Free tier 10,000 chars/month. Overage $0.15/1K (Creator), $0.12/1K (Pro), $0.10/1K (Scale), $0.05/1K (Business), i.e. $50–150/M. Octave "reads for meaning and adapts delivery without tags" and supports voice design by description plus acting instructions. — [cekura best TTS for voice agents](https://www.cekura.ai/blogs/best-tts-for-ai-voice-agents); [aipedia Hume pricing](https://www.aipedia.wiki/guides/hume-ai-pricing-for-emotion-aware-voice-apps/); [pixazo Hume vs ElevenLabs](https://www.pixazo.ai/blog/hume-ai-vs-elevenlabs); [Hume pricing page (blocked, primary)](https://www.hume.ai/pricing)

**MiniMax Speech**
- Official pay-as-you-go: speech-2.6-turbo $60/M, speech-2.6-hd $100/M characters. Family also includes Speech 2.8 and a "Voice Design" model (secondary). — [minimax-ai.chat Speech 2.6](https://minimax-ai.chat/models/minimax-speech-26/); [invideo MiniMax audio family](https://invideo.io/blog/minimax-ai-voice-models/); [Artificial Analysis Speech 2.6 Turbo page](https://artificialanalysis.ai/text-to-speech/models/speech-2.6-turbo)

**Inworld TTS**
- Realtime TTS-2 on-demand $25/M characters; monthly plans $20 (Creator), $17.50 (Builder), $15 (Developer), $12.50 (Growth). TTS-2 Flash on Growth: $0.0070/min of audio (vendor framing: 42 cents per finished hour). Inworld's own benchmark post claims MiniMax Speech 2.6 HD is 80 Elo below Inworld at 4x the price (vendor claim). — [therundown Inworld Realtime TTS-2](https://www.therundown.ai/tools/realtime-tts-2); [orcarouter Inworld TTS-2 GA + Flash](https://www.orcarouter.ai/blog/inworld-realtime-tts-2-flash-launch); [Inworld benchmarks post (blocked, vendor)](https://inworld.ai/resources/best-voice-ai-tts-apis-for-real-time-voice-agents-2026-benchmarks)

**Fish Audio (hosted)**
- s2-pro $15.00 per million UTF-8 bytes; Pro plan includes up to 1,620 minutes/month of S1/S2 generation. — [Fish Audio pricing docs](https://docs.fish.audio/developer-guide/models-pricing/pricing-and-rate-limits); [texttolab Fish pricing](https://texttolab.com/blog/fish-audio-pricing)

**Deepgram Aura-2**
- $30/M characters ($0.030/1K; $0.027/1K at Growth tier). Vendor TTFA claim 150–250 ms over WebSocket; independent p50 323 ms (Coval) and 290 ms (Sep 2026). — [texttolab Deepgram pricing](https://texttolab.com/blog/deepgram-pricing); [cekura Deepgram pricing](https://www.cekura.ai/blogs/deepgram-pricing); [gradium](https://gradium.ai/content/tts-latency-benchmark-2026)

**Rime**
- Starter: Arcana $40/M, Mist $30/M. Growth: Arcana $30/M, Mist $20/M. — [Rime new pricing blog](https://www.rime.ai/blog/new-pricing/)

**Smallest.ai Lightning**
- From $0.175 per 10K characters (~$17.50/M). — [Smallest.ai model pricing](https://smallest.ai/pricing/models)

**Speechify (Simba)**
- Simba 3.2 $10/M at entry tier, $6/M at Scale tier. Speechify issued a press release claiming Simba 3.2 ranked #1 on the Artificial Analysis TTS leaderboard (date not captured; claim is the vendor's and has since been overtaken by Eleven v4 / Sonic 3.6 per the leaderboard snapshots below). — [speechify.ai best TTS APIs 2026](https://speechify.ai/blog/best-tts-providers-2026-comparison); [PRWeb Simba 3.2 release](https://www.prweb.com/releases/speechifys-simba-3-2-ranks-1-on-independent-artificial-analysis-tts-leaderboard-worlds-best-real-time-voice-model-above-elevenlabs-openai-google-deepmind--others-302819731.html)

**Resemble AI**
- Bills per second of output: Flex plan from $0.0005/synthesis-second (= $1.80 per audio hour); Creator $29/mo, Professional $99/mo; Rapid Voice Clone $2/mo per voice, Professional Voice Clone $5/mo per voice. — [checkthat Resemble pricing 2026](https://checkthat.ai/brands/resemble-ai/pricing); [Resemble pricing page](https://www.resemble.ai/pricing)

**Play.ht / PlayAI**
- Acquired by Meta in July 2025; the standalone product was wound down and the site shut down 31 Dec 2025. Pre-shutdown API pricing: $7.60/M (AI Voice 7), $10/M (standard), $30/M (Turbo). Not a viable option in Oct 2026. — [buildmvpfast Play.ht pricing](https://www.buildmvpfast.com/tools/api-pricing-estimator/playht); [codaone](https://www.codaone.ai/tools/play-ht/)

**Hosted Kokoro**
- Kokoro-82M on DeepInfra $0.62/M characters; Replicate ~$0.65/M; Together.ai and OpenRouter also list it. "Under $1 per million characters, or under $0.06 per hour of audio output" (Apr 2025 market rate). — [DeepInfra Kokoro API](https://deepinfra.com/hexgrad/Kokoro-82M/api); [OpenRouter Kokoro](https://openrouter.ai/hexgrad/kokoro-82m); [arifsolmaz Kokoro note, Jan 2026](https://arifsolmaz.github.io/repo/2026/01/28/kokoro-82m/)

**Other 2026 entrants visible on leaderboards (names only; no pricing captured)**: Qwen-Audio-3.0/3.1-TTS-Plus (Alibaba, hosted), Breeze TTS 2 (open weights), Step Audio EditX (Mar 2026, open), Voxtral TTS (Mistral, open), Magpie-Multilingual 357M (NVIDIA, Feb 2026, open), Gradium. — [AA leaderboard via search](https://artificialanalysis.ai/text-to-speech/leaderboard); [gradium](https://gradium.ai/content/tts-latency-benchmark-2026)

### Inferences
- Pricing has bifurcated by billing unit: character-billed (most vendors), token-billed (OpenAI gpt-4o-mini-tts, Gemini TTS), and time-billed (Resemble, Inworld Flash). Converting Gemini's $9/M audio tokens at 25 tokens/s gives $0.0135 per minute of audio; at a typical ~150 words/min and ~6 characters/word (~900 chars/min) that is roughly $15/M characters — the same order as OpenAI's mini-tts. Treat this as an estimate.
- Token/time billing favors fast, terse speech (fewer audio tokens per character); character billing favors long words. For short math prompts the difference is small.
- Every vendor-claimed TTFA in this list is 2–3x lower than independent p50 measurements (ElevenLabs 75 vs 185–208 ms; Cartesia <90 vs 269–270 ms; Deepgram 150–250 vs 290–323 ms). Budget from measured p50.

### Gaps
- Could not fetch primary pricing pages for ElevenLabs, OpenAI, Azure, Hume, Cartesia or Inworld (egress blocked); figures above are from vendor pages quoted via search snippets or secondary trackers dated 2026.
- No price found for Azure Dragon HD Omni specifically, for Google Chirp 3 HD voice count, or for the hosted Qwen-Audio-TTS-Plus and Breeze TTS 2 models.
- ElevenLabs' free tier size was not confirmed in this session.

## Q2. Cost arithmetic: narrating 300 short math prompts per child per week for 10,000 kids

### Takeaway
At an assumed 60 characters per prompt, the workload is 180M characters/week (~9.4B/year). Live synthesis costs $112/week on hosted Kokoro, ~$2,700–2,900/week on $15–16/M tiers (OpenAI tts-1, Polly/Azure/Google Neural, Fish S2 Pro), $5,400 on $30/M tiers, $7,200 on ElevenLabs v4 Turbo and $14,400–18,000/week on the premium tier — i.e. $0.75M–0.94M/year at ElevenLabs v4/v3 prices. Because math prompts are templated, pre-rendering the distinct strings once costs a few hundred dollars even at premium prices; the per-request cost only matters if text is generated live.

### Cited Findings
- Price inputs used (all from Q1 sources): Kokoro $0.62/M ([DeepInfra](https://deepinfra.com/hexgrad/Kokoro-82M/api)); Google Standard $4/M ([diyai](https://diyai.io/ai-tools/audio-generation/google-cloud-text-to-speech-pricing/)); Speechify Simba $6–10/M ([speechify.ai](https://speechify.ai/blog/best-tts-providers-2026-comparison)); OpenAI tts-1 $15/M, tts-1-hd $30/M ([texttolab](https://texttolab.com/blog/openai-tts-pricing)); Polly/Azure/Google Neural $16/M ([costbench Polly](https://costbench.com/software/ai-voice-tools/amazon-polly/), [texttolab Azure](https://texttolab.com/blog/azure-text-to-speech-pricing)); Azure Neural HD $22/M ([Microsoft Tech Community](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/azure-speech-%E2%80%93-neural-hd-text-to-speech-recent-voice-updates/4505380)); Inworld $25/M ([therundown](https://www.therundown.ai/tools/realtime-tts-2)); Chirp 3 HD / Polly Generative / Aura-2 $30/M; ElevenLabs v4 Turbo $40/M, Flash/Turbo v2.5 $50/M, v4 $80/M, v3 $100/M ([cellcog](https://cellcog.ai/blog/eleven-v4/), [Puter](https://developer.puter.com/tutorials/elevenlabs-api-pricing/)); Cartesia $49/M ([invideo](https://invideo.io/blog/cartesia-sonic-ai-voice/)); MiniMax HD $100/M ([minimax-ai.chat](https://minimax-ai.chat/models/minimax-speech-26/)); Google Studio $160/M ([diyai](https://diyai.io/ai-tools/audio-generation/google-cloud-text-to-speech-pricing/)).

**Arithmetic (assumption: a short math prompt such as "What is seven plus five? Tap the answer." is ~60 characters; this is my assumption, not a sourced figure)**

- Characters per week = 300 prompts × 60 chars × 10,000 kids = 180,000,000 = **180M chars/week**
- Per year = 180M × 52 = **9.36B chars/year**

| Tier (price per 1M chars) | $/week (×180) | $/year (×9,360) |
|---|---|---|
| Hosted Kokoro $0.62 | $112 | $5,800 |
| Google Standard/WaveNet $4 | $720 | $37,440 |
| Speechify Simba $6 / $10 | $1,080 / $1,800 | $56k / $94k |
| OpenAI tts-1, Fish S2 Pro $15 | $2,700 | $140,400 |
| Polly/Azure/Google Neural $16 | $2,880 | $149,760 |
| Azure Neural HD $22 | $3,960 | $205,920 |
| Inworld TTS-2 $25 | $4,500 | $234,000 |
| Chirp 3 HD, Polly Generative, Aura-2, tts-1-hd $30 | $5,400 | $280,800 |
| ElevenLabs v4 Turbo $40 | $7,200 | $374,400 |
| Cartesia Sonic 3.6 $49 | $8,820 | $458,640 |
| ElevenLabs Flash/Turbo v2.5 $50 | $9,000 | $468,000 |
| ElevenLabs v4 $80 | $14,400 | $748,800 |
| ElevenLabs v3, MiniMax HD $100 | $18,000 | $936,000 |
| Google Studio $160 | $28,800 | $1,497,600 |

- Free-tier coverage: Azure's 500K chars/month and Google's 1M/month (Chirp 3 HD) or 4M/month (Standard) cover 0.03%–0.6% of a 780M-char month (180M × 4.33); free tiers are irrelevant at this scale but cover a whole pre-render of a templated catalogue (see inference below). — [texttolab Azure](https://texttolab.com/blog/azure-text-to-speech-pricing); [diyai Google](https://diyai.io/ai-tools/audio-generation/google-cloud-text-to-speech-pricing/)

### Inferences
- The per-child-per-week cost ranges from $0.0011 (Kokoro) to $0.18 (ElevenLabs v3). At $0.03–0.05/child/week (the $16–30/M tiers) a free app with 10,000 weekly actives would spend $150k–280k/year — not viable without revenue; at ElevenLabs premium prices it is ~$1M/year.
- Pre-rendering changes the problem entirely. If the question catalogue is templated, the distinct strings are what cost money. Illustrative: 50,000 distinct prompt strings × 60 chars = 3M characters, one-time = $240 at ElevenLabs v4 ($80/M), $90 at Chirp 3 HD, or free inside Google's 1M/month Chirp 3 HD free tier spread over three months. Numbers and digits can be concatenated from pre-rendered fragments, though sentence prosody suffers at fragment joins (a well-known concatenative-TTS limitation; not separately sourced here).
- Therefore for Math City the hosted-vs-on-device question is really "pre-render with a premium hosted voice and bundle the audio" versus "ship an on-device model and synthesize live"; only live-generated text (e.g., a tutor explaining a wrong answer) forces per-request hosted costs or an on-device model.

### Gaps
- No vendor publishes volume-discount tables beyond the plan tiers quoted; enterprise rates at 9B chars/year would be negotiated and are unknowable from public sources.

## Q3. Time-to-first-audio, streaming support, and real-time vs batch suitability

### Takeaway
Independently measured p50 TTFA (Coval leaderboard, 2026): ElevenLabs Flash v2.5 185–208 ms, Cartesia Sonic 3.5 ~270 ms, Deepgram Aura-2 290–323 ms, OpenAI gpt-4o-mini-tts 636 ms. Anything under ~300 ms measured is usable for interactive turn-taking; batch pre-rendering can use any model, including the slow premium ones (ElevenLabs v3/v4, Google Studio, Gemini TTS).

### Cited Findings
- Coval independent p50 streaming TTFA: ElevenLabs Flash v2.5 208 ms; Cartesia Sonic 3.5 270 ms; Deepgram Aura-2 323 ms; OpenAI gpt-4o-mini-tts 636 ms. Sep 2026 update: Flash v2.5 185 ms, Sonic 3.5 269 ms, Aura-2 290 ms. — [futureagi](https://futureagi.com/blog/best-tts-providers-voice-agents-2026/); [gradium benchmark 2026](https://gradium.ai/content/tts-latency-benchmark-2026); [Coval benchmark on openbenchmarks (blocked)](https://openbenchmarks.com/text-to-speech-benchmark-by-coval)
- Vendor claims: ElevenLabs Flash ~75 ms; Cartesia sub-90 ms over WebSocket (Sonic 3: 40 ms model latency); Deepgram 150–250 ms; OpenAI 350–500 ms over SSE; Hume Octave 2 ~100 ms (200 ms TTFT streaming); Eleven v4 Turbo median ~100 ms; Qwen3-TTS "as low as 97 ms" with first packet after a single character of input. — [futureagi](https://futureagi.com/blog/best-tts-providers-voice-agents-2026/); [invideo Cartesia](https://invideo.io/blog/cartesia-sonic-ai-voice/); [cekura](https://www.cekura.ai/blogs/best-tts-for-ai-voice-agents); [cellcog Eleven v4](https://cellcog.ai/blog/eleven-v4/); [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS)
- Coval's framing: "Cartesia's sub-90ms time-to-first-audio is a best case; independent p50 streaming benchmarks put it meaningfully higher, and you should budget from measured p50, not the datasheet." — [futureagi](https://futureagi.com/blog/best-tts-providers-voice-agents-2026/)
- Self-hosted reference points: Baseten's Orpheus-3B deployment achieves 200 ms TTFB on an H100 MIG slice and <150 ms on a full H100. — [Baseten / Canopy Labs Orpheus](https://www.baseten.co/blog/canopy-labs-selects-baseten-as-preferred-inference-provider-for-orpheus-tts-model/)

### Inferences
- Real-time-capable (measured p50 ≤ ~300 ms, streaming): ElevenLabs Flash/Turbo and v4 Turbo, Cartesia Sonic, Deepgram Aura-2, Inworld TTS-2 Flash, Rime, Smallest Lightning, Hume Octave 2, Azure Neural (streaming), self-hosted Kokoro/Orpheus/Qwen3-TTS. Batch-oriented or slow-first-byte: OpenAI tts-1/gpt-4o-mini-tts (636 ms), ElevenLabs v3/v4 non-Turbo, Google Studio, Gemini TTS (token-based generation; no sub-200 ms claims found).
- For a kids' math game the network round trip (hundreds of ms on mobile) is added on top of all hosted TTFA numbers; an on-device model with 100–300 ms synthesis (Kokoro on a phone) will usually feel faster than any hosted model.

### Gaps
- No independent p95 figures captured; no measured latency found for Gemini TTS, Chirp 3 HD, Azure Dragon HD, Polly Generative, MiniMax or Fish hosted.

## Q4. Style / emotion / instruction prompting — who offers it and how good is it

### Takeaway
Three control paradigms exist in 2026: (1) in-script audio tags (ElevenLabs v3/v4 with [whispers], [laughs]; Gemini TTS 200+ tags; Orpheus tags; Inworld markups), (2) free-text delivery instructions (OpenAI gpt-4o-mini-tts `instructions`, Gemini style prompt, ElevenLabs v4 "staging", Hume acting directions, Qwen3-TTS instruction control), and (3) implicit, text-driven emotion with no control surface (Hume Octave "reads for meaning", Azure HD voices). Arena results show the tag/instruction-rich models (Eleven v4, Sonic 3.6, Gemini 3.8 Flash TTS) at the top, but no public blind test isolates how well an instruction like "excited teenager" is followed.

### Cited Findings
- ElevenLabs v3 uses tag-based controls inside the script ([whispers], [laughs], [sighs], scene cues); v4 adds natural-language staging ("describe how a line should be delivered and let the model interpret the scene") and tags for sound effects. — [sureprompts](https://sureprompts.com/blog/voice-generation-models-compared-2026); [runtimewire](https://runtimewire.com/article/elevenlabs-eleven-v4-turbo-launch)
- Gemini TTS: prompt-based style direction ("speak in a cheerful, positive tone") plus 200+ audio tags. — [speechslide](https://speechslide.com/en/blog/tts-engine-listening-comparison); [nemovideo](https://www.nemovideo.com/blog/gemini-3-1-flash-tts-vs-elevenlabs)
- Hume Octave: "explicitly designed around prosodic emotion modeling"; Octave 2 "reads for meaning and adapts delivery without tags". — [pixazo](https://www.pixazo.ai/blog/hume-ai-vs-elevenlabs); [sureprompts](https://sureprompts.com/blog/voice-generation-models-compared-2026)
- OpenAI gpt-4o-mini-tts is "steerable" via instructions (~$15/M chars). — [texttolab](https://texttolab.com/blog/openai-tts-pricing)
- Qwen3-TTS (open): "Instruction Control: adaptive tone adjustment based on text semantics and user directives"; emotion control via natural-language instructions. — [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS); [Qwen blog, 15 Jan 2026](https://qwen.ai/blog?id=qwen3tts-0115)
- Orpheus-3B (open, Llama-3.2-3B backbone) supports emotion tags and ~200 ms streaming latency. — [codersera Orpheus vs CSM](https://codersera.com/blog/orpheus-3b-tts-vs-sesame-csm-1b-ai-speech-synthesis-for-emotion-conversational-depth/); [localaimaster Orpheus setup](https://localaimaster.com/blog/orpheus-tts-setup-guide)
- Chatterbox (open, Resemble) has an emotion-exaggeration control on a 0.5B Llama backbone. — [tech-now Chatterbox Multilingual](https://tech-now.io/en/blogs/chatterbox-multilingual-open-source-zero-shot-tts/)

### Inferences
- "How good is it in practice" is only indirectly measured: the Artificial Analysis arena is a preference vote on a prompt's output, so instruction-following quality is folded into the Elo. The models whose marketing centers on direction (Eleven v4, Sonic 3.6, Gemini 3.8 Flash TTS, Qwen-Audio-TTS-Plus) hold the top five Elo slots (see Q8), which is consistent with — but does not prove — better steerability.
- For a kids' game the practical differentiator is whether a *persona* ("excited teenager") can be fixed once at voice-design time (ElevenLabs Voice Design, Hume, Qwen3-TTS VoiceDesign) versus re-specified on every request (instructions). Fixing it once is cheaper and more consistent.

### Gaps
- No independent, published blind test of instruction adherence (e.g., an "emotion correctness" score across vendors) was found. The EmergentTTS-Eval benchmark referenced in Higgs Audio v2's materials (win rates vs gpt-4o-mini-tts) could not be fetched.

## Q5. Voice design from a text description vs cloning from a sample

### Takeaway
Description-to-voice ("voice design") is offered hosted by ElevenLabs (Voice Design), Hume (Octave), MiniMax (Voice Design model) and, open-weights, by Qwen3-TTS-1.7B-VoiceDesign; sample cloning is near-universal (ElevenLabs 10 s instant clone, Cartesia, Fish, Inworld, MiniMax, Azure Custom Neural Voice, Google Chirp 3 Instant Custom Voice at $60/M; open: Qwen3-TTS 3 s, CosyVoice 3, Chatterbox, F5-TTS, IndexTTS2, Fish S1). OpenAI, Polly and Gemini TTS ship preset voices with style control but no cloning or design.

### Cited Findings
- ElevenLabs Voice Design: generate a new voice from attributes (age, gender, accent, style). Eleven v4 instant clone from 10 s of audio. — [sureprompts](https://sureprompts.com/blog/voice-generation-models-compared-2026); [runtimewire](https://runtimewire.com/article/elevenlabs-eleven-v4-turbo-launch)
- Hume Octave "generates custom AI voices with adjustable emotions" from descriptions (launch coverage, Feb 2025). — [VentureBeat on Octave launch](https://venturebeat.com/ai/hume-launches-text-to-speech-model-octave)
- MiniMax ships a dedicated "Voice Design" model alongside Speech 2.6/2.8 (secondary). — [invideo MiniMax family](https://invideo.io/blog/minimax-ai-voice-models/)
- Qwen3-TTS (Apache-2.0, 22 Jan 2026): Qwen3-TTS-12Hz-1.7B-VoiceDesign takes natural-language descriptions of timbre, emotion and prosody; Base models clone from ~3 s of reference audio; nine preset speakers in CustomVoice. — [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS); [neosophie open TTS 2026](https://neosophie.com/en/blog/20260317-tts)
- Google: Chirp 3 Instant Custom Voice $60/M (cloning); Gemini TTS controls style by prompt. — [diyai](https://diyai.io/ai-tools/audio-generation/google-cloud-text-to-speech-pricing/); [speechslide](https://speechslide.com/en/blog/tts-engine-listening-comparison)
- Azure Custom Neural Voice $24/M ($48/M HD) — trained clone with consent. — [texttolab Azure](https://texttolab.com/blog/azure-text-to-speech-pricing)
- CosyVoice 3 (0.5B, Apache-2.0): zero-shot cross-lingual cloning, 9 languages + 18 Chinese dialects. — [neosophie](https://neosophie.com/en/blog/20260317-tts)
- Chatterbox clones from ~5 s; Chatterbox Multilingual v3 covers 25 languages. — [chatterboxai playground](https://chatterboxai.net/playground); [localaimaster Chatterbox v3](https://localaimaster.com/blog/chatterbox-multilingual-v3)

### Inferences
- For a kids' app, design-from-description avoids the consent and policy problems of cloning (see Q10) and produces a voice nobody owns. An open voice-design model (Qwen3-TTS VoiceDesign) can create the persona, after which a smaller on-device model could be fine-tuned on its output — but no source in this session documents that specific pipeline.

### Gaps
- Whether Gemini TTS or OpenAI offer any description-to-voice feature in Oct 2026 was not confirmed (my understanding is both remain preset-voice; treat as unverified).

## Q6. Compute: parameter counts and GPU needs of the open models

### Takeaway
Open TTS models cluster into four size classes: tiny (Piper 15–32M, Kokoro 82M — CPU or any GPU, 12–79x real time on Apple Silicon), small (Chatterbox 0.5B, F5-TTS, Fish S1-mini 0.5B, CosyVoice 3 0.5B, Qwen3-TTS 0.6B — 2–6 GB VRAM, RTF ~0.1 on an RTX 3090), medium (Sesame CSM 1B, Dia 1.6B, IndexTTS2 ~1B, Qwen3-TTS 1.7B, VibeVoice 1.5B — 5–10 GB, RTF 0.3–0.75 on consumer cards, real time on a 4090/5090), and large audio-LLMs (Orpheus 3B ~8 GB quantized, Fish S1 4B, Higgs Audio v2 5.8B, VibeVoice 7B — 16–24 GB, comfortable on a 4090/5090 or any A100/H100). Nothing in the open catalogue needs more than one GPU to run one stream in real time.

### Cited Findings
| Model | Parameters | Source |
|---|---|---|
| Piper (VITS) | ~15–20M medium, 28–32M high variants | [quick-tts Piper voices guide](https://quick-tts.com/blog/piper-voices-ranked.html) |
| Kokoro | 82M; trained ~500 GPU-hours (A100 80GB, ~$400) for v0.19, ~1,000 A100-hours (~$1,000) total | [hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M); [arifsolmaz](https://arifsolmaz.github.io/repo/2026/01/28/kokoro-82m/) |
| XTTS-v2 | 467M, >10,000 training hours | [medium Kokoro-82M](https://medium.com/data-science-in-your-pocket/kokoro-82m-the-best-tts-model-in-just-82-million-parameters-512b4ba4f94c) |
| F5-TTS | base trained 1.2M updates, batch 307,200 frames, >1 week on 8×A100 80G (parameter count not captured; paper reports ~336M — unverified here) | [F5-TTS paper](https://arxiv.org/html/2410.06885v1) |
| Fish Speech / OpenAudio S1 | S1 4B; S1-mini 0.5B (S1 WER 0.008, S1-mini 0.011). Fish-Speech AR trained 1 week on 8×H100 80G plus vocoder 1 week on 8×RTX 4090; Fish Speech 1: 150k hours, 1 week on 16×A800 | [aibase S1-mini](https://news.aibase.com/news/18707); [Fish-Speech paper](https://arxiv.org/html/2411.01156v1); [HF blog Fish Speech 1](https://huggingface.co/blog/lengyue233/fish-speech-1) |
| Chatterbox | 0.5B Llama backbone, 0.5M hours data; Turbo 350M; Nano 110M; Multilingual v3 0.5B | [openspeech Chatterbox](https://www.openspeech.dev/models/chatterbox); [localaimaster v3](https://localaimaster.com/blog/chatterbox-multilingual-v3) |
| Orpheus | 3B (Llama-3.2-3B backbone) | [codersera](https://codersera.com/blog/orpheus-3b-tts-vs-sesame-csm-1b-ai-speech-synthesis-for-emotion-conversational-depth/) |
| Dia | 1.6B; trained on Google TPU Research Cloud grant, hours undisclosed | [nari-labs/Dia-1.6B](https://huggingface.co/nari-labs/Dia-1.6B); [TechTalks](https://bdtechtalks.com/2025/04/24/dia-1-6b-text-to-speech/) |
| Sesame CSM | 1B Llama backbone + small Mimi-code decoder ("1B (1.6B)") | [cloudprice CSM 1B](https://cloudprice.net/models/sesame-csm-1b) |
| Higgs Audio v2 | 3.6B LLM + 2.2B audio DualFFN = 5.8B; Llama-3.2-3B base; >10M hours pretraining; Apache-2.0, Jul 2025 | [bosonai HF README](https://huggingface.co/bosonai/higgs-audio-v2-generation-3B-base/blob/096073c5b8f03d040f6c00a97d7ceb6e807af65f/README.md); [erogol review](https://erogol.com/2025/07/26/higgs-audio-v2-unified-audio-language-modeling-at-scale) |
| VibeVoice | Qwen2.5 LLM 1.5B or 7B + ~340M per acoustic/semantic encoder-decoder; MIT | [VibeVoice tech report](https://arxiv.org/pdf/2508.19205); [arunbaby](https://www.arunbaby.com/speech-tech/0070-vibevoice-multi-speaker-long-form-tts/) |
| Qwen3-TTS | 0.6B and 1.7B; 12 Hz tokenizer; Apache-2.0; 10 languages | [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS) |
| CosyVoice 3 | 0.5B (a 1.5B variant exists per the paper — not confirmed here) | [neosophie](https://neosophie.com/en/blog/20260317-tts) |
| IndexTTS2 | ~1B; IndexTTS-2.5 GPT backbone ~0.8B | [SiliconFlow IndexTTS-2](https://www.siliconflow.com/models/indextts-2); [IndexTeam/IndexTTS-2.5](https://huggingface.co/IndexTeam/IndexTTS-2.5) |
| Magpie-Multilingual (NVIDIA) | 357M (Feb 2026) | [AA leaderboard via search](https://artificialanalysis.ai/text-to-speech/leaderboard) |

- VRAM and real-time factor (RTF = synthesis time / audio duration; <1 is faster than real time): Kokoro runs on CPU or ~3 GB GPU, RTF 0.03 on GPU; Chatterbox 2–3 GB, RTF 0.12 (RTX 4060 Ti) / 0.08 (RTX 3090); F5-TTS ~2 GB, RTF 0.14 / 0.10; Dia ~5 GB, RTF 0.75 (4060 Ti) / 0.48 (3090) / 0.34 (RTX 5090); Orpheus-3B Q8 GGUF ~4 GB on disk, ~8 GB at runtime with SNAC decoder and KV cache, ~200 ms latency. — [localaimaster VRAM by GPU](https://localaimaster.com/blog/voice-ai-vram-requirements-by-gpu); [localaimaster best local TTS](https://localaimaster.com/blog/best-local-tts-models); [localaimaster Orpheus](https://localaimaster.com/blog/orpheus-tts-setup-guide)
- Apple Silicon: Kokoro synthesizes 30 s of speech in 379 ms on a Mac Studio (CoreML, 2x MLX); 12–79x real time across the M-series lineup; M1 Mini 14x real time. MetalRT: 178 ms for a 4-word Kokoro utterance vs 493 ms for mlx-audio. Qwen3-TTS "2B" on an M4 tuned from RTF 0.876 to 0.253. — [mattmireles/kokoro-coreml](https://huggingface.co/mattmireles/kokoro-coreml); [MetalRT speech blog](https://www.runanywhere.ai/blog/metalrt-speech-fastest-stt-tts-apple-silicon); [drmhse Qwen3-TTS on M4](https://www.drmhse.com/posts/tuning-qwen3-tts-apple-silicon-m4/)
- Datacenter serving density: Baseten runs Orpheus-3B at 7 simultaneous real-time streams on an H100 MIG slice before optimization, 16 (24 with stable traffic) after TensorRT-LLM. — [Baseten](https://www.baseten.co/blog/canopy-labs-selects-baseten-as-preferred-inference-provider-for-orpheus-tts-model/)
- vLLM-Omni serves Qwen3-TTS, with voice cloning, at 42.88 audio-seconds per second across 2×H20 GPUs at 64 concurrent requests (up from 26.55 after optimizations; P99 end-to-end latency 17.7 s → 9.0 s). — [vLLM blog, 23 Jun 2026 (blocked; via search)](https://vllm.ai/blog/2026-06-23-vllm-omni-tts); [alphasignal summary](https://alphasignal.ai/news/vllm-omni-squeezes-172-more-audio-out-of-four-speech-models)

### Inferences
- Hardware fit (estimates from parameter counts at bf16 ≈ 2 bytes/param plus codec and KV cache): phone-class (<1 GB, CPU/NPU): Piper, Kokoro, Chatterbox-Nano 110M. Consumer 8–12 GB GPU: everything up to Orpheus 3B (quantized) and Qwen3-TTS 1.7B. RTX 4090/5090 (24/32 GB): all listed models including Higgs Audio v2 5.8B (~12 GB weights) and VibeVoice 7B (~14 GB weights) with headroom. A single A100/H100 80 GB holds any open TTS model several times over; the question there is streams per GPU (7–24 for a 3B model), not fit.
- The only open models for which a phone is plausible today are Piper and Kokoro (and possibly Chatterbox-Nano); the 0.5B class runs on a laptop GPU or Apple Silicon at RTF 0.1–0.3 but is marginal on a mid-range phone.

### Gaps
- Could not fetch the Higgs Audio v2, Orpheus, Dia or CSM model cards (HF blocked) to confirm their stated minimum VRAM; the 24 GB often quoted for Higgs v2 is unverified here.
- F5-TTS and CosyVoice 3 parameter counts came from memory rather than a fetched source; treat as approximate.
- No RTF data found for IndexTTS2 (the "Faster IndexTTS-2" paper, arXiv 2607.21042, Jul 2026, was blocked), VibeVoice 7B, or Higgs v2.

## Q7. Does TTS quality keep scaling with parameters, or plateau? Data vs parameters

### Takeaway
The published evidence says TTS has a step change around 150M→400M parameters and 1K→10K hours ("emergent" prosody/compound-noun/question handling in BASE TTS), then diminishing returns; data studies put the data plateau near 100K hours per language for 0.5–1B models. Kokoro (82M, <100 h training for v0.19) topping TTS Arena in Jan 2025/2026 shows naturalness on short, read-style text saturates at tiny scale; what larger audio-LLMs buy is expressiveness, instruction-following, long-form coherence and multi-speaker dialogue, not basic naturalness.

### Cited Findings
- BASE TTS (Amazon, Feb 2024; ~1B params, 100K hours): "the scaling from 1K to 10K hours and 150M to 400M parameters appears to be the critical threshold for emergent abilities"; from BASE-medium to BASE-large, "continued but diminishing improvement is observed in all categories except compound nouns, where performance has saturated." — [BASE TTS, arXiv 2402.08093](https://arxiv.org/pdf/2402.08093v2); [alphaxiv summary](https://www.alphaxiv.org/abs/2402.08093)
- Emilia dataset paper (Jan 2025): "significant gains are observed when scaling up to 46k hours; beyond this point, improvements continue but become less substantial and tend to plateau around 100k hours. For TTS models containing around 0.5–1 billion parameters, a dataset of approximately 100k hours per language appears to be the most cost-effective choice." — [Emilia, arXiv 2501.15907](https://arxiv.org/pdf/2501.15907)
- A synthetic-data TTS study (Dec 2025) identifies two regimes: a variance-limited phase where more data helps, then a resolution-limited regime where "the TTS model's complexity limits further usefulness." — [arXiv 2512.17356](https://arxiv.org/html/2512.17356v1)
- Kokoro-82M, trained on <100 hours of audio, ranked #1 in the TTS Spaces Arena ahead of XTTS v2 (467M, >10K h), MetaVoice (1.2B, 100K h) and Fish Speech (~500M, ~1M h); commentary: "suggesting a steeper scaling law for TTS models than previously thought." Later snapshot: Kokoro v1.0 at Elo 1056, 32nd overall, 54.4% win rate over 5,368 appearances. — [medium Kokoro-82M](https://medium.com/data-science-in-your-pocket/kokoro-82m-the-best-tts-model-in-just-82-million-parameters-512b4ba4f94c); [texttolab Kokoro review](https://texttolab.com/blog/kokoro-tts-review); [arifsolmaz](https://arifsolmaz.github.io/repo/2026/01/28/kokoro-82m/)
- At the other extreme: Higgs Audio v2 (5.8B) pretrained on >10M hours; Fish Speech on ~1M hours; VibeVoice's 7B LLM exists mainly for 90-minute, 4-speaker long-form generation enabled by an ultra-low-frame-rate tokenizer. — [erogol Higgs v2](https://erogol.com/2025/07/26/higgs-audio-v2-unified-audio-language-modeling-at-scale); [arunbaby VibeVoice](https://www.arunbaby.com/speech-tech/0070-vibevoice-multi-speaker-long-form-tts/)
- Qwen3-TTS-1.7B-Base reports SEED-TTS WER 0.77 (zh) / 1.24 (en) and claims to outperform MiniMax-Speech, ElevenLabs and CosyVoice 3 on English content consistency; speaker similarity 0.8+ across most language pairs (vendor benchmark). — [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS)
- Arena evidence of small-but-good: NVIDIA Magpie-Multilingual 357M (Elo 1065) and Kokoro 82M (Elo ~1056–1062) sit within ~60 Elo of Fish S2 Pro (Elo ~1117–1123, 4B-class) and above VibeVoice 7B (Elo 969 on the open leaderboard). — [AA leaderboard via search](https://artificialanalysis.ai/text-to-speech/leaderboard); [offlinetts ranking 2026](https://offlinetts.com/blog/tts-model-ranking-2026/); [SiliconFlow open TTS guide](https://www.siliconflow.com/articles/best-open-source-text-to-speech-models)

### Inferences
- TTS does not follow a clean LLM-style power law in public evidence. Intelligibility and naturalness of read speech saturate below 1B parameters; the Elo gains above that (Breeze TTS 2 at 1216, Eleven v4 at ~1320) come with larger audio-LLM backbones but also with proprietary data, RLHF-style preference tuning and tag/instruction training, so parameters alone cannot be isolated as the cause. A 7B model (VibeVoice) scoring below an 82M model (Kokoro) in the arena is direct evidence that parameters are not sufficient.
- Where scale plausibly matters most for Math City: following a persona instruction consistently, pronouncing arbitrary math expressions ("3/4", "7 × 8", "x squared") correctly, and emotional range. Where it does not: clearly reading a fixed short prompt, which Kokoro-class models already do at arena-competitive quality.

### Gaps
- No 2025–2026 paper was found that reports a controlled parameter-scaling sweep at fixed data (BASE TTS, Feb 2024, remains the main public source). Vendor papers (Inworld TTS-1 technical report, arXiv 2507.21138) could not be fetched.

## Q8. Where multi-GPU matters in TTS (training, throughput serving, tensor parallel), and whether one utterance ever benefits from more than one GPU

### Takeaway
Multi-GPU in TTS is for training (8×A100 for >1 week for F5-TTS; 8×H100 + 8×4090 for Fish-Speech; 16×A800 for Fish Speech 1) and for serving more concurrent streams (16–24 Orpheus streams per H100; ~43 audio-s/s of Qwen3-TTS on 2×H20). No open TTS model is large enough to need tensor parallelism for a single utterance, and practitioner reports show TTS pipelines bottleneck on orchestration and the codec/vocoder stage rather than GPU compute — a vLLM-Omni issue shows throughput capping at ~12 streams with the accelerator 26% utilized, and splitting stages across two chips gained only ~9%.

### Cited Findings
- Training compute disclosed by open models: F5-TTS >1 week on 8×A100 80G; Fish-Speech AR 1 week on 8×H100 80G plus vocoder 1 week on 8×RTX 4090; Fish Speech 1 (150K h) 1 week on 16×A800; Kokoro ~500 A100-hours (v0.19) / ~1,000 A100-hours total; Dia 1.6B on a TPU Research Cloud grant (hours undisclosed); Muyan-TTS trained on a ~$50K budget. — [F5-TTS](https://arxiv.org/html/2410.06885v1); [Fish-Speech](https://arxiv.org/html/2411.01156v1); [HF Fish Speech 1](https://huggingface.co/blog/lengyue233/fish-speech-1); [hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M); [TechTalks Dia](https://bdtechtalks.com/2025/04/24/dia-1-6b-text-to-speech/); [Muyan-TTS](https://arxiv.org/pdf/2504.19146)
- vLLM project (Jun 2026): "Serving TTS isn't the same problem as serving an LLM. It has to hit a first-audio budget of a few hundred ms, keep audio continuous across streaming chunks, and sustain enough concurrent streams per GPU to keep serving cost down. It's also a multi-stage pipeline where each stage bottlenecks differently, so no single recipe carries across models." — [vLLM on X](https://x.com/vllm_project/status/2071427198947639757)
- vLLM-Omni Qwen3-TTS optimizations were about moving per-request Python state machines into GPU-resident batched tensors, reducing device-to-host syncs, decoupling connector chunking from the Code2Wav decode window and batching Stage-0 decode preprocessing: 26.55 → 42.88 audio-s/s (+61.5%) on 2×H20 at 64 concurrent requests. — [vLLM blog (via search)](https://vllm.ai/blog/2026-06-23-vllm-omni-tts); [alphasignal](https://alphasignal.ai/news/vllm-omni-squeezes-172-more-audio-out-of-four-speech-models)
- A vLLM-Omni issue (Qwen3-TTS streaming on an Ascend 910B4): throughput plateaus at ~12 concurrent sessions with 26% AICore utilization, 4–9% HBM bandwidth, 2% CPU; "every resource we can measure is idle, the pipeline is roughly three orders of magnitude away from being compute-bound, and yet throughput stops scaling at 12." A second replica on the same chip cut first-audio latency 25.7% without raising throughput; splitting pipeline stages across two chips gained ~9%. — [vllm-omni issue #7993](https://github.com/vllm-project/vllm-omni/issues/7993)
- A related RFC proposes cross-request batching for the Qwen3-TTS Code2Wav (codec decode) stage because TTFB degrades under concurrency. — [vllm-omni issue #3163](https://github.com/vllm-project/vllm-omni/issues/3163)
- vLLM's generic multi-GPU path is `tensor_parallel_size`, which applies to any model it serves including TTS backbones. — [vLLM distributed serving docs](https://docs.vllm.ai/en/v0.8.0/serving/distributed_serving.html)
- Baseten Orpheus-3B: 7 → 16–24 simultaneous real-time streams per H100 MIG slice after TensorRT-LLM optimization; TTFB 200 ms (MIG) / <150 ms (full H100). — [Baseten](https://www.baseten.co/blog/canopy-labs-selects-baseten-as-preferred-inference-provider-for-orpheus-tts-model/)
- Hosted vendors' scale is throughput: Azure runs 600–700+ voices across 150+ locales; ElevenLabs v4 covers 90+ languages — these are catalog/data-center facts, not per-request multi-GPU facts. — [blipradar](https://blipradar.com/microsoft-azure-tts); [runtimewire](https://runtimewire.com/article/elevenlabs-eleven-v4-turbo-launch)

### Inferences
- Per-utterance benefit from multiple GPUs: none demonstrated for any open model. The largest open TTS backbones (Higgs Audio v2 5.8B, VibeVoice 7B) fit on one 24 GB consumer card in bf16, so tensor parallelism is unnecessary for fit; and autoregressive TTS at 12–50 tokens/s of audio is latency-bound by sequential decoding plus a codec stage, where TP's inter-GPU sync adds latency rather than removing it. The one place a second GPU could help a single stream is pipeline placement (LLM on one device, codec/vocoder on another) and the field report above measured that at ~9%.
- Where frontier hosted models could be multi-GPU per request: only if a proprietary TTS backbone is far larger than anything open (tens of billions of parameters). No vendor has disclosed parameter counts for Eleven v4, Sonic 3.6, Gemini TTS, Octave 2 or Speech 2.6, so this cannot be confirmed or ruled out; Gemini TTS presumably shares infrastructure with Gemini Flash-class LLMs (inference from the model naming, not a sourced fact).
- For Math City the practical reading: datacenter GPUs buy concurrency (streams per dollar) and training runs, not better individual sentences. A single 4090-class card can serve roughly a dozen simultaneous Orpheus/Qwen3-TTS streams, i.e. tens of thousands of short prompts per hour — more than enough to pre-render a whole curriculum overnight.

### Gaps
- Could not fetch the vLLM-Omni design doc or TensorRT-LLM TTS examples to confirm whether the 2×H20 Qwen3-TTS setup was tensor-parallel or two replicas; the issue report suggests replicas/stage-splitting are the paths being explored.
- No frontier vendor discloses model size or per-request GPU topology.

## Q9. Evidence of the quality gap between tiers (arena Elo, MOS, blind tests)

### Takeaway
On the Artificial Analysis Speech Arena (late Sep 2026 snapshots), the top proprietary models sit at Elo ~1260–1320 (Eleven v4 1319–1321, Qwen-Audio-3.1-TTS-Plus 1292, Sonic 3.6 1276–1278, Gemini 3.8 Flash TTS 1267–1275), the best open-weights model (Breeze TTS 2) at 1216, Fish S2 Pro ~1117–1123, and Kokoro 82M at ~1056–1062. Converting Elo gaps to blind-vote win probability: 100 points ≈ 64%, 200 ≈ 76%, 260 ≈ 82%. So a listener prefers Eleven v4 over Kokoro in roughly 4 of 5 head-to-heads, but over the best open model only ~64% of the time.

### Cited Findings
- AA Speech Arena, provider-voice leaderboard (late Sep 2026): 1. Eleven v4 1319–1321; 2. Qwen-Audio-3.1-TTS-Plus 1292; 3. Cartesia Sonic 3.6 1276–1278; 4. Gemini 3.8 Flash TTS 1267–1275; 5. Qwen-Audio-3.0-TTS-Plus 1261. Rankings use Elo from blind pairwise user votes. — [AA leaderboard (via search snippets)](https://artificialanalysis.ai/text-to-speech/leaderboard); [progressiverobot on Eleven v4](https://www.progressiverobot.com/2026/09/28/eleven-v4-turbo-elevenlabs-tops-tts-arena/); [cellcog](https://cellcog.ai/blog/eleven-v4/)
- Open-weights ranking (same leaderboard, 2026): Breeze TTS 2 1216; Fish Audio S2 Pro 1117 (another snapshot: 1123); Step Audio EditX (Mar 2026) 1095 (1111); Voxtral TTS 1083 (1067); Magpie-Multilingual 357M (Feb 2026) 1065; Kokoro 82M v1.0 1062 (1056, 32nd overall, 54.4% win rate, 5,368 appearances); VibeVoice 7B 969. Two snapshots differ by ~10–20 points, which indicates the leaderboard's week-to-week drift. — [AA leaderboard](https://artificialanalysis.ai/text-to-speech/leaderboard); [offlinetts ranking 2026](https://offlinetts.com/blog/tts-model-ranking-2026/); [texttolab Kokoro review](https://texttolab.com/blog/kokoro-tts-review); [SiliconFlow](https://www.siliconflow.com/articles/best-open-source-text-to-speech-models)
- AA also launched a "Controlled Voice Arena" that clones the same 8 voices into every model to separate voice-identity preference from model quality (2026). Cartesia says Sonic 3.6 led both arenas in Aug 2026. — [Artificial Analysis on X](https://x.com/ArtificialAnlys/status/2074886571166462405?lang=en); [MarkTechPost Sonic 3.6](https://www.marktechpost.com/2026/08/18/cartesia-ships-sonic-3-6-a-streaming-tts-model-that-now-leads-both-artificial-analysis-speech-arenas/); [llm-stats Controlled Voice Arena](https://llm-stats.com/benchmarks/aa-controlled-voice-arena)
- Earlier history: Kokoro-82M hit #1 on the Hugging Face TTS Arena (Jan 2025 per most sources; one source says Jan 2026) over XTTS v2, MetaVoice and Fish Speech; TTS Arena V2 (TTS-AGI) continues as a Bradley-Terry Elo arena. — [medium Kokoro](https://medium.com/data-science-in-your-pocket/kokoro-82m-the-best-tts-model-in-just-82-million-parameters-512b4ba4f94c); [TTS-Arena-V2 about page](https://huggingface.co/spaces/TTS-AGI/TTS-Arena-V2/blob/e00d01fe926817d3d0b1c43975ef9692874e031b/templates/about.html)
- Hugging Face's Open TTS Leaderboard (2025–26) scores models on objective metrics (WER, speaker similarity, quality estimators, RTF) rather than votes; details could not be fetched. — [HF Open TTS Leaderboard blog](https://huggingface.co/blog/open-tts-leaderboard)
- Vendor-run comparisons: Inworld claims MiniMax Speech 2.6 HD is 80 Elo lower at 4x the price; Telnyx published early MiniMax-vs-ElevenLabs benchmarks; Speechify claimed #1 for Simba 3.2 at an earlier date. — [Inworld (blocked)](https://inworld.ai/resources/best-voice-ai-tts-apis-for-real-time-voice-agents-2026-benchmarks); [Telnyx](https://telnyx.com/resources/minimax-speech-2-6-vs-elevenlabs-tts-benchmarks); [PRWeb Simba](https://www.prweb.com/releases/speechifys-simba-3-2-ranks-1-on-independent-artificial-analysis-tts-leaderboard-worlds-best-real-time-voice-model-above-elevenlabs-openai-google-deepmind--others-302819731.html)
- Coval's independent benchmark argues that "vendor benchmarks lie" and measures latency and WER directly. — [Coval blog](https://www.coval.ai/blog/best-text-to-speech-providers-in-2026-how-to-choose-(and-why-vendor-benchmarks-lie)/)

### Inferences
- Elo → win probability uses P(A beats B) = 1 / (1 + 10^(−Δ/400)). Eleven v4 (1320) vs Breeze TTS 2 (1216): Δ=104 → 64%. Vs Fish S2 Pro (1120): Δ=200 → 76%. Vs Kokoro (1060): Δ=260 → 82%. Vs VibeVoice 7B (969): Δ=351 → 88%. Mid-tier hosted models (Deepgram, Polly Generative, Azure Neural) were not in the captured snapshots, but Sonic 3.6 vs Kokoro (Δ≈216) → 78%.
- Cost-per-Elo framing: Kokoro delivers ~80% of the leader's Elo (1060/1320) at <1% of the price ($0.62 vs $80/M). The open-weights gap to the frontier (~100 Elo) is now smaller than the gap between the frontier and most $16–30/M cloud-provider voices was in 2024–25 (my inference; the arena did not list those older tiers in captured snapshots).
- Arena votes are on general-purpose prompts with adult-oriented voices; no public arena measures child-listener preference or pedagogical clarity, so for a kids' app the gap could be smaller (clear short prompts) or larger (expressive encouragement) than the Elo suggests.

### Gaps
- The full AA table (prices, latency columns, vote counts, date stamps) could not be fetched; snapshots came from third-party articles dated May–Sep 2026 and differ by 10–20 Elo.
- No MOS-scale (1–5) blind study comparing 2026 hosted models to open models was found; vendor papers report MOS only against their own baselines.

## Q10. Policy and ethics for a kids' app: child-use restrictions, COPPA handling, offline fallback

### Takeaway
Most expressive-TTS vendors forbid children as users: ElevenLabs bars under-18s, prohibits "bundled solutions that target anyone under the age of 13", and bans any children's voice data; Hume requires users to be 18+; OpenAI requires zero-data-retention and COPPA compliance for apps processing under-13 personal data. The cloud providers (Google, Azure, AWS) have no TTS-specific child ban but expect the developer to carry COPPA obligations and (Microsoft) to disclose synthetic voices to parents. Pre-rendering app-authored text server-side and bundling the audio sends no child data to any vendor, which sidesteps every data-handling clause; the "bundled solution targeting under-13" clause is the one that still needs legal reading for ElevenLabs.

### Cited Findings
- ElevenLabs Terms: services "not intended for or directed at children under the age of 18"; ElevenLabs "does not knowingly collect, store, or process Personal Data from children under the age of 18." Prohibited Use Policy forbids "making their Services available to anyone under the age of 13, or anyone between the ages of 13–18 without first obtaining parental or guardian consent, or otherwise using their Services to make available bundled solutions that target anyone under the age of 13", and forbids uploading "Voice Data from children under the age of 18". — [ElevenLabs Prohibited Use Policy](https://elevenlabs.io/use-policy); [ElevenLabs Terms](https://elevenlabs.io/terms-of-use); [ElevenLabs Privacy Policy](https://elevenlabs.io/privacy-policy)
- OpenAI under-18 API guidance: processing personal data of children under 13 (or the local age of digital consent) requires implementing zero data retention first; organizations serving minors must comply with child protection and privacy laws including COPPA. — [OpenAI Under-18 guidance](https://developers.openai.com/api/docs/guides/safety-checks/under-18-api-guidance); [OpenAI community: children under 13 restriction](https://community.openai.com/t/children-under-13-restriction/754816)
- Hume: users must be at least 18; Hume "does not knowingly collect data from individuals under 13". — [Hume Terms of Use](https://www.hume.ai/terms-of-use); [Hume Acceptable Use Policy](https://www.hume.ai/acceptable-use-policy)
- Microsoft Azure TTS transparency note: when a use case "may be used in situations involving minors and children", Microsoft recommends disclosure to parents, and "if a use case is intended for minors or children, the disclosure must be clear and transparent so that parents or legal guardians can understand the role of synthetic media." Azure Speech also has a TTS Code of Conduct. — [Azure TTS transparency note](https://learn.microsoft.com/en-us/azure/foundry/responsible-ai/speech-service/text-to-speech/transparency-note); [Microsoft AI Services Code of Conduct (TTS)](https://learn.microsoft.com/en-us/legal/cognitive-services/speech-service/text-to-speech/code-of-conduct)
- Google Cloud publishes a COPPA compliance page (framed around Workspace for Education; schools must obtain parental consent); nothing TTS-specific restricts child audiences. — [Google Cloud COPPA compliance](https://cloud.google.com/security/compliance/coppa)
- General COPPA guidance for voice: companies may convert children's voice to text and immediately delete it, but may not use that window for anything else; TTS output contains no child data by construction. — [FAS: Strengthening Children's Online Voice Privacy](https://fas.org/publication/childrens-online-voice-privacy/); [Promise Legal COPPA guide 2025](https://blog.promise.legal/startup-central/coppa-compliance-in-2025-a-practical-guide-for-tech-edtech-and-kids-apps/)
- Open-model licenses relevant to bundling: Kokoro, Qwen3-TTS, CosyVoice 3, Higgs Audio v2 are Apache-2.0; VibeVoice and Chatterbox are MIT. — [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS); [neosophie](https://neosophie.com/en/blog/20260317-tts); [arunbaby VibeVoice](https://www.arunbaby.com/speech-tech/0070-vibevoice-multi-speaker-long-form-tts/); [localaimaster Chatterbox](https://localaimaster.com/blog/chatterbox-tts-setup-guide)

### Inferences
- Live, per-request hosted TTS in a kids' app is problematic with ElevenLabs and Hume by their own terms, and requires ZDR plus COPPA diligence with OpenAI; Google/Azure/AWS are workable with developer-side COPPA compliance and (for Azure) parent-facing disclosure. Since TTS requests carry only app-authored text, the actual personal data exposed is IP address/device metadata, which is what a ZDR or no-logging arrangement addresses.
- Pre-render-and-bundle (the developer calls the API from a build machine, ships audio files) keeps children off the vendor's service entirely; the remaining question for ElevenLabs is whether shipping its audio inside a product for under-13s counts as a "bundled solution that targets" under-13s — that clause reads as if it does, so ElevenLabs-generated audio in Math City needs a licensing answer from ElevenLabs or should be avoided. No other vendor's captured terms contain an equivalent clause.
- Offline fallback: an on-device Apache/MIT model (Kokoro/Piper today; Qwen3-TTS-0.6B or Chatterbox-Nano on strong tablets) or bundled pre-rendered audio is the only way to guarantee speech with no network and no data flow, which aligns with Math City's free-offline positioning.

### Gaps
- Could not fetch ElevenLabs' current policy text directly (egress blocked) to check whether the "bundled solutions" clause has an exception for pre-rendered output; needs direct legal review of the live page.
- No Cartesia, MiniMax, Inworld, Fish or Deepgram child-use terms were captured.
- Whether Google Chirp 3 HD / Gemini TTS or Amazon Polly offer contractual ZDR for TTS requests was not confirmed.
