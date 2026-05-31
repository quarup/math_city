# Math City — City Builder Reference

> Canonical reference for the Math City city-builder content: the building DAG,
> the citizen story-beat catalog, and the asset checklist.
> Companion to: [prd.md](prd.md) (product scope), [plan.md](plan.md) (execution),
> and [curriculum.md](curriculum.md) (the math content — this doc is its city-side analogue).

---

## Status

- **Last updated:** 2026-05-31
- **Phase:** Phase 8 — City Builder: Research & Rich Design. Content-authoring only, **no code changes**. Deliverable is this document; Phase 9 implements it.
- **Drafting mode:** *fill pass complete (first draft)*. §1 (references), §2 (categories), §3 (full building specs — 55 anchors), §4 (beat catalog), §5 (asset checklist), and §7 (open questions) are drafted. §6 (implementation status) carries only the Phase-7 ✅ rows; Phase 9 ticks the rest. Three structure decisions are locked (2026-05-31): education (`school`/`high_school`) lives under `services`; `water` is a hard-gating service; the housing spine keeps all 7 rungs. **Still expects Phase-9 iteration** — costs and service ratios are designed-coherent placeholders, finalized by playtest.
- **Framework:** extends the Phase-7 model unchanged — two currencies (🧱 bricks + 🔬 research), four categories, the service-ratio + variety-multiplier growth model, and the typed `UnlockRule` / `TriggerRule` gates. No schema or domain-shape changes proposed. (Per the Phase-8 planning decision: *extend, don't redesign*.)
- **Scope of this pass:** *representative breadth* — full coherent arcs across all four categories with ~55 anchor buildings individually specced; the long-tail variants (cosmetic re-skins, minor tier infills) are described as patterned templates rather than itemized. This keeps the design coherent and reviewable and gives Phase 9 a clear queue without committing to hundreds of hand-authored rows up front.
- **Source of truth note:** once Phase 9 starts wiring content, the building/beat **IDs here become the source of truth**, mirrored by [building_registry.dart](lib/domain/city/building_registry.dart) and [beat_registry.dart](lib/domain/city/beat_registry.dart) — exactly as `curriculum.md` is mirrored by `generator_registry.dart`.

---

## 1. References & Lessons Learned

Phase 8 exists so the building DAG *feels infinite without becoming a junk drawer*
(see [plan.md](plan.md) Risks). Before designing, we studied how established
city-builders pace their progression — what makes unlocks feel rewarding, and
what makes them feel like a grind. Findings below, then what Math City borrows
and what it deliberately rejects.

### 1.1 What the reference games do

**SimCity 4 — reward buildings & the RCI feedback loop.**
SC4's headline progression is *unlock-by-need* and *unlock-by-population*: reward
buildings (and whole zone tiers) appear as the city crosses population thresholds
and as mayor rating / demand rises. Underneath sits the **RCI loop** (Residential
/ Commercial / Industrial): residents create demand for jobs, jobs create demand
for residents, and the three must stay *balanced* — a lopsided city stalls or
abandons. Desirability is local (the mayor's house and parks raise the
desirability of nearby tiles). The lesson: a small set of **interdependent
categories whose imbalance the player can feel** produces emergent, legible
progression without a scripted tech tree.

**Cities: Skylines (I & II) — milestone XP pacing.**
Progress is gated by *milestones*; almost every building has upgraded versions
that unlock as the city grows, so the player is "constantly looking forward to
the next milestone." Cities: Skylines II refined this into **Expansion Points**
that accrue two ways: **passively** (steady drip from population + happiness) and
**actively** (bursts from placing/upgrading service buildings, signature
buildings, expanding roads). The stated design goal: let players build the city
they want — *a small, well-run town should still progress* — rather than forcing
everyone toward a high-population end-game. The lesson: **steady passive drip +
active bursts**, and **don't make scale mandatory** to feel progression.

**Anno series — need-driven tier-ups.**
Residents sit in tiers (e.g. Anno 117's Liberti → Plebians → …). Each tier has a
set of **needs** (food, public services, fashion); satisfy them and residents
*upgrade to the next tier*, which unlocks more advanced buildings — which in turn
have their own, higher needs. The main loop *is* need-satisfaction → tier-up →
new needs. Production-chain ratios reward keeping supply matched to demand. The
lesson: **needs surface the next unlock**; progression reads as "the town asked
for X, I provided it, now the town wants Y."

**SimCity BuildIt — the cautionary case.**
Its progression is widely critiqued: the soft-currency economy is so tight that
*leveling up doesn't feel good* — players sometimes deliberately avoid it because
each new tier raises costs faster than rewards. The lesson (a **reject**):
unlocks must feel like a *reward for play*, never a tax that makes the next thing
harder to afford. Artificial scarcity + pay-to-skip timers are exactly the
free-to-play patterns Math City's PRD forbids.

**Township / Stardew Valley — the cozy loop.**
Even "relaxing" games run on a tight, satisfying core loop: venture → gather →
return → **reinvest in a visible upgrade** → repeat. The reward is that the loop
is *short* and the reinvestment is *immediately visible*. The tension worth
naming: cozy aesthetics can still hide a grind. The lesson: keep the
answer→earn→place→see-it-grow loop short and always-positive; no fail states.

### 1.2 What Math City borrows

1. **Need-driven discovery (Anno + SC4 "unlock by need").** The citizen demand
   bubble *is* the need signal. A building's research card only appears after the
   player reads the demand beat that asks for it (already true in Phase 7 via
   `requiredBeatsRead`). Phase 8 scales this into **arcs**: satisfying one tier's
   need surfaces the next tier's demand ("the apartments are full — what about a
   high-rise?").
2. **Within-category upgrade arcs (Cities: Skylines).** Every category is a
   legible ladder (housing: single home → duplex → apartment → high-rise → …),
   each rung gated on the previous rung + a population / lifetime-brick threshold.
   The player always has a visible "next rung."
3. **Steady drip + active bursts (CS2 Expansion Points).** Maps onto our two
   currencies for free: 🧱 **bricks** drip from *every* correct answer (steady);
   🔬 **research** arrives in bursts on per-concept mastery band-crossings
   (active). Math practice is the XP source — the kid earns progression by
   *learning*, which is the whole point of the app.
4. **Category-balance feedback (SC4 RCI / Anno ratios).** Already modeled in
   [population_model.dart](lib/domain/city/population_model.dart): service-ratio
   ceilings + a variety multiplier + a lopsidedness penalty. Beats *narrate* the
   imbalance ("trash everywhere!", "all shops and nowhere to live") so the kid
   understands *why* growth stalled and what to build next.
5. **Short, visible, always-positive reinvestment loop (cozy games).** Answer
   math → earn bricks → place a building → watch population tick up and a praise
   bubble pop. Keep it short; keep it kind.

### 1.3 What Math City rejects

1. **Tight soft-currency walls / pay-to-skip (SimCity BuildIt).** No
   monetization, no timers, no artificial scarcity. The *only* "cost" of progress
   is math practice. Unlocking must always feel like a reward.
2. **Fail states — bankruptcy, abandonment, RCI collapse (SC4).** Too punishing
   for ages 6–14. Imbalance only ever **slows growth** (a soft population cap) and
   raises a gentle demand bubble; it never destroys what the kid built.
3. **Real-time/energy gating (mobile city-builders).** No "come back in 4 hours."
4. **Deep production chains (Anno).** Too complex for the target age. We abstract
   supply/demand to **service ratios + variety**, not multi-good logistics.
5. **Mandatory high-population end-game (SC4).** Like CS2's stated goal, a kid who
   builds a small cozy town should still feel a full progression arc. Scale is an
   option, not a requirement.

### 1.4 Sources

- [Progression Control in Sim City BuildIt — Game Developer](https://www.gamedeveloper.com/design/progression-control-in-sim-city-buildit) (cautionary tight-economy analysis)
- [SimCity 4 Reward Buildings — StrategyWiki](https://strategywiki.org/wiki/SimCity_4/Reward_Buildings) (unlock-by-population / unlock-by-need)
- [RCI / Zoning & Demand — StrategyWiki](https://strategywiki.org/wiki/SimCity_4/Zoning_and_Demand) and [SC4D Encyclopaedia: RCI](https://wiki.sc4devotion.com/index.php?title=RCI) (category-balance feedback loop)
- [Cities: Skylines Milestones — Paradox Wiki](https://skylines.paradoxwikis.com/Milestones) and [Cities: Skylines II Game Progression feature](https://www.paradoxinteractive.com/games/cities-skylines-ii/features/game-progression) (milestone / Expansion Point pacing)
- [Anno 117 Beginner's Guide — Into Indie Games](https://intoindiegames.com/walkthroughs/anno-117-pax-romana-beginners-guide/) and [Anno 1800 Production Chains — Fandom](https://anno1800.fandom.com/wiki/Production_chains) (need-driven tier-ups, balance ratios)
- [Cosy games still maintain "the grind" — GamingBible](https://www.gamingbible.com/features/stardew-valley-like-games-maintain-grind-mentality-044899-20240118) (cozy-loop tension)

---

## 2. Categories

Math City keeps the **four** Phase-7 categories (the `BuildingCategory` enum in
[category.dart](lib/domain/city/category.dart)). Each plays a distinct role in
the growth model so that a balanced city outgrows a lopsided one — the RCI lesson,
softened for kids into "slows growth" rather than "collapses."

| Category (`enum`) | Display | Growth role | Variety-counts? |
|---|---|---|---|
| `civicHousing` | Civic & Housing | **The spine.** Housing sets the raw population *ceiling* (`populationContribution`); civic anchors (mayor's office, town hall) are the narrative core and unlock gates. | Mostly no (housing tiers aren't "celebrated for variety") |
| `services` | Services | **The enabler.** Gating infrastructure (power, water, waste, health) lifts the service ceilings so housing can actually fill; soft services (education, safety, transit) add desirability. | Yes |
| `commercial` | Commercial | **The multiplier.** Shops/food/offices raise desirability via the variety bonus and give the town life; over-building them without housing triggers the lopsidedness penalty. | Yes |
| `entertainment` | Entertainment | **The delight.** Parks/culture/recreation are the cozy, praise-heavy channel; they feed the variety multiplier and anchor the happiest beats. | Yes |

**How the categories interact (the growth model, already implemented):**
- **Housing** contributes `populationContribution`; the sum is the raw ceiling.
- **Gating services** (`power`, `clinic`, `waste`, and Phase-8's new `water`) cap
  the population the city can actually support — the thinnest gating service wins,
  each with a small free allowance so a brand-new hamlet isn't pinned at zero.
- **Soft services** (`school`, plus Phase-8 `police`/`fire`/`transit`) are
  *non-gating* amenities — they don't hard-cap growth but feed desirability.
- **Variety** across `services` / `commercial` / `entertainment` adds a capped
  desirability multiplier (livelier mix → denser city).
- **Lopsidedness** (amenities dwarfing housing) applies a desirability penalty.

Phase 8 does **not** change these mechanics — it populates the catalog that feeds
them. New service IDs (`water`, `police`, `fire`, `transit`) are content additions
to the existing `serviceProvision` map and `gatingServiceIds` set, not new
machinery. *(`water` joins the gating set; `police`/`fire`/`transit` are soft.)*

---

## 3. Building catalog

The full DAG. Each category below is a within-category arc rooted (directly or
indirectly) at `mayors_office`. Tier (Early / Mid / Late / Capstone) is a
narrative pacing label, not a schema field — it maps loosely to the rising
population / lifetime-brick gates in the unlock rule.

**Reading the spec tables.** Columns: 🧱 = `brickCost` (per placement), 🔬 =
`researchCost` (one-shot, to add the type to the build menu), **Pop** =
`populationContribution`, **Service** = `serviceProvision` (`id:capacity`), **V** =
`varietyContribution`, **Foot** = `footprint` (`w×h` tiles). The **Unlock rule**
column is the typed `UnlockRule`, written in shorthand:

- `B` (bare building id) → `requiredBuildingsPlaced` includes B
- `pop≥N` → `minPopulation: N`
- `life🧱≥N` → `minLifetimeBricks: N`
- `reads:beat_id` → `requiredBeatsRead` includes that demand beat (the discovery
  gate — the card stays hidden until the player opens that bubble; see §4)

Every non-starter building names exactly one demand beat in `reads:` — that beat
is what reveals its research card. `✓P7` marks the ten buildings already shipped
in the Phase-7 registry (IDs and Phase-7 numbers preserved).

### 3.1 Civic & Housing (`civicHousing`)

**Civic-core line** (unique narrative anchors; gate later arcs):

| Building | 🧱 | 🔬 | Pop | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|---|
| `mayors_office` 🏛️ ✓P7 | 0 | 0 | 0 | — | – | 1×1 | *open* (starter, **unique**) |
| `town_hall` 🏤 | 30 | 2 | 0 | — | – | 1×1 | `mayors_office` + pop≥20 · reads:`demand_town_hall` (**unique**) |
| `city_hall` 🏙️ | 80 | 3 | 0 | — | – | 2×2 | `town_hall` + pop≥80 · reads:`demand_city_hall` (**unique**) |
| `library` 📚 | 20 | 2 | 0 | — | – | 1×1 | `school` · reads:`demand_library` |
| `post_office` 📮 | 20 | 2 | 0 | — | – | 1×1 | `town_hall` · reads:`demand_post_office` |

**Housing line** (the population spine — 7-rung ladder, rising `Pop`):

| Building | 🧱 | 🔬 | Pop | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|---|
| `single_home` 🏠 ✓P7 | 5 | 1 | 4 | — | – | 1×1 | `mayors_office` · reads:`demand_first_home` |
| `duplex` 🏘️ | 10 | 1 | 8 | — | – | 1×1 | `single_home` · reads:`demand_duplex` |
| `townhouse_row` 🏘️ | 20 | 2 | 12 | — | – | 2×1 | `duplex` + pop≥12 · reads:`demand_townhouse_row` |
| `apartment` 🏢 ✓P7 | 10 | 1 | 16 | — | – | 1×1 | `single_home` + pop≥8 · reads:`demand_apartment` |
| `mid_rise_apartment` 🏢 | 30 | 2 | 30 | — | – | 1×1 | `apartment` + pop≥30 · reads:`demand_mid_rise` |
| `high_rise` 🌆 | 60 | 3 | 60 | — | – | 2×2 | `mid_rise_apartment` + pop≥60 + life🧱≥300 · reads:`demand_high_rise` |
| `luxury_condo` 🏨 | 100 | 3 | 50 | — | ✅ | 2×2 | `high_rise` + life🧱≥500 · reads:`demand_luxury_condo` |
| `farmhouse` 🏡 | 8 | 1 | 3 | — | – | 1×1 | `single_home` · reads:`demand_farmhouse` (countryside flavor) |

### 3.2 Services (`services`)

Gating infrastructure (hard population caps) + soft amenities (desirability only).
Gating-service rows are `varietyContribution: true` (matching Phase 7); soft
services are `false`. **Education moved here from `civicHousing`** per the
2026-05-31 decision.

**Power** (`power`, gating):

| Building | 🧱 | 🔬 | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|
| `power_plant` ⚡ ✓P7 | 10 | 1 | `power:200` | ✅ | 1×1 | `single_home` · reads:`demand_power` |
| `power_station` 🏭 | 40 | 3 | `power:500` | ✅ | 2×2 | `power_plant` + pop≥40 · reads:`demand_power_station` |
| `solar_farm` ☀️ | 70 | 3 | `power:800` | ✅ | 2×2 | `power_station` + life🧱≥400 · reads:`demand_solar_farm` |

**Water** (`water`, gating — **new service ID**):

| Building | 🧱 | 🔬 | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|
| `water_tower` 🚰 | 10 | 1 | `water:150` | ✅ | 1×1 | `single_home` · reads:`demand_water` |
| `water_treatment` 💧 | 40 | 3 | `water:500` | ✅ | 2×2 | `water_tower` + pop≥40 · reads:`demand_water_treatment` |

**Waste** (`waste`, gating):

| Building | 🧱 | 🔬 | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|
| `waste_management` 🚮 ✓P7 | 10 | 1 | `waste:150` | ✅ | 1×1 | `single_home` + pop≥12 · reads:`demand_waste` |
| `recycling_center` ♻️ | 40 | 3 | `waste:400` | ✅ | 1×1 | `waste_management` + pop≥40 · reads:`demand_recycling` |

**Health** (`clinic`, gating):

| Building | 🧱 | 🔬 | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|
| `clinic` 🏥 ✓P7 | 10 | 1 | `clinic:50` | ✅ | 1×1 | `single_home` · reads:`demand_clinic` |
| `hospital` 🚑 | 60 | 3 | `clinic:200` | ✅ | 2×2 | `clinic` + pop≥60 · reads:`demand_hospital` |

**Education** (`school`, soft):

| Building | 🧱 | 🔬 | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|
| `school` 🏫 ✓P7 | 10 | 1 | `school:60` | – | 1×1 | `single_home` · reads:`demand_school` *(was `civicHousing` in P7)* |
| `high_school` 🎓 | 40 | 2 | `school:150` | – | 1×1 | `school` + pop≥40 · reads:`demand_high_school` |

**Safety** (soft — **new service IDs `police` / `fire`**):

| Building | 🧱 | 🔬 | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|
| `fire_station` 🚒 | 25 | 2 | `fire:100` | – | 1×1 | `town_hall` · reads:`demand_fire` |
| `police_station` 🚓 | 25 | 2 | `police:100` | – | 1×1 | `town_hall` · reads:`demand_police` |

**Transit** (soft — **new service ID `transit`**):

| Building | 🧱 | 🔬 | Service | V | Foot | Unlock rule |
|---|---|---|---|---|---|---|
| `bus_depot` 🚌 | 40 | 3 | `transit:200` | – | 1×1 | `city_hall` · reads:`demand_bus_depot` |
| `train_station` 🚉 | 120 | 5 | `transit:500` | – | 2×2 | `bus_depot` + pop≥100 + life🧱≥600 · reads:`demand_train_station` |

### 3.3 Commercial (`commercial`)

Shops / food / offices — the desirability-multiplier and "town life" channel. All
`varietyContribution: true`, no `populationContribution`.

**Food & daily goods:**

| Building | 🧱 | 🔬 | Foot | Unlock rule |
|---|---|---|---|---|
| `market_stall` 🍎 | 8 | 1 | 1×1 | `single_home` · reads:`demand_market_stall` |
| `grocery` 🛒 ✓P7 | 10 | 1 | 1×1 | `single_home` · reads:`demand_grocery` |
| `supermarket` 🏪 | 30 | 2 | 1×1 | `grocery` + pop≥20 · reads:`demand_supermarket` |
| `bakery` 🥐 | 20 | 2 | 1×1 | `grocery` · reads:`demand_bakery` |
| `coffee_shop` ☕ ✓P7 | 10 | 1 | 1×1 | `single_home` · reads:`demand_coffee_shop` |
| `restaurant` 🍽️ | 25 | 2 | 1×1 | `coffee_shop` · reads:`demand_restaurant` |
| `farmers_market` 🧺 | 20 | 2 | 1×1 | `farmhouse` · reads:`demand_farmers_market` |

**Retail & offices:**

| Building | 🧱 | 🔬 | Foot | Unlock rule |
|---|---|---|---|---|
| `bookshop` 📖 | 20 | 2 | 1×1 | `library` · reads:`demand_bookshop` |
| `toy_store` 🧸 | 20 | 2 | 1×1 | `grocery` · reads:`demand_toy_store` |
| `clothing_store` 👕 | 25 | 2 | 1×1 | `supermarket` · reads:`demand_clothing_store` |
| `office_building` 🏬 | 40 | 3 | 1×1 | `town_hall` · reads:`demand_office` |
| `shopping_mall` 🛍️ | 80 | 3 | 2×2 | `supermarket` + `clothing_store` + pop≥80 · reads:`demand_shopping_mall` *(multi-parent)* |
| `business_tower` 🏢 | 100 | 3 | 2×2 | `office_building` + pop≥80 + life🧱≥400 · reads:`demand_business_tower` |

### 3.4 Entertainment (`entertainment`)

Parks / culture / recreation — the cozy, praise-heavy delight channel. All
`varietyContribution: true`, no `populationContribution`.

**Green & cozy:**

| Building | 🧱 | 🔬 | Foot | Unlock rule |
|---|---|---|---|---|
| `park` 🌳 ✓P7 | 10 | 1 | 1×1 | `single_home` · reads:`demand_more_parks` *(recurring — see §4)* |
| `playground` 🛝 | 10 | 1 | 1×1 | `park` · reads:`demand_playground` |
| `community_garden` 🌻 | 15 | 2 | 1×1 | `park` · reads:`demand_community_garden` |
| `fountain_plaza` ⛲ | 25 | 2 | 1×1 | `town_hall` · reads:`demand_fountain_plaza` |
| `botanical_garden` 🌺 | 50 | 3 | 2×2 | `community_garden` + pop≥50 · reads:`demand_botanical_garden` |

**Recreation & culture:**

| Building | 🧱 | 🔬 | Foot | Unlock rule |
|---|---|---|---|---|
| `sports_field` ⚽ | 25 | 2 | 2×1 | `school` · reads:`demand_sports_field` |
| `swimming_pool` 🏊 | 30 | 2 | 1×1 | `sports_field` · reads:`demand_swimming_pool` |
| `movie_theater` 🎬 | 40 | 3 | 1×1 | `restaurant` · reads:`demand_movie_theater` |
| `museum` 🏛️ | 50 | 3 | 2×2 | `library` · reads:`demand_museum` |
| `stadium` 🏟️ | 90 | 3 | 2×2 | `sports_field` + pop≥80 · reads:`demand_stadium` |

**Capstone attractions** (aspirational, late-game, signature praise beats):

| Building | 🧱 | 🔬 | Foot | Unlock rule |
|---|---|---|---|---|
| `zoo` 🦁 | 120 | 5 | 2×2 | `botanical_garden` + pop≥100 · reads:`demand_zoo` |
| `aquarium` 🐠 | 120 | 5 | 2×2 | `museum` + pop≥100 · reads:`demand_aquarium` |
| `amusement_park` 🎢 | 200 | 5 | 2×2 | `stadium` + pop≥120 + life🧱≥800 · reads:`demand_amusement_park` |
| `observation_tower` 🗼 | 250 | 5 | 1×1 | `city_hall` + life🧱≥1000 · reads:`demand_observation_tower` |

### 3.5 Economy sanity check

- **Total 🔬 to research the whole catalog ≈ 122** (early ≈1, mid ≈2, late ≈3,
  capstone ≈5 each). The lifetime 🔬 ceiling is ~732 (≈366 sub-concepts × 2 award
  bands — see [plan.md](plan.md) *Research-currency earning*), so the full city is
  comfortably affordable through normal play with research to spare. No artificial
  scarcity (the §1.3 reject).
- **🧱 curve** runs 5–30 (early/mid) → 40–120 (late) → 200–250 (capstone). At
  3–5 🧱 per correct answer, a capstone (~200 🧱) is ~40–60 correct answers of
  saving — a satisfying long-arc trophy, not a wall.
- **`life🧱` gates** (300 / 400 / 500 / 600 / 800 / 1000) read as "you've played a
  lot" milestones; 1000 lifetime bricks ≈ 250 correct answers. Capstones gate on
  lifetime bricks so they feel earned by *total practice*, not just city state.

### 3.6 Long-tail variants (patterned, not itemized)

Beyond the 55 anchors, the "feels infinite" long tail is generated by *pattern*,
not hand-authored rows:

1. **Cosmetic re-skins** of an existing rung — same stats, different
   `assetRef`/`emoji`, no new unlock logic (e.g. a blue-roof vs red-roof home).
2. **Tier infills** — a new rung slotted between two anchors when play shows a
   pacing gap; just a new `requiredBuildingsPlaced` link, no new mechanic.
3. **Map-themed variants** (countryside / city / futuristic — Phase 9 maps) — the
   same arc re-skinned per theme. The `farmhouse` / `farmers_market` pair is the
   first countryside seed.

**Anchor totals:** 13 civic & housing · 15 services · 13 commercial · 14 entertainment = **55**.

### 3.7 DAG sanity check

- **No cycles.** Every "chains from" points to an earlier or same-tier rung; the
  graph is a forest rooted at `mayors_office` → `single_home`, off which every
  service / commercial / entertainment arc hangs.
- **Multi-parent nodes** are intentional and narratively sensible:
  `shopping_mall` ← (`supermarket` + `clothing_store`); plus soft cross-links that
  read naturally — `library` ← `school`, `bookshop` ← `library`,
  `museum`/`sports_field` ← education/library, `farmers_market` ← `farmhouse`.
  No building depends on an unrelated cross-category prereq.
- **Every building has ≥1 trigger beat** in §4 (the `reads:` demand beat, at
  minimum).

---

## 4. Story beat catalog

Mirrors §3. Three kinds (Phase-7 `BeatKind`): **demand** (a request — also the
discovery gate via `requiredBeatsRead`), **praise** (placement celebration), and
**warning** (an imbalance the growth model is producing). Tone ∈ silly / civic /
cozy. Each beat below is `id` · tone · emoji `shortLabel` · longText · trigger
summary. Trigger shorthand: `+B` present, `−B` absent, `pop≥N`, `age(B)≥N`
(building age in rounds), `fired:X` (`requiredBeatsFired`), `🧱since≥N`
(`minBricksEarnedSinceLastBeat`). The exact `TriggerRule` encodes in Phase 9.

> **Authoring convention.** A demand beat fires when its prereq is present and its
> target building is still absent (`+prereq −self`, plus any pop gate matching the
> §3 unlock rule). Once the building is placed it flips to `completed` and clears
> (the Phase-7 demand-completion behavior). Praise beats fire on `+self`.

### 4.1 Demand beats (one per non-starter building — the discovery gates)

**Civic & housing:**

| Beat | Tone | Sticker | Text | Trigger |
|---|---|---|---|---|
| `demand_first_home` ✓P7 | cozy | 🏠 a home! | "We've got a mayor's office but nowhere to live yet — could we get a house, please?" | `+mayors_office −single_home −apartment` |
| `demand_duplex` | cozy | 🏘️ share a yard | "Two families want to share a yard — a duplex would fit them both nicely." | `+single_home −duplex` |
| `demand_townhouse_row` | cozy | 🏘️ row houses | "Lots of folks want to live close together — how about a row of townhouses?" | `+duplex pop≥12 −townhouse_row` |
| `demand_apartment` ✓P7 | cozy | 🏢 more homes! | "More families want to move in but every house is full — an apartment block would help." | `+single_home pop≥8 −apartment` |
| `demand_mid_rise` | cozy | 🏢 go taller | "The apartment filled up in a flash — a taller mid-rise would house even more." | `+apartment pop≥30 −mid_rise_apartment` |
| `demand_high_rise` | civic | 🌆 to the sky | "People are lining up to move in — a high-rise tower would reach for the sky!" | `+mid_rise_apartment pop≥60 −high_rise` |
| `demand_luxury_condo` | silly | 🏨 fancy! | "Mr. Alvarez sold his avocados for a fortune and wants a fancy condo." | `+high_rise −luxury_condo` |
| `demand_farmhouse` | cozy | 🏡 chickens? | "Someone wants chickens and a big garden — a farmhouse on the edge of town?" | `+single_home −farmhouse` |
| `demand_town_hall` | civic | 🏤 town hall | "The mayor's office is bursting at the seams — a proper town hall would give the town a real heart." | `+single_home pop≥20 −town_hall` |
| `demand_city_hall` | civic | 🏙️ a city! | "The town's grown into a city — time for a grand city hall to run it all." | `+town_hall pop≥80 −city_hall` |
| `demand_library` | cozy | 📚 books! | "The kids have read every book in the school twice — can we build a library?" | `+school −library` |
| `demand_post_office` | civic | 📮 mail! | "Letters are piling up at the town hall — a post office would sort things out." | `+town_hall −post_office` |

**Services:**

| Beat | Tone | Sticker | Text | Trigger |
|---|---|---|---|---|
| `demand_clinic` ✓P7 | civic | 🏥 a clinic? | "Someone tripped chasing the ice-cream truck and there's nowhere to get a bandage — could we build a clinic?" | `+single_home −clinic` |
| `demand_power` ✓P7 | civic | ⚡ power! | "The lights keep flickering and the fridges are getting warm — the town really needs a power plant." | `+single_home −power_plant` |
| `demand_water` ⚠ | civic | 🚰 water! | "The taps are sputtering and the gardens are going brown — the town needs a water tower." | `+single_home −water_tower` |
| `demand_waste` ✓P7 ⚠ | civic | 🚮 trash! | "The neighborhood is tired of stepping over garbage — we need a Waste Management facility before it gets worse!" | `+single_home pop≥12 −waste_management` |
| `demand_power_station` ⚠ | civic | 🏭 brownouts | "The power plant's maxed out and brownouts are spreading — a bigger power station would keep the lights on." | `+power_plant pop≥40 −power_station` |
| `demand_solar_farm` | cozy | ☀️ go green | "Why not go green? A solar farm would power the whole city from sunshine." | `+power_station −solar_farm` |
| `demand_water_treatment` ⚠ | civic | 💧 clean water | "More homes means more water — a treatment plant would keep it flowing and clean." | `+water_tower pop≥40 −water_treatment` |
| `demand_recycling` | cozy | ♻️ recycle | "We're throwing away things we could reuse — a recycling center would help the town go green." | `+waste_management pop≥40 −recycling_center` |
| `demand_hospital` ⚠ | civic | 🚑 hospital | "The clinic can't keep up with everyone — the city really needs a proper hospital." | `+clinic pop≥60 −hospital` |
| `demand_school` ✓P7 | civic | 🏫 a school? | "The neighborhood kids have nowhere to practice their math — could we build a school?" | `+single_home −school` |
| `demand_high_school` | civic | 🎓 high school | "The kids have outgrown the school — a high school is the natural next step." | `+school pop≥40 −high_school` |
| `demand_fire` | civic | 🚒 fire truck! | "Someone's stove caught fire and there's no truck nearby — a fire station, please!" | `+town_hall −fire_station` |
| `demand_police` | civic | 🚓 police? | "A few too many bikes have gone missing — a police station would help everyone feel safe." | `+town_hall −police_station` |
| `demand_bus_depot` | civic | 🚌 buses! | "Walking everywhere is tiring — a bus depot would get folks around the city." | `+city_hall −bus_depot` |
| `demand_train_station` | civic | 🚉 all aboard | "The city's ready to connect to the world — a train station would do it!" | `+bus_depot pop≥100 −train_station` |

**Commercial:**

| Beat | Tone | Sticker | Text | Trigger |
|---|---|---|---|---|
| `demand_market_stall` | cozy | 🍎 a stall | "A little market stall would be a sweet first shop for the neighborhood." | `+single_home −market_stall` |
| `demand_grocery` ✓P7 | cozy | 🛒 groceries? | "Folks are tired of driving far for milk and bread — a grocery store would be so handy." | `+single_home −grocery` |
| `demand_supermarket` | cozy | 🏪 bigger! | "The grocery's always crowded — a big supermarket would have room for everyone." | `+grocery pop≥20 −supermarket` |
| `demand_bakery` | silly | 🥐 fresh bread | "The whole street woke up dreaming of warm bread — a bakery, please!" | `+grocery −bakery` |
| `demand_coffee_shop` ✓P7 | cozy | ☕ coffee? | "A cozy coffee shop would give everyone a warm place to meet up — what do you think?" | `+single_home −coffee_shop` |
| `demand_restaurant` | cozy | 🍽️ dinner out | "Coffee's lovely, but folks are hungry for dinner out — a restaurant?" | `+coffee_shop −restaurant` |
| `demand_farmers_market` | cozy | 🧺 farm fresh | "The farmhouse has extra veggies to sell — a farmers market would be perfect." | `+farmhouse −farmers_market` |
| `demand_bookshop` | cozy | 📖 a bookshop | "Readers want their own copies to keep — a bookshop next to the library?" | `+library −bookshop` |
| `demand_toy_store` | silly | 🧸 toys! | "Every kid in town has the same birthday wish this year: a toy store!" | `+grocery −toy_store` |
| `demand_clothing_store` | cozy | 👕 new clothes | "Folks want something new to wear — a clothing store would be a hit." | `+supermarket −clothing_store` |
| `demand_office` | civic | 🏬 jobs | "Grown-ups need somewhere in town to work — an office building?" | `+town_hall −office_building` |
| `demand_shopping_mall` | civic | 🛍️ one big roof | "All these shops could share one big roof — a shopping mall!" | `+supermarket +clothing_store pop≥80 −shopping_mall` |
| `demand_business_tower` | civic | 🏢 booming | "Business is booming — a tall business tower would put the city on the map." | `+office_building pop≥80 −business_tower` |

**Entertainment:**

| Beat | Tone | Sticker | Text | Trigger |
|---|---|---|---|---|
| `demand_more_parks` ✓P7 | cozy | 🌳 a park? | "The town's feeling a little grey — a new park would brighten everyone's day." | `+single_home 🧱since≥150` *(recurring)* |
| `demand_playground` | cozy | 🛝 playground | "The little ones need somewhere to climb and slide — a playground!" | `+park −playground` |
| `demand_community_garden` | cozy | 🌻 grow together | "Neighbors want to grow tomatoes together — a community garden?" | `+park −community_garden` |
| `demand_fountain_plaza` | cozy | ⛲ town square | "The town square feels empty — a fountain plaza would make it sparkle." | `+town_hall −fountain_plaza` |
| `demand_botanical_garden` | cozy | 🌺 rare plants | "The garden's a hit — imagine a whole botanical garden of rare plants." | `+community_garden pop≥50 −botanical_garden` |
| `demand_sports_field` | civic | ⚽ let's play | "The school kids need somewhere to run and play — a sports field!" | `+school −sports_field` |
| `demand_swimming_pool` | silly | 🏊 so hot! | "It's sweltering and everyone's fighting over the sprinkler — a swimming pool?" | `+sports_field −swimming_pool` |
| `demand_movie_theater` | cozy | 🎬 movie night | "Friday nights need a movie — can we build a theater?" | `+restaurant −movie_theater` |
| `demand_museum` | civic | 🏛️ our story | "The town's got stories to tell — a museum would show them off." | `+library −museum` |
| `demand_stadium` | civic | 🏟️ go team! | "The team's outgrown the field — a stadium would pack in the crowds!" | `+sports_field pop≥80 −stadium` |
| `demand_zoo` | silly | 🦁 a zoo! | "A lonely penguin needs a home — and so do its friends. A zoo, please!" | `+botanical_garden pop≥100 −zoo` |
| `demand_aquarium` | silly | 🐠 fishy | "The museum's little fish tank started a craze — let's build a whole aquarium." | `+museum pop≥100 −aquarium` |
| `demand_amusement_park` | silly | 🎢 coaster! | "The whole city is chanting for a roller coaster — an amusement park!" | `+stadium pop≥120 −amusement_park` |
| `demand_observation_tower` | civic | 🗼 the view | "The city's so beautiful now — a tower to see it all from the very top." | `+city_hall −observation_tower` |

### 4.2 Praise beats (placement celebrations)

| Beat | Tone | Sticker | Text | Trigger |
|---|---|---|---|---|
| `praise_first_home` ✓P7 | silly | 🎉 home sweet home | "The new home is cozy! Mrs. Pomeroy moved her cat in already — she sends thanks." | `+single_home` |
| `praise_school` | civic | 🔔 first bell | "The school bell rang for the first time — the kids can't wait for math class!" | `+school` |
| `praise_town_hall` | civic | 🎀 ribbon cut | "Ribbon cut! The new town hall already feels like the heart of the town." | `+town_hall` |
| `praise_library` | cozy | 📚 storytime | "Storytime at the library is packed — kids are reading more than ever." | `+library` |
| `praise_grocery` ✓P7 | silly | 🛒 yum! | "The new grocery is a hit — Mr. Alvarez bought twelve avocados and won't say why." | `+grocery` |
| `praise_coffee_shop` ✓P7 | cozy | ☕ cozy! | "The coffee shop smells amazing — half the town is in there swapping stories." | `+coffee_shop` |
| `praise_hospital` | civic | 🚑 thank you | "The new hospital is open and the doctors send their heartfelt thanks, Mayor." | `+hospital` |
| `praise_solar_farm` | cozy | ☀️ sunshine | "The solar farm gleams in the sun — the whole city runs on sunshine now." | `+solar_farm` |
| `praise_recycling` | cozy | ♻️ green day | "Recycling day is the neighborhood's new favorite — green and clean!" | `+recycling_center` |
| `praise_high_rise` | silly | 🌆 what a view | "Whoa — you can see the whole town from the top floor! Residents are thrilled." | `+high_rise` |
| `praise_museum` | civic | 🏛️ grand opening | "The museum's grand opening drew a line all the way around the block." | `+museum` |
| `praise_stadium` | silly | 🏟️ the wave | "The first game sold out — the crowd did the wave for ten whole minutes!" | `+stadium` |
| `praise_zoo` | silly | 🦁 hello! | "The penguins have settled in and the whole city came to say hello." | `+zoo` |
| `praise_amusement_park` | silly | 🎢 wheee! | "The roller coaster's first riders are still grinning — what a day!" | `+amusement_park` |
| `praise_observation_tower` | cozy | 🗼 magical | "From the tower the city looks magical at night. You built this, Mayor." | `+observation_tower` |

### 4.3 Warning beats (imbalance the growth model is producing)

These narrate *why growth stalled*. The capacity-pressure cases are encoded as
the `⚠`-marked **demand** beats in §4.1 (each names the upgrade that relieves the
pressure, so the warning *and* the unlock are one bubble). The two genuinely
ratio-driven cases below have no single target building, so they need a small
`TriggerRule` extension (see §7) — drafted here, wired in Phase 9.

| Beat | Tone | Sticker | Text | Trigger (needs §7 extension) |
|---|---|---|---|---|
| `warn_lopsided` | civic | 🏚️ no homes! | "So many shops and not enough homes — folks love to visit, but nobody can stay! Let's build some housing." | `lopsided` flag (amenities ≫ housing) |
| `warn_growth_stalled` | civic | 🐌 stuck | "The city's stopped growing — something's holding it back. Check your power, water, clinics, and trash." | `population == capacity < housing` |

### 4.4 Recurring & milestone beats

| Beat | Kind | Tone | Text | Trigger |
|---|---|---|---|---|
| `demand_more_parks` ✓P7 | demand | cozy | (see §4.1 — re-fires with 🧱 spacing even after a park exists) | `+single_home 🧱since≥150` |
| `praise_established_town` ✓P7 | praise | civic | "The town's really taking shape — folks are proud to call it home. Nice work, Mayor!" | `+single_home age(mayors_office)≥10 fired:praise_first_home` |
| `milestone_big_city` | praise | civic | "From a single office to a whole skyline — what an incredible journey, Mayor." | `+high_rise age(mayors_office)≥40 fired:praise_established_town` |

### 4.5 Beat catalog totals

54 demand (one per non-starter building; 5 marked `⚠` are warning-toned
capacity asks) · 15 praise · 2 ratio-warnings · 3 recurring/milestone = **~74
beats** in this first pass. The hundreds-of-beats target is reached in Phase 9 by
adding flavor variants (multiple interchangeable texts per trigger, picked at
random) — a content multiplier on the same trigger set, not new mechanics.

---

## 5. Asset checklist

Every art/audio asset must be **CC0, CC-BY, or equivalent — CC-BY-NC and
CC-BY-NC-SA are excluded** (matches [curriculum.md](curriculum.md) §7 and the
licensing rules in [CLAUDE.md](CLAUDE.md)). Attribution accrues in
[LICENSES_THIRD_PARTY.md](LICENSES_THIRD_PARTY.md). Per
[plan.md](plan.md) Phase 9, art is a **hybrid pipeline**: CC0 isometric kits for
the anchors + procedural `CustomPainter` widgets for the long tail, with a
style-anchored image generator for the distinctive capstones.

**Per-building need:** one isometric sprite (PNG-with-transparency, single
dimetric 2:1 projection), with footprint metadata (`1×1` / `2×1` / `2×2`) and a
base anchor point so it sits on the grid. Phase-7's `assetRef` stays opaque, so
swapping emoji-placeholder → sprite is a resolver change with no domain churn.

| Building group (§3) | Art needed | Sourcing bucket | License target |
|---|---|---|---|
| Homes (`single_home`…`townhouse_row`, `farmhouse`) | small house sprites | **Kenney City Kit** (CC0) | CC0 |
| Apartments / towers (`apartment`, `mid_rise_apartment`, `high_rise`, `luxury_condo`, `business_tower`) | mid/high-rise sprites (2×2 for towers) | Kenney City Kit + **image-gen** for tall variants | CC0 / generated |
| Civic core (`mayors_office`…`post_office`) | civic-building sprites | Kenney + OpenGameArt (CC0/CC-BY) | CC0 / CC-BY |
| Services — utilities (`power_*`, `water_*`, `waste_*`, `recycling`, `solar_farm`) | industrial/utility sprites | Kenney City Kit **Industrial** (CC0) | CC0 |
| Services — civic (`clinic`, `hospital`, `school`, `high_school`, `fire_station`, `police_station`, transit) | service-building sprites | Kenney + OpenGameArt | CC0 / CC-BY |
| Commercial (`market_stall`…`shopping_mall`) | shopfront sprites | Kenney + **procedural** re-skins for variety | CC0 |
| Entertainment — green (`park`…`botanical_garden`) | parks/greenery tiles | Kenney nature + **procedural** | CC0 |
| Entertainment — capstones (`stadium`, `zoo`, `aquarium`, `amusement_park`, `observation_tower`) | distinctive signature sprites | **image-gen, style-anchored** to 2–3 Kenney refs | generated (verify license clean) |
| Long-tail re-skins / tier infills (§3.6) | palette/roof variants | **procedural `CustomPainter`** | n/a (code) |

**Audio** (deferred to Phase 11 per plan.md, listed for completeness): a
building-placed SFX and a bubble-pop SFX cover the whole catalog; capstones may
get a one-off fanfare. Source CC0 from Freesound / OpenGameArt.

**Image-gen note.** Style consistency is the binding constraint (plan.md "Art
roadmap"): feed the generator the same 2–3 anchor sprites as style references on
every prompt. Confirm output license is clean before bundling — generated art's
license status is the one yellow flag in this checklist; if it can't be cleared,
fall back to procedural or narrow the capstone set.

---

## 6. Implementation status

✅ markers per §3 building and §4 beat will be **auto-managed by**
`tools/city_builder/sync_implementation_status.py` (stood up in Phase 9, mirroring
[tools/curriculum/sync_implementation_status.py](tools/curriculum/sync_implementation_status.py)),
syncing against `building_registry.dart` / `beat_registry.dart` / `assets/data/city/`.
Until then the counts are tracked by hand.

**Implemented today (Phase 7 — 10 buildings, 13 beats):**
- **Buildings:** `mayors_office`, `single_home`, `apartment`, `school`, `clinic`,
  `power_plant`, `waste_management`, `grocery`, `coffee_shop`, `park`.
- **Beats:** `demand_first_home`, `praise_first_home`, `demand_school`,
  `demand_apartment`, `demand_clinic`, `demand_power`, `demand_waste`,
  `demand_grocery`, `demand_coffee_shop`, `demand_more_parks`, `praise_grocery`,
  `praise_coffee_shop`, `praise_established_town`.

**Remaining for Phase 9:** 45 buildings + ~61 beats from §3 / §4, plus the
`school` category move and the four new service IDs (`water`, `police`, `fire`,
`transit`).

---

## 7. Open questions

**Resolved during Phase 8 drafting (2026-05-31):**
- **Education category** → moved to `services` (`school` + `high_school`). Phase 9
  applies the one-field category change to the existing `school` row.
- **Water** → a **hard-gating** service (`water` joins `gatingServiceIds`), arc
  `water_tower` → `water_treatment`.
- **Housing depth** → keep all **7 rungs**; tune pacing by playtest.
- **Capstone gating** → capstones gate on **lifetime bricks** (300–1000) so they
  read as "you've practiced a lot" trophies. Applied in §3; confirm feel in
  playtest.

**Still open (need Phase-9 implementation or playtest):**
- **2×2 (and 2×1) footprints.** Every Phase-7 building is 1×1. The placement
  invariant in [placement_rules.dart](lib/domain/city/placement_rules.dart) already
  walks the real footprint ring, but the **renderer, tap-to-place hit-testing, and
  road generation** need verification/work for multi-tile buildings before the
  many 2×2 entries here can ship. First Phase-9 task on the art/placement track.
- **`TriggerRule` extension for ratio warnings.** `warn_lopsided` and
  `warn_growth_stalled` (§4.3) can't be expressed with the current
  buildingsPresent/absent/pop/age/beats/bricks fields — they need the growth
  model to surface a `lopsided` boolean and a `growthStalled` boolean into
  `TriggerContext`. Small, additive; the only mechanic touch Phase 9 needs beyond
  content. Everything else in this doc fits the existing typed rules.
- **Flavor-variant beats.** §4.5's path to "hundreds of beats" is multiple
  interchangeable texts per trigger, chosen at random. Confirm the
  `StoryBeat`/registry shape wants a `List<String>` of longTexts vs. separate beat
  rows — a Phase-9 authoring-ergonomics call.
- **Service-ratio & cost tuning.** All §3 numbers are designed-coherent
  placeholders; final values come from Phase-9 playtest (per plan.md's standing
  Phase-9 open question on residents-per-service and variety curves).
- **Per-tier upgrades vs. distinct types.** This design models progression as
  *distinct building types* in an arc (place a new high-rise next to the old
  apartment). Phase 9 also lists "building upgrade tiers" (upgrade-in-place, up to
  3 visual tiers). Decide per arc which rungs are new-type vs. in-place upgrades;
  the `maxTier` / `assetRefByTier` fields in the Data Model already anticipate the
  in-place path.
