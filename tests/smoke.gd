extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL", description])

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var site: Node3D = load("res://scenes/jobsite.tscn").instantiate()
	root.add_child(site)
	await physics_frame
	await physics_frame
	var frame: WallFrame = site.frame
	var player: SitePlayer = site.player
	player.set_physics_process(false)
	check(frame.state == WallFrame.State.FREE, "initial FREE")
	check(not site.command(&"hit"), "cannot fasten before brace")
	check(site.command(&"grab"), "ray-target grab")
	check(not site.command(&"place"), "reject distant placement")
	check(site.command(&"rotate", 1), "clear rotation")
	check(site.command(&"rotate", -1), "reverse rotation")
	check(site.command(&"grab"), "release")
	# Move through the solid load using the same swept carry implementation.
	frame.position = Vector3(-4, 1.42, 0.4)
	frame.state = WallFrame.State.HELD
	site.set_physics_process(false)
	await physics_frame
	for i: int in range(100):
		frame.carry_toward(Vector3(0,1.42,0.4), 1.0 / 60.0)
	check(frame.position.x < -3.4 and frame.blocked, "carry stops at solid load; no tunneling")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = frame.shape.shape
	query.transform = frame.transform
	query.collision_mask = frame.collision_mask
	query.exclude = [frame.get_rid()]
	check(frame.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "carry ends without geometric overlap")
	# Player's shape must also stop at the frame's conservative full envelope.
	player.position = Vector3(-4,0.03,3)
	await physics_frame
	var collision := player.move_and_collide(Vector3(0,0,-4))
	check(collision != null and player.position.z > 0.8, "player cannot walk through carried frame")
	frame.position = Vector3(1.8,1.42,-2.65)
	frame.rotation.y = deg_to_rad(30)
	player.position = Vector3(1.8,0.03,0)
	await physics_frame
	check(not site.command(&"place"), "reject misaligned placement")
	frame.rotation.y = 0
	await physics_frame
	check(site.command(&"place"), "aligned placement")
	check(frame.position.is_equal_approx(WallFrame.SOCKET), "exact socket transform")
	check(not site.command(&"brace"), "brace required in inventory")
	player.position = Vector3(5,0.03,1)
	await physics_frame
	check(site.command(&"brace"), "collect brace nearby")
	player.position = Vector3(1.8,0.03,-0.3)
	player.camera.look_at(frame.global_position)
	await physics_frame
	check(site.command(&"brace"), "install brace through command and ray")
	check(not site.command(&"grab"), "secured wall cannot be grabbed")
	for i: int in range(4):
		player.position = Vector3(frame.nails[i].global_position.x,0.03,-0.3)
		player.camera.look_at(frame.nails[i].global_position)
		await physics_frame
		for n: int in range(3):
			site.cooldown = 0
			check(site.command(&"hit"), "fastener %d strike %d" % [i + 1,n + 1])
			check(not site.command(&"hit"), "cooldown prevents repeated impulse")
	check(frame.state == WallFrame.State.FASTENED, "complete wall FASTENED")
	if "--capture" in OS.get_cmdline_user_args():
		player.position = Vector3(6,0.03,5)
		player.camera.look_at(Vector3(0,1.4,-1))
		site.set_physics_process(true)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://evidence/assembled.png")
		site.set_physics_process(false)
	check(not frame.fasten(0), "completed fastener rejects extra strike")
	check(site.command(&"reset"), "reset command")
	check(frame.state == WallFrame.State.FREE and frame.hits == [0,0,0,0] and site.brace_pickup.visible and not site.has_brace, "reset restores full job")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	site.queue_free()
	await process_frame
	quit(1 if failures else 0)
