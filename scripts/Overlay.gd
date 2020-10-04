extends CanvasLayer

signal tween_respawn_finish

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func crossfade():
	$Tween.interpolate_property($ColorRect, "color", Color(0, 0, 0, 0), Color.black, 0.3)
	$Tween.connect("tween_completed", self, "emit_tween_respawn_finish", [], Tween.CONNECT_ONESHOT)
	$Tween.start()

func emit_tween_respawn_finish(object, key):
	emit_signal("tween_respawn_finish")
	$Tween.interpolate_property($ColorRect, "color", Color.black, Color(0, 0, 0, 0), 0.3)
	$Tween.start()
	
