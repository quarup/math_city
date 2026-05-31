# Math City — City Builder Reference

> Canonical reference for the Math City city-builder content: the building DAG,
> the citizen story-beat catalog, and the asset checklist.
> Companion to: [prd.md](prd.md) (product scope), [plan.md](plan.md) (execution),
> and [curriculum.md](curriculum.md) (the math content — this doc is its city-side analogue).

---

## Status

- **Last updated:** 2026-05-31
- **Phase:** Phase 8 — City Builder: Research & Rich Design. Content-authoring only, **no code changes**. Deliverable is this document; Phase 9 implements it.
- **Drafting mode:** *structure-first*. §1 (references) and §2 (categories) are drafted in full. **§3 is currently a DAG skeleton** — building IDs, categories, within-category arcs, and the prereq graph are laid out, but the per-building cost / service-profile / full `unlockRule` / emoji specs are **pending review** before they're filled in. §4–§7 are stubbed pending the §3 review.
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

## 3. Building catalog — DAG skeleton *(full specs pending review)*

> **This section is a skeleton.** It lays out the four within-category arcs, the
> building IDs, their tier (early / mid / late game), and the prereq graph (what
> each rung chains from). The full per-building spec — 🧱 `brickCost`,
> 🔬 `researchCost`, `populationContribution`, `serviceProvision`,
> `varietyContribution`, `footprint`, `emoji`, and the complete typed
> `unlockRule` — is **filled in after the structure review**.
>
> **Reading the arcs:** "chains from" lists the building(s) a rung's `unlockRule`
> requires via `requiredBuildingsPlaced`, plus any `minPopulation` /
> `minLifetimeBricks` gate. As in Phase 7, **every non-starter building also names
> a demand beat in `requiredBeatsRead`** (§4) — that demand bubble is what reveals
> the research card. The prereq-building + population/brick gates shape *when* the
> demand can fire; reading it is what surfaces the card.
>
> **Tiers** are a narrative pacing label (not a schema field): **Early** = first
> founding moves, **Mid** = a growing town, **Late** = a full city, **Capstone** =
> aspirational landmark. They map loosely to rising population / lifetime-brick
> gates.

### 3.1 Civic & Housing (`civicHousing`)

**Civic-core line** (unique anchors; each is the narrative+unlock hub of its era):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `mayors_office` | Mayor's office | Early | — (starter, ungated, unique) | The founding tile; everything chains off it |
| `town_hall` | Town hall | Mid | `mayors_office` + pop gate | Mid-game civic upgrade; gates several mid services |
| `city_hall` | City hall | Late | `town_hall` + pop gate | Late-game civic capstone (unique) |
| `library` | Library | Mid | `school` | Soft education amenity; cozy/civic beats |
| `post_office` | Post office | Mid | `town_hall` | Small civic amenity |

**Housing line** (the population spine — a clean upgrade ladder, rising `populationContribution`):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `single_home` | Single home | Early | `mayors_office` | First housing; smallest pop |
| `duplex` | Duplex | Early–Mid | `single_home` | 2× a home |
| `townhouse_row` | Townhouse row | Mid | `duplex` + pop gate | Denser low-rise |
| `apartment` | Apartment | Mid | `single_home` + pop gate | Existing Phase-7 rung |
| `mid_rise_apartment` | Mid-rise apartments | Mid–Late | `apartment` + pop gate | Steps up density |
| `high_rise` | High-rise tower | Late | `mid_rise_apartment` + pop + brick gate | Big density (2×2 footprint) |
| `luxury_condo` | Luxury condo | Late | `high_rise` | Lower pop, higher desirability (variety-counts) |
| `farmhouse` | Farmhouse | Early | `single_home` | Countryside-flavor home (cozy beats; small pop) |

### 3.2 Services (`services`)

Gating infrastructure (lifts hard population ceilings) + soft amenities (desirability only).

**Power** (`power`, gating):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `power_plant` | Power plant | Mid | `single_home` | Existing Phase-7 rung; base power |
| `power_station` | Power station | Late | `power_plant` + pop gate | Higher `power` capacity |
| `solar_farm` | Solar farm | Late | `power_station` | Clean-energy capstone (entertainment-adjacent praise) |

**Water** (`water`, gating — **new service ID**):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `water_tower` | Water tower | Early–Mid | `single_home` | Base `water` capacity |
| `water_treatment` | Water treatment plant | Mid | `water_tower` + pop gate | Higher `water` capacity |

**Waste** (`waste`, gating):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `waste_management` | Waste management | Mid | `single_home` + pop gate | Existing Phase-7 rung (warning beat) |
| `recycling_center` | Recycling center | Late | `waste_management` | Higher `waste` capacity; green praise |

**Health** (`clinic`, gating):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `clinic` | Clinic | Mid | `single_home` | Existing Phase-7 rung |
| `hospital` | Hospital | Late | `clinic` + pop gate | Big `clinic` capacity (2×2) |

**Education** (`school`, soft):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `school` | School | Mid | `single_home` | Existing rung *(currently `civicHousing` in Phase 7 — see §7 reclassification note)* |
| `high_school` | High school | Late | `school` + pop gate | Higher education amenity |

**Safety** (soft — **new service IDs `police`/`fire`**):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `fire_station` | Fire station | Mid | `town_hall` | Safety amenity; civic beats |
| `police_station` | Police station | Mid | `town_hall` | Safety amenity; civic beats |

**Transit** (soft — **new service ID `transit`**):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `bus_depot` | Bus depot | Late | `city_hall` | Transit amenity |
| `train_station` | Train station | Capstone | `bus_depot` + pop gate | Transit capstone (2×2) |

### 3.3 Commercial (`commercial`)

Shops / food / offices — the desirability-multiplier and "town life" channel (all variety-counts).

**Food & daily goods:**

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `market_stall` | Market stall | Early | `single_home` | Tiny first shop |
| `grocery` | Grocery | Early–Mid | `single_home` | Existing Phase-7 rung |
| `supermarket` | Supermarket | Mid | `grocery` + pop gate | Bigger grocery |
| `bakery` | Bakery | Mid | `grocery` | Cozy food shop |
| `coffee_shop` | Coffee shop | Early–Mid | `single_home` | Existing Phase-7 rung |
| `restaurant` | Restaurant | Mid | `coffee_shop` | Food/social |
| `farmers_market` | Farmers market | Mid | `farmhouse` | Countryside-flavor commercial |

**Retail & offices:**

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `bookshop` | Bookshop | Mid | `library` | Small retail (ties to education) |
| `toy_store` | Toy store | Mid | `grocery` | Kid-delight retail |
| `clothing_store` | Clothing store | Mid | `supermarket` | Retail |
| `office_building` | Office building | Mid–Late | `town_hall` | Jobs flavor |
| `shopping_mall` | Shopping mall | Late | `supermarket` + `clothing_store` + pop gate | Big retail (2×2; multi-parent) |
| `business_tower` | Business tower | Late | `office_building` + pop gate | Commercial capstone (2×2) |

### 3.4 Entertainment (`entertainment`)

Parks / culture / recreation — the cozy, praise-heavy delight channel (all variety-counts).

**Green & cozy:**

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `park` | Park | Early | `single_home` | Existing Phase-7 rung (recurring demand) |
| `playground` | Playground | Early | `park` | Kid-delight; small |
| `community_garden` | Community garden | Early–Mid | `park` | Cozy green |
| `fountain_plaza` | Fountain plaza | Mid | `town_hall` | Decorative civic-adjacent delight |
| `botanical_garden` | Botanical garden | Late | `community_garden` + pop gate | Bigger green attraction |

**Recreation & culture:**

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `sports_field` | Sports field | Mid | `school` | Recreation (ties to education) |
| `swimming_pool` | Swimming pool | Mid | `sports_field` | Recreation |
| `movie_theater` | Movie theater | Mid | `restaurant` | Culture/social |
| `museum` | Museum | Mid–Late | `library` | Culture (ties to education) |
| `stadium` | Stadium | Late | `sports_field` + pop gate | Big recreation (2×2) |

**Capstone attractions** (aspirational, late-game, big footprints, signature praise beats):

| ID | Name | Tier | Chains from | Role |
|---|---|---|---|---|
| `zoo` | Zoo | Late | `botanical_garden` + pop gate | Signature attraction (2×2) |
| `aquarium` | Aquarium | Late | `museum` + pop gate | Signature attraction (2×2) |
| `amusement_park` | Amusement park | Capstone | `stadium` + pop + brick gate | Signature attraction (2×2) |
| `observation_tower` | Observation tower | Capstone | `city_hall` + brick gate | City landmark (signature) |

### 3.5 Long-tail variants (patterned, not itemized)

Beyond the ~55 anchors above, the "feels infinite" long tail is generated by
*pattern*, not by hand-authoring hundreds of unique rows. Three patterns, to be
specified concretely in the fill pass:

1. **Cosmetic re-skins** of an existing rung (e.g. a home with a different roof
   color) — same stats, different `assetRef`/`emoji`, no new `unlockRule` logic.
2. **Tier infills** — additional rungs slotted between two anchors when play shows
   a pacing gap (the arc shape already supports it; just a new `requiredBuildingsPlaced`).
3. **Map-themed variants** (countryside / city / futuristic, Phase 9 maps) — the
   same arc re-skinned per theme. The `farmhouse` / `farmers_market` pair is the
   first countryside seed.

**Skeleton totals:** 13 civic & housing · 15 services · 13 commercial · 14 entertainment = **55 anchor buildings**, plus the three long-tail patterns.

### 3.6 DAG sanity (skeleton-level)

- **No cycles:** every "chains from" points to an earlier/same-tier rung; the
  graph is a forest rooted at `mayors_office` (+ its `single_home` child, off
  which every service/commercial/entertainment arc hangs).
- **Multi-parent nodes** (intentional, narratively sensible): `shopping_mall`
  (supermarket + clothing store) and a few "ties to education/green" soft links
  (`bookshop`←library, `sports_field`/`museum`←education/library). To be reviewed
  for coherence in the fill pass; nothing requires an unrelated cross-category
  prereq.
- **Every building gets ≥1 trigger beat** in §4 (to be authored against this list).

---

## 4. Story beat catalog *(stub — authored after §3 review)*

Will mirror §3: for every building, at least one **demand** beat (the discovery
gate via `requiredBeatsRead`) and, where it fits, a **praise** beat on placement;
plus **warning** beats for the imbalance cases the growth model produces
(under-served gating service, lopsidedness). Each beat: `id`, `kind`
(demand/praise/warning), `tone` (silly/civic/cozy), `emoji`, `shortLabel`,
`longText`, `triggerRule`, cross-referenced to its §3 building ID(s). Target:
the rich hundreds-of-beats catalog, authored in clusters per arc.

---

## 5. Asset checklist *(stub — authored after §3 review)*

Per §3 building: art needed (isometric tile sprite, per-tier where applicable),
sourcing strategy (Kenney City Kit / OpenGameArt / procedural `CustomPainter` /
image-gen), and license — **CC0 / CC-BY / equivalent only; CC-BY-NC and
CC-BY-NC-SA excluded** (matches [curriculum.md](curriculum.md) §7 /
[LICENSES_THIRD_PARTY.md](LICENSES_THIRD_PARTY.md)). Tracks the Phase 9 "Building
art pipeline" decision (CC0 kits for anchors + procedural for the long tail).

---

## 6. Implementation status *(stub — Phase 9 ticks these)*

Will carry ✅ markers per §3 building and §4 beat, auto-managed by
`tools/city_builder/sync_implementation_status.py` (to be stood up in Phase 9,
mirroring `tools/curriculum/sync_implementation_status.py`). Initially the only
✅ rows are the Phase-7 set: `mayors_office`, `single_home`, `apartment`,
`school`, `clinic`, `power_plant`, `waste_management`, `grocery`, `coffee_shop`,
`park` and their nine Phase-7 beats.

---

## 7. Open questions

- **Education reclassification.** Phase 7 placed `school` under `civicHousing`;
  this design groups education under `services` (with `high_school`) for taxonomic
  cleanliness. Phase 9 should reconcile — either move `school`'s category (a
  one-field content change) or keep it in `civicHousing` and note the exception.
  *Decision needed before fill.*
- **New service IDs.** `water` (gating), `police` / `fire` / `transit` (soft) are
  proposed additions to `serviceProvision` keys + `gatingServiceIds`. Confirm we
  want `water` as a *second* hard-gating service (more infrastructure pressure
  early) vs. keeping it soft.
- **Tier count per arc.** Housing has 7 rungs; is that the right depth, or should
  the spine be shorter (less grind) / longer (more "next rung")? Needs playtest.
- **Capstone gating.** Should capstones (amusement park, observation tower, train
  station) gate on *lifetime bricks* (total practice) so they read as "you've
  played a lot" trophies, or purely on city state? Leaning lifetime-brick.
- **Service-ratio + cost numbers.** All deferred to the fill pass and ultimately
  to Phase 9 playtest tuning (per plan.md's Phase-9 open question).
