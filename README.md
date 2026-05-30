# Vatbreak — Game Design Document
*TINS 2026 Game Jam Entry · 72-Hour Jam*

---

## 1. Project Overview

| Field | Value |
|---|---|
| Title | Vatbreak |
| Engine | Godot 4.x |
| Genre | Twin-stick Bullet Heaven |
| Estimated Dev Time | ~15 hours |
| Theme | Alien zoo containment failure / nano-weapons / John Scalzi references |
| Platform Target | PC + Web (itch.io) |

---

## 2. Concept & Narrative

In the far future, humanity operates ZooCorps™ — commercial alien zoos where extraterrestrial species catalogued by the Colonial Defense Forces are grown in sealed vats inside each enclosure and displayed to tourists. During a routine system update, a buffer overflow in the central breeding controller causes every vat to enter an uninterrupted reproductive loop.

The vats overflow. The enclosures fill beyond capacity. The aliens break free.

By the time you arrive, the zoo is already lost. Aliens of every species roam the entire facility. You are a ZooCorps containment officer armed with the **MP-35** ("empee"), a CDF-derived nano-rifle whose smart ammunition reassembles in the clip before firing — a direct descendant of the adaptive weapons technology developed for CDF soldiers in their engineered bodies. Your mission: fight through the overrun zoo, locate the breached enclosures, and destroy the vats inside. Each vat is the source of one alien species — destroy it, and that species stops spawning.

Enclosures are named after alien species and factions from John Scalzi's *Old Man's War* universe.

---

## 3. TINS Rules Compliance

| Rule | Description | How Satisfied |
|---|---|---|
| Genre #157 | It's a Zoo! | The entire game is set inside a single futuristic alien zoo facility. The breached enclosure layout drives the map structure and the narrative premise. |
| Art #84 | Include references to the works of a science fiction author of your choice. | Enclosures, alien species, weapons tech, and flavour text all reference John Scalzi's *Old Man's War* universe — the MP-35 descends from CDF adaptive weapon technology; enclosures are named after Scalzi alien species. |
| Tech #132 | Catastrophic overflow: Chaos ensues as the capacity of some container is exceeded. | Breeding vats are literal containers. Their overflow is the inciting catastrophe and the core gameplay trigger — the entire starting state of the map (aliens everywhere) is the direct consequence of the vats overflowing. |
| Bonus Rule | Something important must change over time in a way the player can notice and interact with. | The **Vat Bloom System**: unattended vats advance to a second stage with a visible color change, doubling their spawn rate. Destroying a vat of a given species permanently stops that species from spawning. Both changes are visible and alter how the player moves through the map. |

---

## 4. Core Gameplay

### 4.1 Loop

The game is a single large map. When the player spawns in, all alien species are already present across the entire map. Semi-enclosed breached enclosures are scattered throughout — each contains one vat responsible for spawning one alien species.

The player must:

1. Survive the mixed alien hordes using movement, positioning, and ammo mode switching
2. Navigate to each breached enclosure and destroy the vat inside
3. Destroy all vats to win

Destroying a vat immediately stops that species from spawning. The map progressively gets less chaotic as vats fall. If the player dies, it's game over.

### 4.2 Controls

| Action | Input |
|---|---|
| Move | WASD / Left stick |
| Aim | Mouse cursor / Right stick |
| Fire | Left mouse button / Right trigger |
| Cycle ammo mode | Scroll wheel / Bumpers |
| Quick-swap to last mode | Middle mouse / Left bumper |

### 4.3 The MP-35 "Empee" Nano-Rifle

A CDF-lineage weapon issued to ZooCorps containment teams. The nano-cells in the clip reassemble between shots into one of three configurations. Mode is selected before firing; switching has no cooldown. Ammo is effectively unlimited — the nano-cells recycle themselves.

| Mode | Behaviour |
|---|---|
| **BULLET** | High fire rate, single-target, low per-shot damage. Best against individual tough enemies and precise targeting of vat weakpoints. |
| **GRENADE** | Slow projectile, large AOE explosion on impact. High burst damage. Has an arming distance — won't explode at point-blank range. Best against dense clusters and vat shields. |
| **BEAM** | Continuous hitscan ray, very low damage per tick but applies Nano-Burn DoT that stacks. Best against slow tank enemies and softening vat health over time. |

### 4.4 The Vat Bloom System

Each surviving vat advances to a second stage over time. This is something the player can **notice** (the vat's glow shifts from green to red) and **interact with** (a bloomed vat spawns its species twice as fast, making it a higher-priority target).

| Stage | Visual | Effect |
|---|---|---|
| 1 — Active | Green glow | Standard spawn rate |
| 2 — Bloomed | Red glow | Spawn rate doubled |

---

## 5. Enemies

All alien species are named after creatures and factions from the *Old Man's War* universe. Each species is tied to one vat. Destroying that vat stops the species from spawning; existing aliens of that type remain until killed.

| Enemy | Behaviour | Scalzi Reference |
|---|---|---|
| **Consu Crawler** | Fast, low HP, swarms in groups | The Consu — powerful, numerous, alien in motivation |
| **Fnitu Drifter** | Mid-range, fires slow acid globs | Inspired by the strange biology of non-humanoid CDF enemy species |
| **Rraey Brute** | Slow, very high HP, charges in straight lines | The Rraey — militaristic, physically imposing |
| **Obin Seer** | Rare elite; teleports, spawns adds | The Obin — emotionless but capable of collective emergent behaviour |
| **Vat** *(structure)* | Stationary; has a health bar, bloom-stage glow, and a weakpoint that takes double damage from Bullet mode | — |

---

## 6. Level Structure

One large map. Three breached enclosures are distributed across it, each semi-open (walls partially destroyed). The player navigates between them through open zoo corridors already swarming with aliens from the start.

| Enclosure | Name | Vat / Species | Notes |
|---|---|---|---|
| A | **Consu Wing** | Consu Crawler vat | Closest to spawn, most open approach |
| B | **Rraey Terrarium** | Rraey Brute vat | Mid-map, tighter corridors nearby |
| C | **Obin Habitat** | Obin Seer vat | Farthest from spawn, hardest to reach |

The Fnitu Drifter vat can be placed as a fourth enclosure if time allows, or Drifters can be removed from the roster to keep scope tight.

---

## 7. Development Scope & Priorities

### Must-Have (Core Loop)
- Player movement (8-directional, constant speed)
- MP-35 with all three ammo modes
- Basic enemy AI: move toward player, deal contact/projectile damage
- Vat structure with health bar, bloom timer, and per-species spawn link
- Single map with all enclosures and win/lose condition
- Basic HUD: health, vat status indicators (one per species, showing bloom state)
- Title screen with game name and plot summary

### Should-Have (Polish)
- All 4 enemy types
- Bloom visual (vat glow shifts green → red)
- Web export for itch.io submission
- Kill feedback when a vat is destroyed (species-stop notification)

### Nice-to-Have (Stretch)
- Screen shake and hit-feel juice
- Wall crack visual on vat at Stage 2
- Simple end screen with time and vats destroyed
- Scalzi-flavoured text on title or end screen

### Hour Budget

| Task | Est. Time |
|---|---|
| Project setup + scene structure | 1h |
| Player controller + aiming | 1.5h |
| MP-35 weapon (3 modes) | 2h |
| Enemy base AI + 2 enemy types | 2h |
| Vat system (bloom, health, spawn link) | 1h |
| Single map layout + tilemap | 2h |
| HUD + UI | 1h |
| Enemy types 3 & 4 | 1h |
| Title screen (name + plot text) | 0.5h |
| Web export + packaging | 0.5h |
| Polish, playtesting | 1.5h |
| **TOTAL** | **~14 hours** |

---

## 8. Godot Implementation Notes

### 8.1 Scene Structure

| Scene | Description |
|---|---|
| `Main.tscn` | Root. Holds HUD, the level, and GameState autoload. |
| `Player.tscn` | CharacterBody2D. Children: Sprite, CollisionShape, GunPivot (Node2D), MP35.tscn. |
| `MP35.tscn` | Node2D on GunPivot. Manages ammo mode state and fires projectile scenes. |
| `Bullet/Grenade/Beam.tscn` | Three separate projectile scenes with a shared base script. |
| `Enemy.tscn` | CharacterBody2D base, inherited by each enemy type scene. |
| `Vat.tscn` | StaticBody2D. Holds bloom timer, health, stage state, species reference, and spawn trigger. |
| `Level.tscn` | Single TileMap containing all enclosures, initial enemy spawn markers, and vat placements. |
| `TitleScreen.tscn` | Static screen with game name, plot summary, and start button. |

### 8.2 Key Implementation Notes

- **GameState autoload:** tracks remaining vat count per species. When a vat is destroyed, it signals GameState to stop spawning that species. Win condition triggers when all vats are at zero.
- **Initial enemy population:** on Level load, place a set of pre-positioned enemy instances across the full map (not spawned by vats) so the map is already populated from the first second. Vats then continuously add more.
- **Enemy spawning:** each Vat has a Timer whose `wait_time` halves on bloom. On timeout, instance an enemy of the linked species at a random spawn point within the enclosure radius.
- **Species stop on vat death:** Vat emits a `vat_destroyed(species_id)` signal. GameState receives it and sets a flag. Each enemy spawner checks this flag before spawning. Existing enemies of that type are unaffected.
- **Beam mode:** use a `RayCast2D` updated every physics frame while fire is held. Apply damage via a repeating Timer (tick every 0.1s). Apply a `NanoBurn` status resource to hit enemies.
- **Grenade arming:** track distance travelled in `_physics_process`; set `can_explode = true` after ~80px.
- **Bloom visuals:** `PointLight2D` on each vat, tweened from green to red modulate on bloom trigger.
- **Camera:** simple follow camera on the player with gentle smoothing. No scene transitions mid-game.

---

## 9. Art Direction Notes

Visual style: top-down 2D, clean pixel art or simple vector shapes. Readability over detail given time constraints.

- **Vats:** cylindrical silhouette, centre glow green at Stage 1, red at Stage 2.
- **Aliens:** each species has a distinct silhouette — Crawler (small, round), Drifter (floating, wispy), Brute (wide, slow), Seer (tall, angular). All share a bioluminescent element.
- **Map:** open zoo corridors connecting semi-ruined enclosures. Broken walls indicate breached areas. Each enclosure visually distinct (terrain color, props) to aid navigation.
- **HUD:** minimal. Health bar top-left. Ammo mode indicator (three icons, active one highlighted) bottom-centre. Vat status row top-right: one icon per enclosure, green/red/destroyed.
- **Title screen:** game name, two or three sentences of plot, start button. Scalzi flavour quote optional.

---

*Good luck, officer. The vats are blooming.*
