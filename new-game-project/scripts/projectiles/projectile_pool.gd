class_name ProjectilePool
extends Node
## Simple pool: reuse freed projectiles by PackedScene key.

var _free_by_scene: Dictionary = {} # PackedScene -> Array[Node]
var _pending_releases: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func acquire(scene: PackedScene):
	if scene == null:
		return null
	var arr: Array = _free_by_scene.get(scene, [])
	if arr.is_empty():
		return null
	var node: Node = arr.pop_back() as Node
	if is_instance_valid(node):
		node.process_mode = Node.PROCESS_MODE_INHERIT
		node.visible = true
		if node is Area2D:
			var ar := node as Area2D
			ar.monitoring = true
			ar.monitorable = true
		return node
	return null


## Safe from area_entered / _physics_process: only appends — reparent runs later in _process (idle).
func queue_return(scene: PackedScene, node: Node) -> void:
	if scene == null or not is_instance_valid(node):
		return
	_pending_releases.append({&"scene": scene, &"node": node})


func _process(_delta: float) -> void:
	if Run.is_paused or _pending_releases.is_empty():
		return
	var item: Dictionary = _pending_releases.pop_front()
	var scene: PackedScene = item.get(&"scene") as PackedScene
	var node: Node = item.get(&"node") as Node
	if scene == null or not is_instance_valid(node):
		return
	_do_reparent_to_pool(scene, node)


func _do_reparent_to_pool(scene: PackedScene, node: Node) -> void:
	if node.get_parent():
		node.get_parent().remove_child(node)
	add_child(node)
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.visible = false
	if node is Area2D:
		var ar := node as Area2D
		ar.monitoring = false
		ar.monitorable = false
	var arr: Array = _free_by_scene.get(scene, [])
	arr.append(node)
	_free_by_scene[scene] = arr
