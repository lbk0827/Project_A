# Kazena Combat Designer Portfolio Gap Analysis

Date: 2026-07-14

## Purpose

This document maps the current combat prototype to the Chaos Zero Nightmare combat designer opening and identifies the highest-value work needed before using the project as a portfolio piece.

The goal is not to present the project as a general game-development sample. The stronger positioning is:

> A collectible turn-based deckbuilding RPG combat prototype focused on character kit design, monster intent patterns, run-based encounter flow, and data-driven balancing.

## Job Posting Signals

The posting emphasizes the following combat design responsibilities:

- Character/hero design and balancing.
- Character/hero data work.
- Monster design and balancing.
- Monster data work.
- Level design through monsters.
- Combat system design.

The preferred qualifications also point toward:

- Understanding of collectible turn-based RPGs.
- Interest in deckbuilding board games and TCGs.
- Strategic thinking and enjoyment of strategic decision-making.
- Ability to design combat that is easy to enter but gains depth with familiarity.

## Current Project Fit

The project already has useful portfolio material for this role.

### Combat System

Relevant implementation:

- `project-a/scripts/core/ingame.gd`
- `project-a/scripts/core/run_state.gd`

Existing combat features:

- Hand, draw pile, discard pile, reshuffle flow.
- Energy-limited card play.
- Card targeting and all-enemy effects.
- Monster intent preview and shared enemy action countdown.
- Player HP, block, enemy HP, enemy block.
- RP skill selection and execution.
- Route selection into combat without a hard scene cut.

Portfolio angle:

> The prototype demonstrates a playable combat loop where card sequencing, enemy action timing, and route progression are connected in one run structure.

### Character Kit And Data

Relevant data:

- `project-a/data/generated/character_cards.json`
- `project-a/data/generated/card_effect_rows.json`
- `project-a/data/generated/character_rp_skills.json`
- `project-a/tables/excel/CharacterCards.xlsx`
- `project-a/tables/excel/CharacterRPSkills.xlsx`

Current character sample:

- Character: `tsuki`
- Starter deck: 9 cards from 8 unique card definitions.
- RP skill: `moon_slash`
- Core mechanics: attack cards, shield card, draw, attack damage buff, inspiration activation, inspiration payoff, all-enemy damage.

Portfolio angle:

> Tsuki can be framed as a burst-planning character whose accessible attack and defense cards are supported by deeper inspiration timing decisions.

### Monster And Encounter Data

Relevant data:

- `project-a/data/generated/monsters.json`
- `project-a/data/generated/monster_stats.json`
- `project-a/data/generated/monster_intents.json`
- `project-a/tables/excel/MonsterTable.xlsx`

Current monster set:

- `mire_imp`
- `bog_stalker`
- `bone_crawler`
- `gravebound_crawler`
- `frost_revenant`
- `crown_acolyte`
- `abyssal_crown_guardian`

Current intent set:

- `stab`: attack intent at 100% power.
- `heavy_blow`: attack intent at 150% power.
- `brace`: block intent at 80 power.

Portfolio angle:

> The monster data can be used to show encounter pacing, threat signaling, and how monster action cadence teaches the player when to attack, defend, or prepare a burst turn.

### Route And Level Flow

Relevant data:

- `project-a/data/map/DefaultRoute.tres`
- `Docs/BaseCamp_RunFlow_Design.md`

Current route structure:

- Base camp start.
- Branching early battle/event choice.
- Treasure, rest, elite, and boss nodes.
- Monster ids assigned to combat, elite, and boss nodes.

Portfolio angle:

> The route structure supports a small run arc: early onboarding, mid-run deck pressure, elite check, recovery decision, and boss test.

## Main Gaps Before Portfolio Use

### 1. Balance Rationale Is Missing

The project has numbers, but the portfolio needs to show why those numbers exist.

Current examples:

- Card damage values such as 100%, 180%, and 220%.
- Monster HP values from 500 to 2500.
- Monster attack values from 14 to 30.
- Enemy action counts of 2 or 3.

Needed additions:

- Average starter deck damage per turn.
- Average block generation per turn.
- Expected turns-to-kill by monster.
- Expected incoming damage by monster.
- Normal, elite, and boss difficulty targets.
- Cost efficiency table for each card.

Recommended output:

- `Docs/Plans/Combat_Balance_Report.md`
- Include at least one table with expected damage, expected survival pressure, and target turn count.

### 2. Character Design Intent Needs To Be Explicit

Tsuki has enough card mechanics to be a portfolio character, but the design intent should be written clearly.

Needed additions:

- Character fantasy.
- Combat role.
- Intended beginner loop.
- Intended expert loop.
- Strengths, weaknesses, and counter-pressure.
- Why each card exists in the starter deck.
- Why the RP skill complements the card kit.

Recommended output:

- `Docs/Plans/Tsuki_Character_Combat_Kit.md`

Suggested framing:

> Tsuki is a burst-oriented attacker. Beginners can play simple attack and defense turns, while experienced players use inspiration activation and payoff cards to build stronger multi-card turns.

### 3. Monster Roles Need Stronger Differentiation

The current monster set has data variation, but the design roles should be sharper.

Needed additions:

- Each monster's learning objective.
- Each monster's pressure type.
- How each monster asks the player to use Tsuki's kit differently.
- Why each monster appears at its route position.

Suggested role map:

| Monster | Proposed Role | Design Purpose |
| --- | --- | --- |
| Bog Stalker | Early tempo pressure | Teaches response to faster action cadence. |
| Gravebound Crawler | Mid-run endurance check | Tests whether the player can sustain through repeated threats. |
| Frost Revenant | Elite burst check | Tests defense timing and burst setup. |
| Abyssal Crown Guardian | Boss synthesis check | Tests target planning, burst windows, and long-fight resource pressure. |

Recommended output:

- `Docs/Plans/Monster_Level_Design_Report.md`

### 4. Deckbuilding Reward Loop Is Too Thin

The posting specifically values deckbuilding and TCG understanding. The current combat system has a persistent deck in `RunState`, but the visible reward loop is not yet strong enough.

Needed additions:

- Combat reward with 3 card choices.
- Optional skip reward.
- Card remove or upgrade option at rest/event.
- At least 2 build directions for Tsuki.

Possible build directions:

- Inspiration chain build: more inspiration activation and payoff.
- AoE burst build: all-enemy damage and RP acceleration.
- Defensive tempo build: shield, draw, and delayed burst.

Recommended implementation or design output:

- Minimal implementation: card reward selection after combat victory.
- Minimum documentation: reward pool table and build-path explanation.

### 5. Data Workflow Should Be Presented As Design Work

The project already has generated JSON and Excel table files. This is highly relevant because the posting explicitly mentions data work.

Needed additions:

- Short explanation of table-to-runtime data flow.
- Screenshot or export sample from the card and monster tables.
- Before/after example showing a balance change made through data.

Recommended portfolio section:

> Data workflow: card, effect, monster, and stat tables are maintained as designer-editable spreadsheets and exported to JSON used by the Godot runtime.

### 6. Text Encoding Must Be Cleaned For Submission

Some Korean text appears garbled in generated JSON and existing documents. This should not appear in a submitted portfolio.

Needed additions:

- Clean Korean display names in portfolio-facing docs.
- Avoid relying on corrupted glossary files for submission.
- Create new clean documents instead of trying to reuse broken text directly.

## Recommended Portfolio Package

The strongest submission package would include:

1. One-page combat overview.
2. Tsuki character kit sheet.
3. Card and effect data table excerpt.
4. Monster role and intent table.
5. Balance report with expected turn counts.
6. Route/encounter flow diagram.
7. Short gameplay video showing route selection, card play, monster intent response, victory, and next route choice.

## Suggested Work Order

### Priority 1: Balance Report

Create a spreadsheet or markdown report that answers:

- How much damage can the starter deck produce per turn?
- How many turns should each monster survive?
- How much HP should the player lose in each encounter?
- Which fight is the first real skill check?
- Which card or monster value was changed after testing, and why?

This is the most important missing evidence for a combat designer application.

### Priority 2: Tsuki Character Kit Sheet

Document:

- Character concept.
- Card list.
- Card purpose.
- Core loop.
- Advanced loop.
- RP skill purpose.
- Balance risks and tuning levers.

### Priority 3: Monster Level Design Report

Document:

- Monster-by-monster role.
- Intent pattern.
- Expected player response.
- Route placement.
- Difficulty curve.

### Priority 4: Deckbuilding Reward Spec

Add or document:

- Post-combat card reward.
- Reward pool.
- Build paths.
- Card rarity or appearance rules, if needed.

### Priority 5: Submission Cleanup

Prepare:

- Clean Korean text.
- Screenshots.
- Short gameplay capture.
- Portfolio PDF or Notion-style writeup.

## Recommended Portfolio Positioning

Use this project as a combat design case study, not as a broad game project.

Suggested title:

> Turn-Based Deckbuilding RPG Combat Prototype: Character Kit, Monster Intent, and Run Encounter Design

Suggested summary:

> I designed and implemented a small turn-based deckbuilding combat prototype with data-driven cards, effects, monsters, stats, and route encounters. The prototype focuses on an accessible starter loop that develops into deeper strategic decisions through card sequencing, inspiration timing, monster intent reading, and run-based encounter pressure.

## Final Assessment

The current project is suitable for the portfolio, but it needs stronger designer-facing evidence before submission.

The most valuable next step is not more visual polish. It is a clear balance and design rationale package that proves the combat numbers, character kit, monster roles, and route structure were intentionally designed and iterated.
