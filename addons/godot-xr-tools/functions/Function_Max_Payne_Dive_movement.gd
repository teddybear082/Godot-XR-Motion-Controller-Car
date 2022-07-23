tool
class_name Function_Max_Payne_Dive_movement
extends MovementProvider

##
## Movement Provider for Max Payne Style Diving Bullet Time Movement
##
## @desc:
##     This script provides "Max Payne Dive" movement aka player dives to the side in slow motion.  The user
##     can determine for how long it works and what button triggers the motion.
##


## Movement provider order
export var order := 45

## Length of bullet time effect
export var max_payne_time := 1.25

## Set ease in and out time
export var max_payne_ease := .25

## Set max payne dive speed (impacts how long it takes to get from beginning to end of dive motion)
export var max_payne_dive_speed = 2

## Set max payne dive lateral distance in units
export var max_payne_dive_distance = 5

## Set max payne dive height in units
export var max_payne_dive_height = 1.5

## Bullet time scale (percentage of engine speed)
export var max_payne_time_scale = .20

## Normal time scale
export var normal_time_scale = 1.0

## Determine if max payne dive is active or not
var is_max_payne_diving := false

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
export (Buttons) var max_payne_dive_button_id = Buttons.VR_BUTTON_BY

## Controller node
onready var _controller : ARVRController = get_parent()

## ARVR Camera node
onready var _arvrcamera = get_parent().get_parent().get_node("ARVRCamera")

## PlayerBody node
onready var _playerbody = get_parent().get_parent().get_node("PlayerBody")

## Variable to stop buttons from triggering action again when held by player
var button_states = []

## Variables to assist in leaping motion
var leap_target = null
var curr_transform = null
var solve_controller_direction = null
var leap_direction = null
## Tell other nodes when Bullettime is active or not
signal player_max_payne_dove
signal player_stopped_max_payne_diving


# Activate max payne dive
func physics_movement(delta: float, player_body: PlayerBody, is_active: bool):
	
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Toggle bullet time on button press
	if button_pressed(max_payne_dive_button_id):
		is_max_payne_diving = !is_max_payne_diving
		if is_max_payne_diving:
			#code for slowing down world, starting timer and tween, naturally end if no intervention
			emit_signal("player_max_payne_dove")
			_controller.set_rumble(.2) 
			yield(get_tree().create_timer(.1), "timeout") 
			_controller.set_rumble(0) 
			$MP_Sound.play()
			$MP_Tween.stop_all()
			
			
			#trigger start of player movement into dive
			
			#get current player position before movement started
			curr_transform = player_body.camera_node.global_transform
			
			
			#get controller direction for direction of dive
			
			#solve_controller_direction = player_body.camera_node.rotation.y - _controller.rotation.y 
			#The above was the first attempt to try to do this by comparing the camera's rotation to the controller
			
			#This version below instead uses that fact that the camera's global_transform.basis.x is a vector
			#pointing out the right side of the head at 90 degrees, the dot product then returns whether the angle
			#is less than 90 degrees, i.e., is positive, and thus facing right, is more than 90 degrees, i.e., negative
			#or 0 meaning the controllers are facing straight ahead. The -controller.global_transform.basis.z vector is the vector
			#coming out of the front of the controller into the world.
			
			solve_controller_direction = player_body.camera_node.global_transform.basis.x.dot(-_controller.global_transform.basis.z)
			
			
			#print("Performing dive and this is the dot product direction of the controller angle: " + str(solve_controller_direction))
			#print("The Camera's transform basis is: " + str(player_body.camera_node.transform.basis))
			#print("Controller's transform.basis is: " + str(_controller.transform.basis))
			#print("Camera transform basis x - controller transform basis x is: " + str(player_body.camera_node.transform.basis.x - _controller.transform.basis.x))
			#print("Camera transform basis z - controller transform basis z is: " + str(player_body.camera_node.transform.basis.z - _controller.transform.basis.z))
			#print("Camera transform basis x.x - controller transform basis x.x is: " + str(player_body.camera_node.transform.basis.x.x - _controller.transform.basis.x.x))
			#print("Camera transform basis z.z - controller transform basis z.z is: " + str(player_body.camera_node.transform.basis.z.z - _controller.transform.basis.z.z))
			#print("Camera transform basis x.z - controller transform basis x.z is: " + str(player_body.camera_node.transform.basis.x.z - _controller.transform.basis.x.z))
			#print("Camera transform basis z.x - controller transform basis z.x is: " + str(player_body.camera_node.transform.basis.z.x - _controller.transform.basis.z.x))#make into an actionable decision whether left (z is > .90, i.e., approx. 1), right (z is < -.90,i.e. approx. -1) or back (z is around zero)
			#print("Camera rotation degrees is: " + str(player_body.camera_node.rotation_degrees))
			#print("Camera rotation is: " + str(player_body.camera_node.rotation))
			#print("Controller rotation degrees is: " + str(_controller.rotation_degrees))
			#print("Controller rotation is:" + str(_controller.rotation))
			
			#make leap go backward if controller is roughly neutral
			
			#This was the first version based on controller and head rotation: if solve_controller_direction <.50 and solve_controller_direction > -.50:
			if solve_controller_direction > -.30 and solve_controller_direction < .30:
				leap_target = curr_transform.translated(Vector3(0, max_payne_dive_height * ARVRServer.world_scale, max_payne_dive_distance))
			
			
			
			#make leap go left if controller is angled left with respect to camera
			
			#This was the first version based on controller and head rotation: if solve_controller_direction <= -.50 or solve_controller_direction > 4.00:
			if solve_controller_direction < -0.30:
				leap_target = curr_transform.translated(Vector3(-max_payne_dive_distance * ARVRServer.world_scale, max_payne_dive_height * ARVRServer.world_scale, 0))
				
			#make leap go right if controller is angled right with respect to camera
			
			#This was the first version based on controller and head rotation: if solve_controller_direction >= .50 and solve_controller_direction < 4.00:
			if solve_controller_direction > .30:
				leap_target = curr_transform.translated(Vector3(max_payne_dive_distance * ARVRServer.world_scale, max_payne_dive_height * ARVRServer.world_scale, 0))
			
			
			#now move body toward chosen target
			player_body.velocity = player_body.move_and_slide(leap_target.origin - curr_transform.origin) * max_payne_dive_speed * ARVRServer.world_scale
			
			#slow time to max payne time while diving
			Engine.time_scale = max_payne_time_scale
			$MP_Tween.interpolate_property(Engine, "time_scale", Engine.time_scale, max_payne_time_scale, max_payne_ease, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			$MP_Tween.start()
			yield($MP_Tween, "tween_completed")
			yield(get_tree().create_timer(max_payne_time), "timeout")
			Engine.time_scale = normal_time_scale 
			is_max_payne_diving = false
			return true
		
		#stop diving movement if button is pressed again	
		if is_max_payne_diving == false:	
			emit_signal("player_stopped_max_payne_diving")
			$MP_Tween.stop_all()
			$MP_Tween.interpolate_property(Engine, "time_scale", Engine.time_scale, normal_time_scale, max_payne_ease, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			$MP_Tween.start()
			yield($MP_Tween, "tween_completed")
			$MP_Sound.play()
			_controller.set_rumble(.3) 
			yield(get_tree().create_timer(.1), "timeout") 
			_controller.set_rumble(0) 	


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
