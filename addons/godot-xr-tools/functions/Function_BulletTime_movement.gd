tool
class_name Function_BulletTime_movement
extends MovementProvider

##
## Movement Provider for Bullet Time (Slow-Mo)
##
## @desc:
##     This script provides "bullet time" aka Matrix, SuperHot movement to the player.  The user
##     can determine for how long it works and what button triggers the motion.
##


## Movement provider order
export var order := 35

## Length of bullet time effect
export var slo_mo_time := 1.5

## Set ease in and out time
export var slo_mo_ease := .25

## Bullet time scale (percentage of engine speed)
export var bullet_time_scale := .20

## Normal time sclae
export var normal_time_scale = 1.0

## Determine if slo-mo is active or not
var is_bullet_time := false

## enum our buttons, should find a way to put this more central
enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}

## Bullet time activate button
export (Buttons) var bullet_time_button_id = Buttons.VR_BUTTON_BY

## Controller node
onready var _controller : ARVRController = get_parent()

## Variable to stop buttons from triggering action again when held by player
var button_states = []

## Tell other nodes when Bullettime is active or not
signal bullet_time_active
signal bullet_time_off


# Activate bullet time
func physics_movement(_delta: float, _player_body: PlayerBody, _disabled: bool):
	
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Toggle bullet time on button press
	if button_pressed(bullet_time_button_id):
		is_bullet_time = !is_bullet_time
		if is_bullet_time:
			#code for slowing down world, starting timer and tween, naturally end if no intervention
			emit_signal("bullet_time_active")
			$SloMo_Sound.play()
			$SloMo_Tween.stop_all()
			$SloMo_Tween.interpolate_property(Engine, "time_scale", Engine.time_scale, bullet_time_scale, slo_mo_ease, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			$SloMo_Tween.start()
			yield($SloMo_Tween, "tween_completed")
			yield(get_tree().create_timer(slo_mo_time), "timeout")
			is_bullet_time = false
			
		if is_bullet_time == false:	
			emit_signal("bullet_time_off")
			$SloMo_Tween.stop_all()
			$SloMo_Tween.interpolate_property(Engine, "time_scale", Engine.time_scale, normal_time_scale, slo_mo_ease, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			$SloMo_Tween.start()
			yield($SloMo_Tween, "tween_completed")
#			$SloMo_Sound.play()	
	


func button_pressed(b):
	if _controller.is_button_pressed(b) and !button_states.has(b):
		button_states.append(b)
		return true
	if not _controller.is_button_pressed(b) and button_states.has(b):
		button_states.erase(b)
	
	return false
# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is ARVRController:
		return "Unable to find ARVR Controller node"

	# Call base class
	return ._get_configuration_warning()
