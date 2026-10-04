# BARELY UP TO CODE — Phase 0 + 1 mechanics prototype

Standalone single-player Godot graybox. Selected direction: Scruffy Suburbia, with lanky workers and deliberately silly faces. This mechanics build only adds a default long forearm/glove blockout; detailed art and customization are deferred. No multiplayer, economy, whole house, characters, paid assets, add-ons, or external services.

## Engine and run

Pinned to **Godot 4.6.3.stable.official.7d41c59c4**, the engine already installed in the development environment. Built-in Jolt Physics; GL Compatibility renderer. No extension or package installation required.

Open `project.godot` in this version and press F6 on `scenes/jobsite.tscn`, or F5. From a terminal: `godot --path /path/to/barely-up-to-code`. Requires a graphical desktop for play. No export templates needed for source-project play. This ZIP is source, not a standalone executable.

## Windows quick start

1. Use **Godot Engine 4.6.3 Standard** for Windows (GDScript; .NET is not required).
2. On this repository, choose **Code → Download ZIP**, then extract the ZIP fully.
3. Open Godot's Project Manager, click **Import**, browse to the extracted `project.godot`, and click **Import & Edit**.
4. Press **F5** to play. Click inside the game if the mouse is not captured. Press **R** to restart the job or **Esc** to free the mouse.

The first import builds Godot's local cache. No plugins, account credentials, export templates, or asset downloads are required to play the source project.

## Controls and job

- WASD walks, mouse looks. E grabs the aimed frame or releases it.
- Q / T rotates a held frame 15 degrees left / right. Blocked rotations are rejected.
- Carry around the solid load toward the mint outline. Match position and orientation; the HUD says ALIGNED when F can place it. No jump or sprint.
- After placing, approach the mint brace on the right; B collects it. Aim at the wall and B installs it.
- Aim at each of the four pink squares and click three times with the hammer. The HUD counts 12 total strikes and confirms WALL SECURED.
- R resets the entire job from any state. Esc releases the cursor; click resumes.

The frame remains upright and uses one conservative solid collision envelope, including the visibly empty stud bays. Player and frame cannot pass through that envelope. This deliberate Phase 1 simplification prioritizes reliable carrying; it is not a dynamic ragdoll or structural simulation. Carry speed is capped at 4.5 m/s, player speed at 3.5 m/s; no carry forces accumulate. Overstretched carry releases; out-of-bounds items reset. The brace is a logical inventory item and installed visual, not a second physics carry object. The hammer is equipped from spawn.

## Verification

Run `./tests/run.sh` with the pinned `godot` on PATH. It imports/parses, then runs 45 assertions against real Jolt collision queries and the live scene: grab/release/rotate, obstructed carry, player collision, placement alignment, brace collection/installation, all 12 strikes, cooldown, completion and reset. The script positions actors for targeted fixtures; it is not a human walking playtest or a continuous input replay.

Rendered verification: a real X11/OpenGL Mesa llvmpipe run executed the same test and captured `evidence/assembled.png`, visually inspected. Audio used Dummy output; generated impact sound was not auditioned. Human feel, hardware performance, and prolonged adversarial collision testing remain untested.

For another rendered capture on a graphical desktop:
`godot --path . --script res://tests/smoke.gd -- --capture`

See `STATUS.md` for handoff and `NEXT.md` for Phase 2 priorities.

Additional rendered control smoke test: `godot --path . --script res://tests/controls.gd`. On the development X11/Mesa display, 24 assertions passed through `Input.parse_input_event`: WASD, mouse yaw/pitch, E grab/release, Q/T rotation, carried movement, F placement, B collect/install, mouse hammer clicks, Esc/click cursor release/capture, R reset and walking into the obstruction. Synthetic events exercise the real input handlers; actor placement fixtures isolate assembly steps. This is not an OS-device or human playtest. No game-code defect was found in this bounded check.
