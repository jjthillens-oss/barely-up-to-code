class_name SiteGeometry
extends RefCounted

static func box(parent: Node3D, size: Vector3, at: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material_override = material
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		parent.add_child(body)
		body.position = at
		collider(body, size)
	return mesh

static func collider(parent: CollisionObject3D, size: Vector3) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	parent.add_child(collision)
	return collision

static func sign_text(parent: Node3D, text: String, at: Vector3, size: int = 40) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = size
	label.outline_size = 5
	label.modulate = Color("fff4ce")
	parent.add_child(label)
	return label
