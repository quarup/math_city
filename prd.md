# Math Dash — Product Requirements Document

**Math Dash** is a mobile game for Android and iOS that makes math practice fun for kids. Multiple players can share a single device, each with their own profile and progress.

**Target audience:** Kids ages 6–14, with math content spanning grades K–8.

**Platform:** Cross-platform mobile (iOS + Android), built with Flutter and the Flame game engine.

**Business model:** Completely free — no ads, no in-app purchases, no subscriptions. All content, assets, and libraries used must be compatible with free, non-commercial educational use (open licenses preferred).

**Compliance:** Designed for ages 6–14, the app must satisfy children's-app requirements on both stores: no third-party tracking, no data collection beyond local profiles, no behavioral advertising. Privacy policy required. Apple "Made for Kids" and Google "Designed for Families" guidelines apply.

**Accessibility:** Baseline a11y is in scope from the start — color-blind-safe palette (the wheel relies heavily on color, so segments must also be distinguishable by shape/icon), readable type at small sizes, audio cues for key feedback (so a 6-year-old who isn't yet reading fluently can play), respect for OS-level text-size settings. Optional dyslexia-friendly font (e.g. OpenDyslexic) toggle is a stretch goal for Phase 6.

**Localization:** v1 ships English-only. All user-facing strings must be externalized (no hardcoded text in widgets) so future translation is mechanical, not a rewrite.

---

## Success Metrics

These focus on learning outcomes, not time-on-app:

- **Skill progression:** % of players who advance at least one skill from "challenging" to "comfortable" within their first 5 sessions
- **Accuracy improvement:** wrong-answer rate per skill decreases over successive attempts (player is actually learning, not just guessing)
- **Breadth of practice:** average number of distinct skill categories practiced per week (kids are exploring, not grinding one skill)
- **Challenge engagement:** % of correct answers that are 5-star (challenging-band) questions — higher = player is being appropriately stretched
- **Retention through learning:** D14 retention among players who advanced at least one skill level (learning = reason to return)

---

## Player Creation & Profile

When the app opens, the player selects their profile or creates a new one.

**Creating a new player:**
- Enter a name
- Select starting school grade (K–8)
- Customize basic appearance: skin tone, hair style/color, eye color, basic clothing. [Simple 2D avatar — no 3D required initially]

**Advanced customization** (hats, accessories, special clothing, gadgets, pets, vehicles) must be **earned** via points ("stars") — see *Redeeming Stars* section.

Multiple player profiles can exist on one device with no login required. [Assumption: no account/auth on first version; cloud save is opt-in — see *Saving User Data*]

---

## Gameplay Loop

Each **round** follows this sequence:

1. **Player select** — The current player can hand the device to another player at the start of any round.
2. **Spin the wheel** — A colorful wheel displays 4–8 math skills (selected from a larger pool, weighted toward skills the player needs to practice). Player taps to spin.
3. **Answer a question** — A question in the landed skill category appears at the player's current level for that skill.
4. **Result:**
   - **Correct answer at regular difficulty:** +3 stars, celebratory animation/sound.
   - **Correct answer at challenge difficulty** (near the edge of their ability): +5 stars, bigger celebration.
   - **Wrong answer:** 0 stars. A friendly step-by-step explanation guides the player to the correct answer. No penalty — the game stays encouraging.
5. Return to step 1.

### Answer Input

Input method is tied to the player's proficiency band for that skill:

- **Challenging band** → **Multiple choice** (4 options). Distractors are plausible (e.g. off-by-one, common conceptual mistakes). Reduces friction when the concept is unfamiliar.
- **Comfortable band** → **Typed numeric answer**. No hints from distractors; tests genuine recall and reinforces fluency.

This means the same player might type answers for skills they've mastered and pick from options for skills they're still developing.

### Timer

No hard timer in v1. After ~20 seconds of inactivity, the character plays a gentle "thinking" animation as a nudge — but the player can take as long as they need. A timed-mode toggle is out of scope for v1 (see *Out of Scope*).

### Multiplayer Turn Structure
When multiple players share a device, they **alternate rounds** in a single session (Player A spins → Player B spins → ...). Each player's stars and skill data update independently. A per-session leaderboard shows how many stars each player earned this session.

---

## Skill System & Adaptive Difficulty

The game tracks proficiency at the **sub-skill** level — not at broad category level — because a kid who's mastered single-digit addition has not necessarily mastered multi-digit addition, and the wheel needs to surface the right granularity.

### Two-level taxonomy: Categories → Skills

**Categories** are how proficiency is *displayed* to the player (and how the wheel groups options visually). **Skills** are what proficiency is *tracked* against and what the wheel selects. One category contains many skills.

Example category → skills decomposition (full catalog defined in Phase 2):

| Category | Example skills (each tracked independently) |
|---|---|
| **Number sense** | counting to 20, counting to 100, place value (tens), place value (hundreds), comparing 2-digit numbers, comparing 3-digit numbers |
| **Addition & subtraction** | single-digit addition, single-digit subtraction, 2-digit addition (no carry), 2-digit addition (with carry), 2-digit subtraction (no borrow), 2-digit subtraction (with borrow), 3-digit addition, 3-digit subtraction, mental addition |
| **Multiplication & division** | times tables 2–5, times tables 6–9, times tables 10–12, 2-digit × 1-digit, long multiplication, simple division, long division |
| **Fractions** | identifying fractions, comparing fractions (same denominator), comparing fractions (different denominators), adding fractions, multiplying fractions |
| **Decimals & percentages** | reading decimals, adding/subtracting decimals, converting fractions to decimals, finding percentages of numbers |
| **Geometry** | naming 2D shapes, naming 3D shapes, perimeter of rectangles, area of rectangles, area of triangles, angles |
| **Measurement** | reading clocks (hour), reading clocks (minute), length conversions, weight conversions, volume conversions |
| **Word problems** | single-step (addition/subtraction), single-step (multiplication/division), multi-step |
| **Algebra basics** (grades 6–8) | patterns, simple equations (one variable), evaluating expressions |

The wheel surfaces individual **skills** (e.g. "2-digit addition with carry"), not categories. The Player Progress screen rolls skill data up to **categories** for a digestible at-a-glance view, with drill-down to see the per-skill detail.

### Adaptive Logic

Each skill has a **proficiency level** (e.g. 0.0–1.0) per player, updated after every answer:
- Correct answer → proficiency increases
- Wrong answer → proficiency decreases slightly (floor at 0)

The exact update formula is an implementation detail (TBD in Phase 2). It should produce stable behavior with small N (e.g. doesn't swing wildly after one wrong answer).

Based on proficiency, each skill is classified into one of four bands:

| Band | Condition | Action |
|---|---|---|
| **Mastered** | Way above current level | Excluded from wheel (e.g. counting for a grade 5 player) |
| **Comfortable** | At or slightly above level | Included; correct = 3 stars |
| **Challenging** | Noticeably above current level | Included with lower probability; correct = 5 stars |
| **Not yet** | Far above current level | Excluded from wheel (e.g. calculus for grade 4) |

The wheel at any given round contains a **mix of comfortable + challenging** skills so the player always has a chance to earn 5-star questions but isn't overwhelmed.

### Question Generation

Questions must feel **infinite and varied**. The strategy is hybrid, chosen per skill:

- **Pure-arithmetic skills** (e.g. single-digit addition, times tables) → **algorithmic generation** at runtime. Random operands within the skill's defined range, with templated wording variation. Effectively infinite, no storage cost. Wrong-answer explanations are likewise templated.
- **Word problems and concept-rich skills** (e.g. multi-step word problems, geometry, fractions) → **curated + batch AI-generated**, shipped as static data. We seed from open-licensed datasets (GSM8K, MathDataset-ElementarySchool, Illustrative Mathematics) and supplement with offline batch LLM generation. Each question carries a hand-authored or AI-authored step-by-step explanation.

**Critical constraint:** No cloud LLM calls at runtime. All AI-generated content is produced offline, reviewed for quality, and shipped bundled with the app or as a periodically-updated content pack. This keeps the app free, offline-capable, and avoids per-user API costs.

---

## Redeeming Stars

Stars are the in-game currency earned by answering correctly. Stars are spent on cosmetic upgrades only — no gameplay advantage is purchasable. The app is entirely free; stars cannot be purchased with real money.

### Milestone Unlocks

At certain cumulative star totals, the player **unlocks a new reward category** they can shop from. Milestone thresholds follow a roughly exponential curve:

| Milestone | Stars needed (cumulative) |
|---|---|
| 1 | 10 |
| 2 | 30 |
| 3 | 75 |
| 4 | 150 |
| 5 | 300 |
| 6 | 600 |
| … | … |

When a player hits a milestone, a celebration screen appears and they choose which **reward category** to unlock (they do NOT unlock all categories at once — choosing one makes it feel more personalized). Example categories: Pets, Hats & Accessories, Vehicles (cars, planes, rockets), Houses, Toys, Sports gear.

Items within each category have varying star costs. Cheaper items are available early; rarer/cooler items cost more.

### Shop
A persistent "Shop" or "Wardrobe" screen where players can:
- Browse owned and purchasable items
- Equip items to their character
- See how many stars they need to afford the next item

---

## Sound & Visual Design

- Bright, playful color palette appropriate for kids
- Animated character that reacts to correct/wrong answers (jumps, cheers, looks sad)
- Sound effects for: wheel spin, correct answer, wrong answer, milestone unlock, star collection
- Background music (loopable, upbeat, with a mute toggle)
- All UI copy uses simple language appropriate for the youngest end of the target age range

---

## Engagement Mechanics

- **Daily streak:** Playing at least one round per day maintains a streak. Streak milestones award bonus stars.
- **Daily challenge:** One special skill challenge per day with a bonus star reward.
- Push notifications for streak reminders (v2, requires parental consent flow on iOS/Android).

---

## Player Progress Screen

Each player can view their own progress from their profile — the goal is to **empower the player** to understand where they shine and what they can improve, not to report to an adult.

The screen shows:
- **Skill proficiency chart** — visual breakdown of current level per skill category (e.g. a radar/spider chart or color-coded grid)
- **Strengths** — skills currently in the "comfortable" band, highlighted positively
- **Growing edges** — skills in the "challenging" band, framed as exciting opportunities ("You're leveling up in fractions!")
- **Stars earned** — total and recent history
- **Sessions and questions answered** — simple stats the player can feel proud of
- **Milestones reached** — visual timeline of milestone badges unlocked

No PIN, no adult-only section. The data is the player's own, presented in a way that's motivating rather than evaluative.

---

## Onboarding

First-time experience:
1. "Create your player" screen (name, grade, basic avatar)
2. Brief animated tutorial showing the spin wheel and how to answer (1–2 screens, skippable)
3. First question is intentionally easy to create an early win

---

## Saving User Data

All player data (profiles, proficiency levels, star counts, milestones, equipped items) is:

- **Stored locally** on the device with no account required for basic use.
- **Optionally backed up and restored** via the platform's own game services — Game Center (iOS, tied to the user's iCloud) and Google Play Games (Android). The user signs in with their existing Apple or Google account; the app does not run a backend or store any data on our infrastructure.

If the user is not signed in to their platform's game service, local-only storage is the fallback — the app remains fully playable, just without cross-device backup.

---

## Content & Licensing

All third-party content, assets, and libraries must be compatible with free non-commercial educational distribution:

- **Math questions:** Open educational resources (OER) preferred — Creative Commons licensed datasets, Khan Academy open content, OpenStax, or similar. AI-batch-generated content is acceptable if generated offline and does not require an ongoing paid API subscription for players.
- **Art assets:** CC0 or CC-BY licensed sprite sheets and icons, or custom-created.
- **Music & sound effects:** CC0 or royalty-free with no attribution required (e.g. OpenGameArt.org, Freesound.org with appropriate licenses).
- **Fonts:** OFL (SIL Open Font License) or equivalent.
- **Libraries/frameworks:** MIT, Apache 2.0, BSD, or similar permissive licenses.

---

## Edge Cases

- **Player masters all v1 content.** If every available skill drops into the "mastered" band, the wheel falls back to a celebration message ("You've mastered everything! New skills coming soon.") and offers a free-play mode that randomly samples from mastered skills (no stars awarded — keeps it from being a grind for trivial points).
- **Mid-question abandonment.** If the player closes the app or switches profiles before answering, the question is discarded with no proficiency change and no stars. It does not count as wrong.
- **Profile deletion.** Players can delete their own profile from the profile picker (with a confirmation prompt). All local data for that profile is removed; cloud-save data for that profile is also removed on next sync if signed in.
- **Two players want to play simultaneously.** Not supported — gameplay is turn-based on a single device. The "alternate rounds" structure is the v1 multiplayer model.
- **Grade-level advancement.** A player's stored grade level is the *starting point* for the adaptive system, not a moving target. The system adapts based on actual proficiency, so a player who advances grades in real life will naturally see harder skills enter their wheel without any manual update. A "change grade" option is available in settings if a parent wants to recalibrate.

---

## Out of Scope (v1)

- Real-time multiplayer over the internet
- Teacher/classroom mode
- Timed quiz mode
- Leaderboards beyond the per-session summary
- Push notifications (v2)
- In-app analytics or crash reporting (revisit if needed; would require privacy disclosure)
