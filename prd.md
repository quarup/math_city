# Math City — Product Requirements Document

**Math City** is a mobile game for Android and iOS that makes math practice fun for kids. Multiple players can share a single device, each with their own profile and progress.

**Target audience:** Kids ages 6–14, with math content spanning grades K–8.

**Platform:** Cross-platform mobile (iOS + Android), built with Flutter and the Flame game engine.

**Business model:** Completely free — no ads, no in-app purchases, no subscriptions. All content, assets, and libraries used must be compatible with free, non-commercial educational use (open licenses preferred).

**Compliance:** Designed for ages 6–14, the app must satisfy children's-app requirements on both stores: no third-party tracking, no data collection beyond local profiles, no behavioral advertising. Privacy policy required. Apple "Made for Kids" and Google "Designed for Families" guidelines apply.

**Accessibility:** Baseline a11y is in scope from the start — color-blind-safe palette (the wheel relies heavily on color, so segments must also be distinguishable by shape/icon), readable type at small sizes, audio cues for key feedback (so a 6-year-old who isn't yet reading fluently can play), respect for OS-level text-size settings. Optional dyslexia-friendly font (e.g. OpenDyslexic) toggle is a stretch goal for Phase 10 (polish).

**Localization:** v1 ships English-only. All user-facing strings must be externalized (no hardcoded text in widgets) so future translation is mechanical, not a rewrite.

---

## Success Metrics

These focus on learning outcomes, not time-on-app:

- **Concept progression:** % of players who advance at least one concept from "challenging" to "comfortable" within their first 5 sessions
- **Accuracy improvement:** wrong-answer rate per concept decreases over successive attempts (player is actually learning, not just guessing)
- **Breadth of practice:** average number of distinct concept categories practiced per week (kids are exploring, not grinding one concept)
- **Challenge engagement:** % of correct answers that are challenging-band (5 🧱) questions — higher = player is being appropriately stretched
- **Retention through learning:** D14 retention among players who advanced at least one concept level (learning = reason to return)

---

## Player Creation & Profile

When the app opens, the player selects their profile or creates a new one.

**Creating a new player:**
- Enter a name
- Select starting school grade (K–8)
- Customize an avatar: pick from a curated set of slot options (hair style/color, skin tone, eyes, mouth, glasses, earrings, optional features like blush/freckles). The avatar is a 2D illustrated character rendered by the [DiceBear](https://www.dicebear.com/) Adventurer style — see [plan.md](plan.md) Locked Decisions for details.

The avatar is **free to customize and re-edit at any time** from the profile picker — it is not tied to the in-game economy.

Multiple player profiles can exist on one device with no login required. [Assumption: no account/auth on first version; cloud save is opt-in — see *Saving User Data*]

---

## Gameplay Loop

Each **round** follows this sequence:

1. **Player select** — The current player can hand the device to another player at the start of any round.
2. **Spin the wheel** — A colorful wheel displays 4–8 math concepts (selected from a larger pool, weighted toward concepts the player needs to practice). Player taps to spin.
3. **Answer a question** — A question in the landed concept category appears at the player's current level for that concept.
4. **Result:**
   - **Correct answer at regular difficulty:** +3 🧱 bricks, celebratory animation/sound.
   - **Correct answer at challenge difficulty** (near the edge of their ability): +5 🧱 bricks, bigger celebration.
   - **Wrong answer:** 0 🧱. A friendly step-by-step explanation guides the player to the correct answer. No penalty — the game stays encouraging.
   - **Band-crossing bonus:** if this correct answer pushes the concept's proficiency across a band-boundary threshold for the first time (e.g. from challenging into comfortable), the player also earns +1 🔬 research with a distinct celebratory animation. Awarded at most once per concept per threshold.
5. Return to step 1.

### Answer Input

Input method is tied to the player's proficiency band for that concept:

- **Challenging band** → **Multiple choice** (4 options). Distractors are plausible (e.g. off-by-one, common conceptual mistakes). Reduces friction when the concept is unfamiliar.
- **Comfortable band** → **Typed numeric answer**. No hints from distractors; tests genuine recall and reinforces fluency.

This means the same player might type answers for concepts they've mastered and pick from options for concepts they're still developing.

### Timer

No hard timer in v1. After ~20 seconds of inactivity, the character plays a gentle "thinking" animation as a nudge — but the player can take as long as they need. A timed-mode toggle is out of scope for v1 (see *Out of Scope*).

### Multiplayer Turn Structure
When multiple players share a device, they **alternate rounds** in a single session (Player A spins → Player B spins → ...). Each player's 🧱 / 🔬 balances and concept data update independently. A per-session leaderboard shows how many 🧱 each player earned this session.

---

## Concept System & Adaptive Difficulty

The game tracks proficiency at the **sub-concept** level — not at broad category level — because a kid who's mastered single-digit addition has not necessarily mastered multi-digit addition, and the wheel needs to surface the right granularity.

### Two-level taxonomy: Categories → Concepts

**Categories** are how proficiency is *displayed* to the player (and how the wheel groups options visually). **Concepts** are what proficiency is *tracked* against and what the wheel selects. One category contains many concepts.

The full K–8 taxonomy — 12 top-level categories and ~361 sub-concepts, anchored on the US Common Core State Standards for Mathematics — lives in **[curriculum.md](curriculum.md)**. That document is the canonical source for concept IDs, prerequisite relationships, target grade, question-source strategy, and diagram requirements.

Top-level categories: Counting & Number Sense; Place Value & Number Properties; Addition & Subtraction; Multiplication & Division; Fractions; Decimals & Percentages; Ratios & Proportions; Measurement, Time & Money; Geometry & Shapes; Integers & Rational Numbers; Pre-Algebra (Expressions, Equations, Functions); Data, Statistics & Probability.

The wheel surfaces individual **sub-concepts** (e.g. "2-digit addition with carry"), not categories. The Player Progress screen rolls sub-concept data up to **categories** for a digestible at-a-glance view, with drill-down to see the per-sub-concept detail.

### Adaptive Logic

Each sub-concept has a **proficiency level** (e.g. 0.0–1.0) per player, updated after every answer:
- Correct answer → proficiency increases
- Wrong answer → proficiency decreases slightly (floor at 0)

**Grade is for initialization only.** A player's stated grade level seeds initial proficiency for sub-concepts at and below that grade. After initialization, the system advances the player along the **prerequisite DAG defined in [curriculum.md](curriculum.md)** — when a sub-concept reaches `mastered`, its DAG children become eligible to surface on the wheel. There is **no cross-domain gating**: a kid who's advanced in arithmetic but behind in geometry will see both branches advance independently. Kids who excel at visual concepts but struggle with word problems (or vice versa) progress at their own pace per branch.

Based on proficiency, each sub-concept is classified into one of four bands:

| Band | Condition | Action |
|---|---|---|
| **Mastered** | Player has demonstrated reliable correctness | Excluded from wheel; DAG children become eligible to surface |
| **Comfortable** | At fluency, but not yet mastered | Included; correct = 3 🧱; typed numeric input |
| **Challenging** | Newly introduced or partially understood | Included with lower probability; correct = 5 🧱; multiple choice |
| **Not yet** | Prerequisites not yet mastered, OR concept is far from the player's current frontier | Excluded from wheel |

The wheel at any given round contains a **mix of comfortable + challenging** concepts across whichever branches the player is currently advancing on, so the player always has a chance to earn 5-🧱 (challenging-band) questions but isn't overwhelmed.

### Question Generation

Questions must feel **infinite and varied**. The strategy is hybrid, chosen per sub-concept (see [curriculum.md](curriculum.md) for the per-sub-concept assignment):

- **Algorithmic generators** — bounded random parameters, computed answers, templated wording variation, deterministic step-by-step explanations. Covers ~85% of K–8 content (all arithmetic, fractions, percent, equations, signed numbers, etc.). Effectively infinite, near-zero storage cost.
- **Procedural diagram widgets** — for geometry, fractions-as-shapes, clocks, coordinate planes, etc., a small set of parameterized Flutter widgets (`FractionBar`, `Clock`, `CoordinatePlane`, etc.) renders the figure on the fly from the question's parameters. Diagrams are not bundled images.
- **Curated bundled datasets** — for reasoning-heavy content where templates would produce nonsense (multi-step real-world word problems, statistical-question recognition, qualitative graph descriptions). Sourced exclusively from permissively-licensed datasets (MIT / Apache 2.0 / CC-BY): DeepMind `mathematics_dataset`, GSM8K, MathDataset-ElementarySchool, MathQA, SVAMP. CC-BY-NC content is excluded (commercial-distribution risk on app stores).
- **Hand-curated gap-fills** — ~1500 items authored by humans to fill gaps where no open dataset has age-appropriate K–2 coverage or specific edge cases.

Each question carries a step-by-step explanation shown on wrong answers — algorithmically templated for generators, hand-or-AI-authored for dataset items.

**Critical constraint:** No cloud LLM calls at runtime. **Offline batch LLM generation is also off the table for v1** — first see how far algorithmic generation + datasets get us. This keeps the app free, offline-capable, and avoids per-user API costs.

---

## Cosmetics System

Players earn in-game currency by answering math questions correctly. All currency is spent on **the city builder only** — no gameplay advantage is purchasable, and the app is entirely free; currency cannot be purchased with real money.

**Two currencies (locked Phase 7, 2026-05-23):**

- 🧱 **Bricks** — the spending currency. Earned per correct answer. Spent to *place* buildings (and later: expand land, run city events).
- 🔬 **Research** — the unlocking currency. Earned when a math concept's proficiency crosses a band-boundary threshold for the first time (e.g. when a sub-concept moves from the "challenging" band into the "comfortable" band). Spent to *unlock new building types* — once researched, a building type appears permanently in the player's build menu, subject only to its brick cost on each placement. The player chooses which available building to research next, so research credit functions as a literal credit balance the player tallies up over time.

The two-currency design splits "I worked hard at math today" (bricks for any correct answer) from "I genuinely learned a new piece of math" (research for crossing a proficiency band). Both feed the city builder, but the research currency ties new content unlocks to real learning progress rather than raw practice volume. The number of band-crossing thresholds is configurable in code (v1 ships 2 thresholds per concept), so the research-earning rate can be tuned post-launch without a schema migration. See [plan.md](plan.md) *Domain Specs / Research-currency earning*.

The avatar is *not* part of the economy: players customize it freely (see *Player Creation & Profile*) and can re-edit anytime. The Phase 4 spike showed that no off-the-shelf Flutter avatar library combines full-body rendering with rich purchasable accessory slots, so the design was simplified to a single long-arc spending sink: the city builder. See [plan.md](plan.md) Locked Decisions for the full reasoning.

### City Builder

Each player has their own persistent city, accessed from a dedicated **"My City"** screen. The city is built on an isometric tile grid and is **purely cosmetic** — it does not affect math gameplay. Its purpose is to give players a long-running creative project that visualizes how far they've come, paced by a story of citizens reacting to what they build.

The design ambition is **"feels infinite"**: hundreds of building types over the long arc of the catalog, each with a place in a content-rich progression — not a flat list of 10–15 buildings gated by a single 🧱 threshold. Buildings are organized into four roles, **all of which contribute to city growth**:

| Category | Examples | Role |
|---|---|---|
| **Civic core & housing** | mayor's office; single home, apartment, high rise; school | Provides population capacity and the seed of the city. The mayor's office is the player's *first* build — the city starts empty, no free placement |
| **Services** | clinic, hospital, veterinarian, power plant, gas station, waste management, fire station | Gates further growth via aggregate ratios (1 clinic per N residents, 1 power plant per N, etc.). Missing a needed service stalls growth |
| **Commercial** | grocery, clothing store, bike shop, restaurants, coffee shop, car dealership | Variety multiplies growth — a city with only one commercial type stalls or shrinks; introducing each new commercial subtype unlocks a small growth boost |
| **Entertainment** | playground, park, cinema, amusement park | Same variety effect as commercial. Cities top-heavy in entertainment without supporting services or housing draw complaints rather than residents |

**Unlock model — a branching DAG plus a research spend.** A building type becomes *available to research* when a combination of conditions is met (any combination of the following):

- *Lifetime bricks threshold* — enough lifetime 🧱 earned to date.
- *Prerequisite buildings placed* — e.g. a hospital requires at least one clinic and apartment-tier-2 already on the map (multi-parent prereqs use AND semantics, kept narratively coherent — we don't add prereqs that would feel random).
- *Population minimum* — e.g. the cinema only becomes available once the city passes 50 residents.
- *Story beat completed* — a citizen request has surfaced (the player doesn't need to explicitly accept it, but the beat must have appeared at least once).

Once available, the player **spends 🔬 research credit** to actually unlock the building — at which point it's permanently in the build menu and can be placed any number of times for its 🧱 brick cost. Research is finite and earned by genuine learning progress (band-crossings on the math curriculum), so the player has to choose which available building to research next — that choice IS the player's progression decision.

Because the DAG is branching, different players will follow different paths — one player might invest heavily in commercial variety before unlocking advanced healthcare, another might push housing density first. The UI is **discovery-based, not a visible tech tree** — buildings not yet available-to-research don't appear in the research panel at all; the next thing to research is hinted at via citizen requests (see below), and available buildings appear in the research panel when their gates are met. This keeps new players from feeling overwhelmed and preserves the surprise of each unlock.

**Citizen requests — floating emoji bubbles.** The city screen surfaces what citizens want and what they're celebrating, via cute emoji / sticker bubbles that float above the buildings:

- Bubbles use simple visual language — a 🏥 over a head for "we need healthcare", a 🎉 over a coffee shop after it opens, a 🚮 over a pile for "the trash situation is getting out of hand". Tapping a bubble expands it into a full sentence explaining the citizen's request or feeling.
- Tone is mixed — kid-friendly silly ("Mrs. Pomeroy's cat ate a sock — we need a vet!") sits alongside slightly less cutesy civic notes ("The neighborhood is tired of stepping over garbage — we need a Waste Management facility!"). The mix keeps it interesting for the older end of the 6–14 range.
- **Both demands and praise.** Bubbles show needs ("we want a park") but also positive feedback ("citizens love the new bakery", "the garbage gets collected on time now"). Praise bubbles validate recent placements; demand bubbles hint at what's available or about to unlock.
- **Max ~5 bubbles on screen at once.** Unacknowledged bubbles rotate — if the player doesn't act on one, it disappears for a while and may resurface later. Bubble state persists across sessions (a request the player ignored last night can still be there tomorrow, or come back in a different form).
- **Story beats can recur even after a building is unlocked or built** — e.g. "we want more parks" can fire repeatedly as the city grows, even when a park already exists. Each beat has its own pacing rules to avoid spamming.

**Beat trigger conditions** combine several inputs (all optional per beat):

- *Buildings present* — the beat only fires once a prerequisite mix exists (citizens don't demand a shopping mall before the city has a variety of small shops).
- *Buildings absent / under-served* — the inverse: a beat about needing healthcare only fires while healthcare is missing or insufficient for the current population.
- *Population minimum* — keeps low-end-of-DAG beats from firing in the first few minutes.
- *Building age* — some beats only fire N rounds after a specific building was placed ("the bakery's been open a month — citizens love it").
- *Beat history* — a beat can require another beat to have already fired, letting narrative threads chain without forcing the chain into the building DAG.
- *Brick-progress spacing* — beats are paced by progress (🧱 bricks earned since the last beat) so they don't fire all at once.

**Other mechanics:**

- **Land:** Players start with a small fixed beginner map. They can spend 🧱 bricks to expand the land symmetrically outward, and to unlock additional themed maps later (e.g. countryside, big city, futuristic). Each map has its own independent placement state.
- **Roads:** Auto-generated to connect placed buildings — the player never manually draws roads. Avoids fiddly precision placement on a phone.
- **Moving buildings:** Free. Players can rearrange their city without spending more 🧱.
- **Selling buildings:** Not supported in v1. Simplifies the economy and avoids "I bought the wrong thing, refund me" friction.
- **Upgrade tiers:** Some buildings have visual upgrade tiers (e.g. wooden → brick → ornate). Tiers change the *style*, not the footprint, to keep cities visually balanced as they grow.
- **Population:** A visible counter shows the current population. Growth follows from a *mix* of buildings: monotone cities (all cinemas, or all apartments and nothing else) stall or even shrink, with citizens complaining that the city is unbalanced.
- **Growth model:** A combination of aggregate service ratios (1 clinic per N residents, 1 power plant per N, etc.) and category-balance multipliers (variety of commercial + entertainment + services boosts growth; lopsided mixes stall it). Concrete formulas are tuned across Phase 7–9 by play-testing.
- **Events:** Players can spend 🧱 bricks on temporary events (festivals, parades) that attract additional residents.

**Out of v1, nice to have later:**
- Animated city: cars driving on roads, building lights turning on at night, pedestrians on sidewalks, day/night cycle.
- Sharing screenshots of cities with friends.
- A player-facing "city journal" archiving past citizen requests and the player's response.

(Detailed 🧱 / 🔬 prices, DAG unlock conditions, beat scripts, and growth formulas are tuned across Phases 7–9 — see [plan.md](plan.md). Phase 7 ships a small proof of the system with ~10 buildings and ~5 beats; Phase 8 designs the full DAG + hundreds of beats in a future `city_builder.md`; Phase 9 implements the full content and generates the building art.)

---

## Sound & Visual Design

- Bright, playful color palette appropriate for kids
- Animated character that reacts to correct/wrong answers (jumps, cheers, looks sad)
- Sound effects for: wheel spin, correct answer, wrong answer, 🧱 collection, 🔬 award, building placed
- Background music (loopable, upbeat, with a mute toggle)
- All UI copy uses simple language appropriate for the youngest end of the target age range

---

## Engagement Mechanics

- **Daily streak:** Playing at least one round per day maintains a streak. Streak milestones award bonus 🧱.
- **Daily challenge:** One special concept challenge per day with a bonus 🧱 reward.
- Push notifications for streak reminders (v2, requires parental consent flow on iOS/Android).

---

## Player Progress Screen

Each player can view their own progress from their profile — the goal is to **empower the player** to understand where they shine and what they can improve, not to report to an adult.

The screen shows:
- **Concept proficiency chart** — visual breakdown of current level per concept category (e.g. a radar/spider chart or color-coded grid)
- **Strengths** — concepts currently in the "comfortable" band, highlighted positively
- **Growing edges** — concepts in the "challenging" band, framed as exciting opportunities ("You're leveling up in fractions!")
- **Stars earned** — total and recent history (current balance + lifetime earned)
- **Sessions and questions answered** — simple stats the player can feel proud of

No PIN, no adult-only section. The data is the player's own, presented in a way that's motivating rather than evaluative.

---

## Onboarding

First-time experience:
1. "Create your player" screen (name, grade, basic avatar)
2. Brief animated tutorial showing the spin wheel and how to answer (1–2 screens, skippable)
3. First question is intentionally easy to create an early win

---

## Saving User Data

All player data (profiles, avatar config, proficiency levels, 🧱 / 🔬 balances, city state) is:

- **Stored locally** on the device with no account required for basic use.
- **Optionally backed up and restored** via the platform's own game services — Game Center (iOS, tied to the user's iCloud) and Google Play Games (Android). The user signs in with their existing Apple or Google account; the app does not run a backend or store any data on our infrastructure.

If the user is not signed in to their platform's game service, local-only storage is the fallback — the app remains fully playable, just without cross-device backup.

---

## Content & Licensing

All third-party content, assets, and libraries must be compatible with free non-commercial educational distribution:

- **Math questions:** Permissively licensed only — MIT / Apache 2.0 / CC-BY / CC0. **CC-BY-NC and CC-BY-NC-SA content is excluded** because app-store distribution of free apps is generally treated as commercial channel use, and the legal-risk floor is non-zero for NC licensors. This excludes EngageNY/Eureka, OpenStax K–12, Khan Academy, CK-12, and Illustrative Mathematics v.360 — all of which are NC-family. Approved sources are inventoried in [curriculum.md §7](curriculum.md). v1 does not use offline LLM batch generation.
- **Art assets:** CC0 or CC-BY licensed sprite sheets and icons, or custom-created.
- **Music & sound effects:** CC0 or royalty-free with no attribution required (e.g. OpenGameArt.org, Freesound.org with appropriate licenses).
- **Fonts:** OFL (SIL Open Font License) or equivalent.
- **Libraries/frameworks:** MIT, Apache 2.0, BSD, or similar permissive licenses.

---

## Edge Cases

- **Player masters all v1 content.** If every available concept drops into the "mastered" band, the wheel falls back to a celebration message ("You've mastered everything! New concepts coming soon.") and offers a free-play mode that randomly samples from mastered concepts (no 🧱 / 🔬 awarded — keeps it from being a grind for trivial points).
- **Mid-question abandonment.** If the player closes the app or switches profiles before answering, the question is discarded with no proficiency change and no 🧱 / 🔬 award. It does not count as wrong.
- **Profile deletion.** Players can delete their own profile from the profile picker (with a confirmation prompt). All local data for that profile is removed; cloud-save data for that profile is also removed on next sync if signed in.
- **Two players want to play simultaneously.** Not supported — gameplay is turn-based on a single device. The "alternate rounds" structure is the v1 multiplayer model.
- **Grade-level advancement.** A player's stored grade level is the *starting point* for the adaptive system, not a moving target. The system adapts based on actual proficiency, so a player who advances grades in real life will naturally see harder concepts enter their wheel without any manual update. A "change grade" option is available in settings if a parent wants to recalibrate.

---

## Out of Scope (v1)

- Real-time multiplayer over the internet
- Teacher/classroom mode
- Timed quiz mode
- Leaderboards beyond the per-session summary
- Push notifications (v2)
- In-app analytics or crash reporting (revisit if needed; would require privacy disclosure)
