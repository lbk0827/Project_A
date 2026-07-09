# BaseCamp Run Flow Design

## Purpose

This document records the agreed run-start and route-selection flow for the current combat prototype.
The target feel is close to the reference clip `Docs/RefClip/BaseCampStartNext.MP4`: the player should not feel a hard scene cut between route selection and combat. Instead, the route UI, camera, battlefield, and combat HUD should transition inside one continuous run screen.

## Reference Observations

From the Kazena reference clip:

1. The player starts in a non-combat route-selection state.
2. Characters remain visible on the left side of the battlefield.
3. A compact minimap sits in the lower-left corner.
4. Up to three next-node choices float on the right as destination tiles.
5. Selecting a node highlights that node with a short glow.
6. The view moves/zooms toward the selected destination tile rather than fading to a loading screen.
7. Route UI disappears and combat HUD appears.
8. The enemy is already staged in the same visual field when combat begins.
9. A centered `BATTLE START` style banner plays before hand/card interaction begins.

The important UX takeaway is continuity: node selection and combat entry should feel like one in-world flow, even if implementation swaps runtime state behind the scenes.

## Prototype Target Flow

### New Game

1. Title screen `새 게임` is pressed.
2. `RunState.reset_run()` initializes the run at `base_camp`.
3. The game enters `InGame`.
4. `InGame` detects route-selection mode because there is no active combat node.
5. BaseCamp background is shown.
6. Heroine is visible and idle.
7. Enemies, card hand, energy controls, and battle HUD controls are hidden.
8. `BattleMapOverlay` opens immediately.
9. The player chooses one connected next node.

### Selecting a Combat Node

1. The selected route choice is highlighted.
2. The route overlay plays a short Kazena-style commit animation.
3. `RunState.start_combat_node(node_id, monster_id)` records the active combat.
4. `InGame` swaps into combat presentation without going through the standalone `MapScreen`.
5. BaseCamp UI disappears.
6. The stage background changes to the combat stage.
7. Enemy nodes are spawned.
8. Combat HUD is shown.
9. `BATTLE START` / player-turn banner plays.
10. Cards are drawn and the normal combat loop begins.

### Selecting a Result Node

For the current prototype, result nodes resolve instantly inside the overlay:

- Event: gain prototype gold.
- Treasure: gain prototype gold.
- Rest: heal.

After resolution, `RunState.current_node_id` becomes the selected result node, the node is marked complete, and `BattleMapOverlay` refreshes to show the next connected route choices.

### Winning Combat

1. Combat victory marks the active combat node complete.
2. `RunState.current_node_id` becomes the completed combat node.
3. If this was the boss node, the run is cleared.
4. Otherwise `BattleMapOverlay` opens over the same battlefield.
5. The player chooses the next connected node.

## Route Node Model

The run starts at `base_camp`, which replaces the previous abstract `start` node.

`base_camp` rules:

- Type: `base_camp`
- Has no event payload.
- Is not marked completed.
- Exists only as a route origin and safe visual staging point.
- Immediately exposes its connected next nodes.

Combat nodes:

- `battle`
- `elite`
- `boss`

Result nodes:

- `event`
- `treasure`
- `rest`

## UI Requirements

### BattleMapOverlay

The overlay is the main route-selection UI.

Required elements:

- Lower-left minimap.
- Up to three right-side destination choices.
- Current-node indicator.
- Completed-node indicator.
- Selectable-node emphasis.
- Compact run status: HP, gold, path count, and short result messages.

### Minimap Visual Direction

The minimap should follow the reference:

- Dark translucent panel.
- Diagonal grid.
- Diamond-shaped nodes.
- Thin connecting lines.
- Current route column or current node highlight.
- Clean compact layout; it should read as context, not the main decision surface.

### Right-Side Destination Choices

The right-side choices should feel like in-world destination tiles:

- Large floating tile silhouettes.
- Cyan-ish outline/glow.
- Right-side vertical type flag.
- Small arrow/caret leading into the destination.
- Stronger highlight when selected.

### Combat HUD Visibility

In route-selection mode:

- Hide card hand.
- Hide deck/tomb counters.
- Hide energy and end-turn controls.
- Hide enemy status bars because no enemy exists.

In combat mode:

- Show normal battle HUD.
- Use existing card draw, energy, targeting, and enemy intent flow.

## Scene Strategy

Use `InGame` as the single run screen for now.

This avoids a hard visual cut and matches the reference better than:

- Title -> `MapScreen` -> `InGame`
- Combat -> `MapScreen`

The standalone `MapScreen` can remain as a debug/full-map scene, but the main player flow should use `BattleMapOverlay` inside `InGame`.

## BaseCamp Stage Art

The first BaseCamp stage should be a wide 1280x720 background.

Suggested visual direction:

- Safe camp inside a dark ruined industrial/urban environment.
- Cool blue ambient light with warmer camp lights.
- Enough empty space on the left/center for the heroine.
- Enough darker negative space on the right for destination-choice UI.
- No characters, readable text, logos, or UI baked into the image.

## Implementation Notes

Short-term implementation can be intentionally simple:

- `RunState.START_NODE_ID = "base_camp"`.
- `MapRouteData` owns route nodes and starts at `base_camp`.
- Title start/continue enters `InGame`.
- `InGame._ready()` branches:
  - route mode: BaseCamp background + heroine + overlay.
  - combat mode: combat background + enemies + battle start.
- `BattleMapOverlay` emits node selection.
- `InGame` handles node selection and switches state.

## Known Follow-Ups

- Add actual event/treasure/rest choice UIs.
- Add card reward after combat.
- Add a proper route-choice commit animation with camera pan/zoom.
- Let combat stage backgrounds vary per node.
- Decide whether Continue should restore mid-combat state or always return to route selection.
- Replace placeholder type glyphs with final icons.
