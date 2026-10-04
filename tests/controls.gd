extends SceneTree
# Rendered input-pipeline smoke test. Synthetic OS-style events, not a human playtest.
# Actor placement fixtures isolate individual bindings without a long navigation bot.
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL", label])

func key(code: Key, held: float = 0.05) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(held).timeout
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	Input.parse_input_event(event)
	await process_frame

func click() -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(event)
	await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var site: Node3D = load("res://scenes/jobsite.tscn").instantiate()
	root.add_child(site)
	await create_timer(0.3).timeout
	var player: SitePlayer = site.player
	var frame: WallFrame = site.frame
	var start := player.position
	await key(KEY_W, 0.25)
	check(player.position.z < start.z - 0.3, "W moves forward")
	start = player.position
	player.velocity = Vector3.ZERO
	await key(KEY_S, 0.25)
	check(player.position.z > start.z + 0.3, "S moves backward")
	start = player.position
	await key(KEY_A, 0.25)
	check(player.position.x < start.x - 0.3, "A moves left")
	start = player.position
	player.velocity = Vector3.ZERO
	await key(KEY_D, 0.25)
	check(player.position.x > start.x + 0.3, "D moves right")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 40)
	Input.parse_input_event(motion)
	await process_frame
	check(player.rotation.y < -0.1 and player.camera.rotation.x < -0.04, "mouse changes yaw and pitch")
	await key(KEY_R)
	check(player.position.distance_to(Vector3(-3.5,0.03,4.1)) < 0.1 and player.rotation.is_zero_approx(), "R resets position and look")
	await key(KEY_E)
	await create_timer(0.2).timeout
	check(frame.state == WallFrame.State.HELD, "E grabs aimed frame")
	await key(KEY_Q)
	check(frame.rotation.y < -0.2, "Q rotates left")
	await key(KEY_T)
	check(absf(frame.rotation.y) < 0.01, "T rotates right")
	await key(KEY_E)
	check(frame.state == WallFrame.State.FREE, "E releases frame")
	await key(KEY_E)
	check(frame.state == WallFrame.State.HELD, "E regrabs frame")
	# Hold W into frame: the carry sweep advances it while player stays separated.
	start = frame.position
	await key(KEY_W, 0.25)
	check(frame.position.z < start.z - 0.2, "walking advances carried frame")
	# Position a near-socket fixture; do not call construction commands directly.
	player.position = Vector3(1.8,0.03,-0.35)
	player.velocity = Vector3.ZERO
	frame.position = WallFrame.SOCKET
	await create_timer(0.12).timeout
	await key(KEY_F)
	check(frame.state == WallFrame.State.PLACED, "F places aligned frame")
	player.position = Vector3(5,0.03,1)
	await key(KEY_B)
	check(site.has_brace, "B collects nearby brace")
	player.position = Vector3(1.8,0.03,-0.35)
	player.camera.look_at(frame.global_position)
	await key(KEY_B)
	check(frame.state == WallFrame.State.BRACED, "B installs brace at aimed wall")
	for i: int in range(4):
		player.position = Vector3(frame.nails[i].global_position.x,0.03,-0.35)
		player.camera.look_at(frame.nails[i].global_position)
		await create_timer(0.1).timeout
		for strike: int in range(3):
			await click()
			await create_timer(0.27).timeout
		check(frame.hits[i] == 3, "mouse clicks fasten target %d" % [i + 1])
	check(frame.state == WallFrame.State.FASTENED, "input sequence completes wall")
	await key(KEY_ESCAPE)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Esc frees cursor")
	await click()
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "click recaptures cursor")
	await key(KEY_R)
	check(frame.state == WallFrame.State.FREE and frame.hits == [0,0,0,0] and site.brace_pickup.visible, "R resets completed job")
	# Real held movement into the obstruction from a fixture starting outside it.
	player.position = Vector3(-0.8,0.03,2.5)
	player.camera.rotation = Vector3.ZERO
	await key(KEY_W, 0.8)
	check(player.position.z > 1.45, "W cannot walk through solid load")
	print("CONTROLS RESULT: %d checks, %d failures" % [checks, failures])
	site.queue_free()
	await process_frame
	quit(1 if failures else 0)
