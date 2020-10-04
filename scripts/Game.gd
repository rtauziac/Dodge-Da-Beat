extends Spatial

var started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred("respawn", false)
	$CanvasLayer.connect("tween_respawn_finish", self, "on_tween_respawn_finished")
	
	$Vinyl/AreaHitCenter.connect("body_entered", $Player, "get_hit")
	$Vinyl/AreaHitCenter.connect("body_exited", $Player, "leave_hit")
	$Vinyl/DespawnArea.connect("body_entered", $Player, "get_hit")
	$Vinyl/DespawnArea.connect("body_exited", $Player, "leave_hit")
	
	$Player.connect("remove_heart", self, "remove_heart")
	$Player.connect("end_game", self, "show_end_game_screen")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func respawn(hurt = true):
	$Player.global_transform.origin = $SpawnPosition.global_transform.origin
	if hurt:
		$Player._on_TimerHit_timeout()

func _on_OutOfBoundsArea_body_entered(body):
	if body is Player:
		$CanvasLayer.crossfade()

func on_tween_respawn_finished():
	respawn()

func remove_heart():
	if $CanvasLayer/HBoxContainer/HeartBoxContainer.get_child_count() > 0:
		$CanvasLayer/HBoxContainer/HeartBoxContainer.get_child(0).queue_free()

func show_end_game_screen():
	var elapsed_time = $Vinyl.time_elapsed
	$CanvasLayer/CenterContainer/Label.text = "You survived %d beats" % floor(elapsed_time * 2)

func new_game():
	get_tree().reload_current_scene()


func _on_TimerStart_timeout():
	$Vinyl/AudioStreamPlayer3D.play()
	started = true
	$Vinyl/SpawnTimer.start()
