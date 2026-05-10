# Card UI PRD

## Purpose

Build a readable and responsive card battle UI that can grow from the current prototype into a data-driven card system.

## Current State

- `CardView.tscn` is used as a reusable template for one card.
- `main.gd` creates one `CardView` instance per card in the current hand.
- Prototype cards are defined in `CARD_LIBRARY` inside `main.gd`.
- The previous full-screen dim background and temporary debug UI have been removed.

## Goals

1. Complete the basic card UI interaction.
2. Add a compact battle HUD for playtesting.
3. Move card definitions out of `main.gd` into external data.
4. Replace card-id-specific effect branches with a reusable effect system.
5. Improve card play flow with targeting and animations.

## Milestone 1: Card UI Basic Completion

### Scope

- Display each card using its card frame, cost, name, and description.
- Show attack and skill cards with the correct frame texture.
- Disable cards when they cannot be played.
- Add hover feedback:
  - hovered card rises above the hand
  - hovered card scales up slightly
  - hovered card renders above neighboring cards
- Add a light hand fan layout so the hand reads as a card hand rather than a flat button row.

### Out of Scope

- Drag-and-drop card play.
- Target selection.
- Draw/discard animations.
- Final card art and final typography.

## Milestone 2: Minimal Battle HUD

### Scope

- Player HP, block, and energy.
- Enemy HP, block, and intent.
- End Turn and Restart controls.
- Minimal layout that does not obscure the character.

## Milestone 3: Card Data Separation

### Preferred Workflow

- Keep editable design data in Excel or a spreadsheet if needed.
- Export the runtime data to JSON or CSV.
- Load runtime card data from `res://data/cards.json` or similar.

### Recommendation

Use JSON first because card effects will likely become nested and composable.

## Milestone 4: Card Effect System

### Scope

- Represent each card as a list of effects.
- Support damage, block, draw, and energy gain.
- Remove direct `match card["id"]` branches for basic cards.

## Milestone 5: Improved Play Flow

### Scope

- Attack cards can target enemies.
- Skill cards can resolve immediately.
- Played cards move to discard with feedback.
- Cards preview whether they are playable.

## Acceptance Criteria

- Play mode shows a hand of multiple card instances from one `CardView` template.
- Hovering a playable card gives immediate visual feedback.
- Unplayable cards are visibly disabled and do not emit play actions.
- The current prototype remains playable with Slash, Guard, Focus, and Heavy Slash.
