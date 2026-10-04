class_name WallFrame
extends CharacterBody3D

enum State { FREE, HELD, PLACED, BRACED, FASTENED }
const SIZE := Vector3(3.6, 2.8, 0.24)
const SPAWN := Vector3(-3.5, 1.42, 1.0)
const SOCKET := Vector3(1.8, 1.42, -3.0)
var state: State = State.FREE
var hits: Array[int] = [0, 0, 0, 0]
var shape: CollisionShape3D
var nails: Array[MeshInstance3D] = []
var brace: MeshInstance3D
var blocked := false

func _ready() -> void:
	safe_margin = 0.008
	collision_layer = 2
	collision_mask = 1 | 4
	shape = SiteGeometry.collider(self, SIZE)
	var wood := Color("f7b455")
	for x: float in [-1.7, -0.57, 0.57, 1.7]:
		SiteGeometry.box(self, Vector3(0.16, 2.8, 0.24), Vector3(x, 0, 0), wood)
	for y: float in [-1.32, 1.32]:
		SiteGeometry.box(self, Vector3(3.6, 0.16, 0.24), Vector3(0, y, 0), wood)
	for p: Vector3 in [Vector3(-1.7,-0.9,0.2), Vector3(1.7,-0.9,0.2), Vector3(-1.7,0.8,0.2), Vector3(1.7,0.8,0.2)]:
		nails.append(SiteGeometry.box(self, Vector3(0.17,0.17,0.12), p, Color("f65879")))
	brace = SiteGeometry.box(self, Vector3(0.17, 2.65, 0.18), Vector3(0, -0.3, 0), Color("35bea7"))
	brace.rotation.z = -0.95
	reset_frame()

func reset_frame() -> void:
	state = State.FREE
	position = SPAWN
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	hits = [0, 0, 0, 0]
	brace.visible = false
	for nail: MeshInstance3D in nails:
		nail.scale = Vector3.ONE

func clear_at(candidate: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	query.transform = candidate
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.002
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func rotate_safe(angle: float) -> bool:
	var original := transform
	# Small angular increments prevent clipping through thin barriers mid-turn.
	for step: int in range(1, 13):
		var candidate := original
		candidate.basis = Basis(Vector3.UP, angle * float(step) / 12.0) * original.basis
		if not clear_at(candidate):
			return false
	rotate_y(angle)
	return true

func carry_toward(target: Vector3, delta: float) -> void:
	var motion := (target - global_position).limit_length(4.5 * delta)
	blocked = move_and_collide(motion, false, 0.01) != null
	velocity = Vector3.ZERO

func can_place() -> bool:
	if state != State.HELD or position.distance_to(SOCKET) > 0.7:
		return false
	if absf(wrapf(rotation.y, -PI, PI)) > deg_to_rad(15):
		return false
	var target := Transform3D(Basis.IDENTITY, SOCKET)
	return clear_at(target) and not test_move(transform, SOCKET - position)

func place() -> bool:
	if not can_place():
		return false
	transform = Transform3D(Basis.IDENTITY, SOCKET)
	state = State.PLACED
	return true

func install_brace() -> bool:
	if state != State.PLACED:
		return false
	state = State.BRACED
	brace.visible = true
	return true

func fasten(index: int) -> bool:
	if state != State.BRACED or index < 0 or index >= 4 or hits[index] >= 3:
		return false
	hits[index] += 1
	nails[index].scale.z = 1.0 - float(hits[index]) * 0.22
	if hits.all(func(count: int) -> bool: return count == 3):
		state = State.FASTENED
	return true

func _physics_process(delta: float) -> void:
	if state == State.FREE:
		velocity.y = maxf(velocity.y - 18.0 * delta, -12.0)
		move_and_slide()
	if position.y < -8 or position.length() > 40:
		reset_frame()
