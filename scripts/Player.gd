extends KinematicBody

class_name Player

signal remove_heart
signal end_game

var hearts = 3

export (float) var speed = 6.0
export (float) var jump_force = 2.0 
export (Curve) var dead_zone: Curve
export (float) var move_factor := 0.2
export (float) var move_factor_air := 0.06
export (float) var jump_buffer_amount := 0.4
export (float) var slide_duration := 0.6

export (Curve) var blend_anim_curve: Curve

export (float) var gravity := 9.8

var camera: Camera
var prev_mov := Vector3.ZERO # store the userinitiated movement from the previous frame
var velocity := Vector3.ZERO
#var air_velocity := Vector3.ZERO # the additional velocity when jumping
#var prev_pos := Vector3.ZERO # store the spatial position from the previous frame

onready var skater_spatial = $skater
onready var anim_tree = $skater/AnimationTree
var anim_state_machine: AnimationNodeStateMachinePlayback

var jump_buffer: float # used to control jump height
var prev_slide_buffer: float
var slide_buffer: float
var was_on_floor: bool

var hurt: bool #used to prevent player movement
var hurt_area_inside_count := 0 #used to store the fact that the player is on a hurt object `0` means false
export (float) var invincibility_time := 3
var invincibility: float

# Called when the node enters the scene tree for the first time.
func _ready():
	reset_variables()
	camera =  get_parent().get_node("Camera").get_node("Camera")
	dead_zone.bake_resolution = 512
	dead_zone.bake()
#	prev_pos = global_transform.origin
	anim_state_machine = anim_tree["parameters/playback"]
	blend_anim_curve.bake()
	
	anim_state_machine.travel("idle_run")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# movement
	var joy_dir := Vector2.ZERO
	if not hurt:
		if Input.is_key_pressed(KEY_W):
			joy_dir.y -= 1
		if Input.is_key_pressed(KEY_S):
			joy_dir.y += 1
		if Input.is_key_pressed(KEY_A):
			joy_dir.x -= 1
		if Input.is_key_pressed(KEY_D):
			joy_dir.x += 1
		joy_dir += Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1))
		if joy_dir.length() > 1:
			joy_dir = joy_dir.normalized()
		
	var cam_dir = camera.global_transform.basis
	var forward = cam_dir.z
	forward.y = 0
	forward = forward.normalized()
	var right = cam_dir.x
	
	var dz = dead_zone.interpolate_baked(joy_dir.length())
	var movement = (forward * joy_dir.y * speed + right * joy_dir.x * speed) * delta * dz
	prev_mov = lerp(prev_mov, movement, move_factor if is_on_floor() else move_factor_air)
	var new_vel := prev_mov
	
	var vel_for_dir := new_vel
	vel_for_dir.y = 0
	var has_speed = false
	if vel_for_dir.length() > 0.05:
		skater_spatial.look_at(skater_spatial.global_transform.origin + vel_for_dir, Vector3.UP)
		has_speed = true
	elif get_parent().started:
		skater_spatial.rotate(Vector3.UP, Global.vinyl_rotation_speed * delta)
	#print(vel_for_dir.length() / max(0.001, delta) / speed)
	anim_tree.set("parameters/idle_run/blend/blend_amount", blend_anim_curve.interpolate_baked(vel_for_dir.length() / max(0.001, delta) / speed))
	if is_on_floor():
		new_vel.y = 0
		if not hurt and Input.is_action_just_pressed("jump"):
			new_vel.y = jump_force
#			prev_mov = Vector3.ZERO
			jump_buffer = jump_buffer_amount
			anim_state_machine.travel("jump")
			$JumpAudioPlayer.play(0)
			
			#air_velocity = (global_transform.origin - prev_pos) / delta
			
		if not hurt and has_speed and Input.is_action_just_pressed("slide"):
			slide_buffer = slide_duration
			
		if was_on_floor == false and not hurt:
			anim_state_machine.travel("land")
			$LandingAudioPlayer.play(0)
		was_on_floor = true
	else:
		new_vel.y = velocity.y - gravity * delta
		jump_buffer = max(0, jump_buffer - delta)
		if Input.is_action_pressed("jump") and jump_buffer > 0:
			new_vel.y = velocity.y + jump_buffer
		else:
			jump_buffer = 0
#		new_vel += air_velocity
		was_on_floor = false
		
	velocity = new_vel
	
	if slide_buffer > 0:
		slide_buffer = max(0, slide_buffer - delta)
		if not (Input.is_action_pressed("slide") and slide_buffer > 0):
			slide_buffer = 0
	
	if slide_buffer > 0 and prev_slide_buffer == 0: #slides
		anim_state_machine.travel("slide")
		$CollisionShapeStanding.set_deferred("disabled", true)
		$CollisionShapeSliding.set_deferred("disabled", false)
		$CollisionShapeStanding.visible = false
		$CollisionShapeSliding.visible = true
		$SlideAudioPlayer.play(0)
	elif slide_buffer == 0 and prev_slide_buffer > 0: #end sliding
		anim_state_machine.travel("idle_run")
		$CollisionShapeStanding.set_deferred("disabled", false)
		$CollisionShapeSliding.set_deferred("disabled", true)
		$CollisionShapeStanding.visible = true
		$CollisionShapeSliding.visible = false
		$SlideAudioPlayer.stop()
	
#	prev_pos = Vector3(global_transform.origin.x, global_transform.origin.y, global_transform.origin.z)
	prev_slide_buffer = slide_buffer
	
	invincibility = max(0, invincibility - delta)
	
	if invincibility == 0 and not hurt and hurt_area_inside_count > 0:
		apply_hurt()
	
	$skater.visible = fmod(invincibility, 0.3) < 0.15
	
	if jump_buffer > 0:
		move_and_slide_with_snap(velocity, Vector3.ZERO, Vector3.UP)
	else:
		move_and_slide_with_snap(velocity, Vector3.DOWN * 0.25, Vector3.UP)

func reset_variables():
	jump_buffer = 1 # used to control jump height
	prev_slide_buffer = 0.0
	slide_buffer = 0.0
	was_on_floor = false
	hurt = false
	invincibility = 0.0

func get_hit(body: Node):
	if body == self:
		hurt_area_inside_count += 1

func get_hit_hell(body: Node):
	if body == self:
		apply_hurt()

func leave_hit(body: Node):
	if body == self:
		hurt_area_inside_count -= 1

func apply_hurt():
	anim_state_machine.travel("hit")
	$HurtAudioPlayer.play(0)
	hurt = true
	$TimerHit.start()

func _on_TimerHit_timeout():
	hearts -= 1
	emit_signal("remove_heart")
	if hearts > 0:
		hurt = false
		anim_state_machine.travel("idle_run")
		invincibility = invincibility_time
	else:
		set_process(false)
		skater_spatial.visible = false
		emit_signal("end_game")
