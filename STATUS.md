# Phase 0 + 1 handoff

Standalone, single-player Godot 4.6.3 mechanics prototype. Built-in Jolt Physics and procedural geometry; no dependencies, external services, multiplayer, economy, or whole-house content.

## Architecture

- `scenes/jobsite.tscn`: root scene; `scripts/jobsite.gd` builds the fixtures and UI.
- `jobsite.gd`: local command validation, inventory and HUD. Future host authority belongs at this boundary; no network transport exists yet.
- `wall_frame.gd`: typed free/held/placed/braced/fastened states, conservative solid collision envelope, capped swept carry, checked rotation, snap placement, logical fasteners and reset.
- `player.gd`: capsule movement, view ray, first-person hammer and bounded feedback.
- `geometry.gd`: procedural boxes, colliders and signs.
- `tests/smoke.gd`: focused state/collision integration tests.
- `tests/controls.gd`: synthetic input events through the rendered game's real input handlers.

## Verified

Godot 4.6.3.stable.official.7d41c59c4: import and startup pass; 45 state/collision assertions and 24 rendered input assertions pass. The actual OpenGL/Mesa screenshot is `evidence/assembled.png`. Software display warns that VSync changes are unsupported. No gameplay script errors were observed in the final checks.

Tests cover grab/release, rotation, carry obstruction, player collision, placement alignment, brace collection/installation, twelve hammer strikes, cooldown, completion, reset, WASD, mouse look, and cursor capture. Actor-position fixtures isolate interactions; these tests are not a continuous navigation replay or human playtest. Human feel, audible sound, Windows runtime, hardware performance and prolonged adversarial collision testing remain untested.

## Deliberate limits

The upright frame uses one solid envelope, including the visible spaces between studs. The brace is a logical inventory item and installed visual; hammer is equipped from spawn. Carry speed is capped at 4.5 m/s; player speed at 3.5 m/s. Out-of-bounds and reset paths recover the job.

Selected visual direction: Scruffy Suburbia, with lanky workers and deliberately silly faces. Only a simple first-person forearm/glove blockout exists. No individual face selected, detailed character art, or customization implemented.

See README for play and test instructions; NEXT.md describes two-peer co-op priorities before further content.
