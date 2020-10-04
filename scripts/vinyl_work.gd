extends Spatial

export (PackedScene) var half_block_prefab: PackedScene
export (PackedScene) var tall_block_prefab: PackedScene
export (PackedScene) var block_prefab: PackedScene
export (PackedScene) var door_prefab: PackedScene
export (PackedScene) var hell_prefab: PackedScene

export (Curve) var spawn_rate: Curve
export (Curve) var half_block_spawn_rate: Curve
export (Curve) var block_spawn_rate: Curve
export (Curve) var tall_block_spawn_rate: Curve
export (Curve) var door_spawn_rate: Curve
export (Curve) var hell_spawn_rate: Curve

export (float) var difficulty_duration := 120.0

var rng = RandomNumberGenerator.new()

var time_elapsed = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_parent().started:
		$Vinyl.rotate(Vector3.UP, Global.vinyl_rotation_speed * delta)
		time_elapsed += delta

func _on_SpawnTimer_timeout():
	var difficulty = min(1, time_elapsed / difficulty_duration)
	#shall we spawn?
	if rng.randf() < spawn_rate.interpolate_baked(difficulty):
		# choose the block
		var the_prefab: PackedScene
		var last_rate_comp: float = 0
		var half_block_rand = rng.randf() * half_block_spawn_rate.interpolate(difficulty)
		var block_rand = rng.randf() * block_spawn_rate.interpolate(difficulty)
		var tall_block_rand = rng.randf() * tall_block_spawn_rate.interpolate(difficulty)
		var door_rand = rng.randf() * door_spawn_rate.interpolate(difficulty)
		var hell_rand = rng.randf() * hell_spawn_rate.interpolate(difficulty)
		
		if half_block_rand > last_rate_comp:
			the_prefab = half_block_prefab
			last_rate_comp = half_block_rand
		if block_rand > last_rate_comp:
			the_prefab = block_prefab
			last_rate_comp = block_rand
		if tall_block_rand > last_rate_comp:
			the_prefab = tall_block_prefab
			last_rate_comp = tall_block_rand
		if door_rand > last_rate_comp:
			the_prefab = door_prefab
			last_rate_comp = door_rand
		if hell_rand > last_rate_comp:
			the_prefab = hell_prefab
			last_rate_comp = hell_rand
		
		#print("%f %f %f %f %f - %f" % [half_block_rand, block_rand, tall_block_rand, door_rand, hell_rand, last_rate_comp])
		
		var new_block: Spatial = the_prefab.instance()
		$SpawnPath/PathFollow.unit_offset = randf()
		$Vinyl.add_child(new_block)
		new_block.global_transform = $SpawnPath/PathFollow.global_transform
		var center_leveled = global_transform.origin
		center_leveled.y = new_block.global_transform.origin.y
		new_block.look_at(center_leveled, Vector3.UP)
		if the_prefab == hell_prefab:
			var the_player = get_parent().find_node("Player")
			new_block.find_node("Area").connect("body_entered", the_player, "get_hit_hell")

func _on_DespawnArea_body_shape_entered(_body_id, body, _body_shape, _area_shape):
	if not body is Player:
		body.queue_free()
