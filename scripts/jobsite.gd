extends Node3D

var frame: WallFrame
var player: SitePlayer
var hud: Label
var hint: Label
var guide: Node3D
var brace_pickup: MeshInstance3D
var has_brace := false
var message := "Bring the frame to the mint outline."
var cooldown := 0.0
var tone: AudioStreamPlayer

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("7596a5")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dbe7ef")
	settings.ambient_light_energy = 0.35
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	SiteGeometry.box(self, Vector3(24,0.3,22), Vector3(0,-0.16,0), Color("a5aaa7"), true)
	for x: float in [-12,12]:
		SiteGeometry.box(self, Vector3(0.3,2,22), Vector3(x,1,0), Color("687b82"), true)
	for z: float in [-11,11]:
		SiteGeometry.box(self, Vector3(24,2,0.3), Vector3(0,1,z), Color("687b82"), true)
	# A solid obstruction for carry collision trials.
	SiteGeometry.box(self, Vector3(1.7,1.2,1.6), Vector3(-0.8,0.6,0.4), Color("637985"), true)
	SiteGeometry.sign_text(self, "SOLID LOAD\nCarry around", Vector3(-0.8,1.5,1.22), 25)
	guide = Node3D.new()
	add_child(guide)
	guide.position = WallFrame.SOCKET
	for x: float in [-1.85,1.85]:
		SiteGeometry.box(guide, Vector3(0.055,2.9,0.055), Vector3(x,0,0), Color("63f0ce"))
	for y: float in [-1.38,1.45]:
		SiteGeometry.box(guide, Vector3(3.75,0.055,0.055), Vector3(0,y,0), Color("63f0ce"))
	SiteGeometry.sign_text(self, "01 / WALL A\nALIGN • BRACE • FASTEN", Vector3(1.8,3.6,-3), 38)
	brace_pickup = SiteGeometry.box(self, Vector3(0.2,0.16,2), Vector3(5,0.18,0), Color("35bea7"))
	SiteGeometry.sign_text(self, "BRACE\n[B] collect nearby", Vector3(5,0.9,0), 27)
	frame = WallFrame.new()
	add_child(frame)
	player = SitePlayer.new()
	add_child(player)
	player.position = Vector3(-3.5,0.03,4.1)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.color = Color(0.04,0.08,0.1,0.88)
	panel.position = Vector2(20,20)
	panel.size = Vector2(640,124)
	canvas.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(38,30)
	hud.add_theme_font_size_override("font_size", 20)
	canvas.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(28,590)
	hint.add_theme_font_size_override("font_size", 19)
	hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint.add_theme_constant_override("shadow_outline_size", 5)
	canvas.add_child(hint)
	var cross := Label.new()
	cross.text = "+"
	cross.position = Vector2(632,343)
	cross.add_theme_font_size_override("font_size", 24)
	canvas.add_child(cross)
	tone = AudioStreamPlayer.new()
	add_child(tone)
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(4400)
	for i: int in range(2200):
		var sample := int(sin(float(i) * 0.11) * exp(-float(i) / 340.0) * 16000)
		data.encode_s16(i * 2, sample)
	sound.data = data
	tone.stream = sound
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Local authority boundary. Phase 2 must validate sender ownership and range here.
# There is no transport, RPC, or multiplayer claim in this prototype.
func command(action: StringName, argument: int = -1) -> bool:
	var hit := player.ray_target()
	var aimed: bool = hit.get("collider") == frame
	match action:
		&"grab":
			if frame.state == WallFrame.State.HELD:
				frame.state = WallFrame.State.FREE
				return true
			if aimed and frame.state == WallFrame.State.FREE:
				frame.state = WallFrame.State.HELD
				return true
		&"place":
			return frame.place()
		&"brace":
			if frame.state == WallFrame.State.HELD:
				return false
			if not has_brace and brace_pickup.visible and player.position.distance_to(brace_pickup.position) < 2.4:
				has_brace = true
				brace_pickup.hide()
				return true
			if has_brace and aimed and frame.install_brace():
				has_brace = false
				return true
		&"hit":
			if not aimed or cooldown > 0:
				return false
			var local_hit: Vector3 = frame.to_local(hit.position)
			var index := -1
			for i: int in range(4):
				if local_hit.distance_to(frame.nails[i].position) < 0.4:
					index = i
			if index >= 0 and frame.fasten(index):
				cooldown = 0.23
				player.impact()
				tone.pitch_scale = 0.9 + float(frame.hits[index]) * 0.12
				tone.play()
				return true
		&"rotate":
			return frame.state == WallFrame.State.HELD and frame.rotate_safe(deg_to_rad(15 * argument))
		&"reset":
			player.position = Vector3(-3.5,0.03,4.1)
			player.rotation = Vector3.ZERO
			player.camera.rotation = Vector3.ZERO
			player.velocity = Vector3.ZERO
			frame.reset_frame()
			brace_pickup.show()
			has_brace = false
			cooldown = 0
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		if event.keycode == KEY_R:
			command(&"reset")
			return
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		match event.physical_keycode:
			KEY_E: command(&"grab")
			KEY_F: command(&"place")
			KEY_B: command(&"brace")
			KEY_Q: command(&"rotate", -1)
			KEY_T: command(&"rotate", 1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			command(&"hit")

func _physics_process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	if frame.state == WallFrame.State.HELD:
		var target := player.position - player.basis.z * 2.65
		target.y = 1.42
		frame.carry_toward(target, delta)
		if player.position.distance_to(frame.position) > 5:
			frame.state = WallFrame.State.FREE
	if player.position.y < -6:
		command(&"reset")
	var names: Array[String] = ["FREE", "HELD", "PLACED", "BRACED", "FASTENED"]
	var total := 0
	for count: int in frame.hits:
		total += count
	hud.text = "BARELY UP TO CODE   /   MECHANICS GRAYBOX\nWALL A  •  %s     /     FASTENERS %d / 12\n%s" % [names[frame.state], total, objective()]
	hint.text = "WASD walk  •  Mouse look  •  E grab / release  •  Q / T rotate\nF place in outline  •  B collect / install brace  •  Click hammer pink targets\nR reset job  •  Esc release cursor  •  Click resume"
	guide.visible = frame.state < WallFrame.State.PLACED

func objective() -> String:
	match frame.state:
		WallFrame.State.FREE: return "Aim at timber + E. Bring frame to the mint outline."
		WallFrame.State.HELD:
			if frame.can_place(): return "ALIGNED — press F to place."
			if frame.blocked: return "OBSTRUCTED — walk around the load."
			return "Carry to outline. Q / T turns 15°. Match its orientation."
		WallFrame.State.PLACED:
			return "Aim at wall + B to brace." if has_brace else "Collect the mint brace to your right with B."
		WallFrame.State.BRACED: return "Aim at each pink square. Three hammer clicks per fastener."
		WallFrame.State.FASTENED: return "WALL SECURED!   R resets the job for another run."
	return ""
