extends Spatial

export (float) var cam_speed = 2.0
export (float) var follow_range_min := 6.0
export (float) var follow_range_max := 12.0
export (float) var follow_range_bottom := 0.4
export (float) var follow_range_top := 2.0
export (float) var player_weight := 2.0

var player: Player
var camera: Camera
var lerp_player_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	player = get_parent().get_node("Player")
	camera = get_node("Camera")
	lerp_player_pos = player.global_transform.origin
	call_deferred("set_process", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# follow the player
	var vec_dif = global_transform.origin - player.global_transform.origin
	var player_dist = vec_dif.length()
	
	if player_dist < follow_range_min:
#		translate(vec_dif * abs(player_dist - follow_range_min) * cam_speed * delta)
		global_transform.origin = player.global_transform.origin + vec_dif.normalized() * follow_range_min
	if player_dist > follow_range_max:
#		translate(-vec_dif * abs(player_dist - follow_range_max) * cam_speed * delta)
		global_transform.origin = player.global_transform.origin + vec_dif.normalized() * follow_range_max

	# compensate height
	var height_dif = global_transform.origin.y - player.global_transform.origin.y
	if height_dif < follow_range_bottom:
		translate(Vector3.UP * abs(height_dif - follow_range_bottom) * cam_speed * delta)

	if height_dif > follow_range_top:
		translate(Vector3.DOWN * abs(height_dif - follow_range_top) * cam_speed * delta)
	
	#apply force in the direction of the vinyl
	$rotation_watcher.look_at(Vector3.ZERO, Vector3.UP)
	translate((-$rotation_watcher.global_transform.basis.z - $rotation_watcher.global_transform.basis.x) * cam_speed * delta / 2)
	
	# look at the player
	lerp_player_pos = lerp(lerp_player_pos, player.global_transform.origin, player_weight)
	camera.look_at(lerp_player_pos, Vector3.UP)
