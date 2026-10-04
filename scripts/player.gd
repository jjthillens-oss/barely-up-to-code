class_name SitePlayer
extends CharacterBody3D

var camera: Camera3D
var hammer: Node3D
var recoil := 0.0
var swing := 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 78
	add_child(camera)
	hammer = Node3D.new()
	camera.add_child(hammer)
	hammer.position = Vector3(0.48, -0.38, -0.75)
	SiteGeometry.box(hammer, Vector3(0.055, 0.47, 0.065), Vector3.ZERO, Color("ffcf64"))
	SiteGeometry.box(hammer, Vector3(0.26, 0.14, 0.14), Vector3(0,0.23,0), Color("354f60"))

	# Default scruffy worker blockout only; long forearm, no customization.
	SiteGeometry.box(hammer, Vector3(0.13,0.17,0.16), Vector3(0,-0.12,0.025), Color("bea786"))
	var sleeve := SiteGeometry.box(hammer, Vector3(0.14,0.16,0.62), Vector3(0.04,-0.24,0.32), Color("7a8068"))
	sleeve.rotation.x = -0.25

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0024)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * 0.0024, -1.3, 1.3)

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var direction := basis * Vector3(input.x, 0, input.y)
	velocity.x = move_toward(velocity.x, direction.x * 3.5, 20 * delta)
	velocity.z = move_toward(velocity.z, direction.z * 3.5, 20 * delta)
	velocity.y = maxf(velocity.y - 18 * delta, -20)
	move_and_slide()
	recoil = move_toward(recoil, 0, delta * 0.08)
	swing = move_toward(swing, 0, delta * 6)
	camera.position.z = recoil
	hammer.rotation.x = -swing

func ray_target(reach: float = 3.8) -> Dictionary:
	var start := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * reach, 1 | 2)
	return get_world_3d().direct_space_state.intersect_ray(query)

func impact() -> void:
	recoil = 0.025
	swing = 0.9
