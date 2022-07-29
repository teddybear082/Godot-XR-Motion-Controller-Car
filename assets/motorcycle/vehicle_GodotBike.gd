extends VehicleBody


############################################################
# Steering

export var MAX_STEER_ANGLE = 20
export var SPEED_STEER_ANGLE = 10
export var MAX_STEER_SPEED = 120.0
export var MAX_STEER_INPUT = 90.0
export var STEER_SPEED = 1.0
export var LEAN_SPEED = 3.0

onready var max_steer_angle_rad = deg2rad(MAX_STEER_ANGLE)
onready var speed_steer_angle_rad = deg2rad(SPEED_STEER_ANGLE)
onready var max_steer_input_rad = deg2rad(MAX_STEER_INPUT)
export (Curve) var steer_curve = null

var steer_target = 0.0
var steer_angle = 0.0

var player_is_seated = false
var was_gear_up = false
var was_gear_down = false
var grounded = true
var steer_lean = false
var lean_val = 0
signal bike_entered(bike_node)
signal bike_exited(bike_node)

var _shift_up_controller: ARVRController
var _shift_down_controller: ARVRController
var _gas_controller: ARVRController
var _brake_controller: ARVRController

# shift button state
var _shift_up_button: bool = false
var _shift_down_button: bool = false

# Gas and brake button state
var _gas_button: bool = false
var _brake_button: bool = false

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

## enum motorcycle controllers
enum Shift_Up_Controller {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}

enum Shift_Down_Controller {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}


enum Gas_Controller {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}


enum Brake_Controller {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}

## Car shifting gears buttons assignment
export (Buttons) var shift_up_button_id = Buttons.VR_BUTTON_AX
export (Buttons) var shift_down_button_id = Buttons.VR_BUTTON_AX
export (Buttons) var gas_button_id = Buttons.VR_TRIGGER
export (Buttons) var brake_button_id = Buttons.VR_TRIGGER

## controllers assignment
export (Shift_Up_Controller) var shift_up_controller: int = Shift_Up_Controller.RIGHT
export (Shift_Down_Controller) var shift_down_controller: int = Shift_Down_Controller.LEFT
export (Gas_Controller) var gas_controller: int = Gas_Controller.RIGHT
export (Brake_Controller) var brake_controller: int = Brake_Controller.LEFT

export (NodePath) var l_controller_path = null
export (NodePath) var r_controller_path = null

var _left_controller
var _right_controller

############################################################
# Speed and drive direction

export var MAX_ENGINE_FORCE = 100.0
export var MAX_BRAKE_FORCE = 5.0

export (Array) var gear_ratios = [ 2.69, 2.01, 1.59, 1.32, 1.13, 1.0 ] 
export (float) var reverse_ratio = -2.5
export (float) var final_drive_ratio = 3.38
export (float) var max_engine_rpm = 4000.0
export (Curve) var power_curve = null

var current_gear = 0 # -1 reverse, 0 = neutral, 1 - 6 = gear 1 to 6.
var clutch_position : float = 1.0 # 0.0 = clutch engaged
var current_speed_mps = 0.0
onready var last_pos = translation

var gear_shift_time = 0.3
var gear_timer = 0.0

func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0

# calculate the RPM of our engine based on the current velocity of our car
func calculate_rpm() -> float:
	# if we are in neutral, no rpm
	if current_gear == 0:
		return 0.0
	
	var wheel_circumference : float = 2.0 * PI * $RVehicleWheel.wheel_radius
	var wheel_rotation_speed : float = 60.0 * current_speed_mps / wheel_circumference
	var drive_shaft_rotation_speed : float = wheel_rotation_speed * final_drive_ratio
	if current_gear == -1:
		# we are in reverse
		return drive_shaft_rotation_speed * -reverse_ratio
	elif current_gear <= gear_ratios.size():
		return drive_shaft_rotation_speed * gear_ratios[current_gear - 1]
	else:
		return 0.0

############################################################
# Input

func _ready():
	_left_controller = get_node(l_controller_path)
	_right_controller = get_node(r_controller_path)
	
		# Get the controllers
	if shift_up_controller == Shift_Up_Controller.LEFT:
		_shift_up_controller = _left_controller
	else:
		_shift_up_controller = _right_controller

	
	if shift_down_controller == Shift_Down_Controller.LEFT:
		_shift_down_controller = _left_controller
	else:
		_shift_down_controller = _right_controller
		
	
	if gas_controller == Gas_Controller.LEFT:
		_gas_controller = _left_controller
	else:
		_gas_controller = _right_controller
		
	
	if brake_controller == Brake_Controller.LEFT:
		_brake_controller = _left_controller
	else:
		_brake_controller = _right_controller

	$IdleSound.play()
	

func _process_gear_inputs(delta : float):
	if gear_timer > 0.0:
		gear_timer = max(0.0, gear_timer - delta)
		clutch_position = 0.0
	else:
		if get_shift_down() and current_gear > -1:
			current_gear = current_gear - 1
			gear_timer = gear_shift_time
			clutch_position = 0.0
		elif get_shift_up() and current_gear < gear_ratios.size():
			current_gear = current_gear + 1
			gear_timer = gear_shift_time
			clutch_position = 0.0
		else:
			clutch_position = 1.0

func _process(delta : float):
	_process_gear_inputs(delta)
	
	var speed = get_speed_kph()
	var rpm = calculate_rpm()
	
	var info = 'Speed: %.0f, RPM: %.0f (gear: %d)'  % [ speed, rpm, current_gear ]
	
	$Info.text = info
	
	if speed > 5:
		if $EngineSound.playing == false:
			$IdleSound.stop()
			$EngineSound.play()
			
	elif speed < 5:
		if $IdleSound.playing == false:
			$EngineSound.stop()
			$IdleSound.play()
			
	if speed >= 15:
		steer_lean = true
		
	elif speed < 13:
		steer_lean = false
	#Lean with player head rotation, except for some reason this breaks forward movement
#	lean_val = get_lean_input()
#	if player_is_seated == true:
#		axis_lock_angular_z = false
#		axis_lock_angular_x = false
	#	rotation.z = lerp(rotation.z, lean_val, LEAN_SPEED * delta)
func _integrate_forces(state):
	#	Lean with player head rotation, except for some reason this breaks forward movement
#	lean_val = get_lean_input()
	if player_is_seated == true:
#		axis_lock_angular_z = false
#		axis_lock_angular_x = false
#		if steer_lean == true:
#			axis_lock_angular_z = false
			lean_val = get_lean_input()
#			rotation.z=lerp(rotation.z, lean_val, .9)
			rotation.z = lean_val*1.5
#			angular_velocity = lerp(angular_velocity, -transform.basis.z*lean_val, 0.1)		
#		elif abs(rotation_degrees.z) >= 1:
#			angular_velocity = lerp(angular_velocity, -transform.basis.z*sin(rotation_degrees.z), 0.1)
#		else:
#			angular_velocity.z = 0
#			angular_velocity.x = 0
#			axis_lock_angular_x = true
#			axis_lock_angular_z = true
func _physics_process(delta):
	# how fast are we going in meters per second?
	current_speed_mps = (translation - last_pos).length() / delta
		
	# get our joystick inputs
	var steer_val = get_steering_input()
	var throttle_val = get_throttle_input()
	var brake_val = get_brake_input()
	
	
	var rpm = calculate_rpm()
	var rpm_factor = clamp(rpm / max_engine_rpm, 0.0, 1.0)
	var power_factor = power_curve.interpolate_baked(rpm_factor)
	
	if current_gear == -1:
		engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive_ratio * MAX_ENGINE_FORCE
	elif current_gear > 0 and current_gear <= gear_ratios.size():
		engine_force = clutch_position * throttle_val * power_factor * gear_ratios[current_gear - 1] * final_drive_ratio * MAX_ENGINE_FORCE
	else:
		engine_force = 0.0
	
	brake = brake_val * MAX_BRAKE_FORCE
	

	var max_steer_speed = MAX_STEER_SPEED * 1000.0 / 3600.0
	var steer_speed_factor = clamp(current_speed_mps / max_steer_speed, 0.0, 1.0)

	if (abs(steer_val) < 0.05):
		steer_val = 0.0
	elif steer_curve:
		if steer_val < 0.0:
			steer_val = -steer_curve.interpolate_baked(-steer_val)
		else:
			steer_val = steer_curve.interpolate_baked(steer_val)
	
	steer_angle = steer_val * lerp(max_steer_angle_rad, speed_steer_angle_rad, steer_speed_factor)
	steering = -steer_angle
	
	#Prevent bike from falling down
	if player_is_seated == false:
		angular_velocity.x = 0
		angular_velocity.z = 0
	
	
	#Rotate tire meshes with vehicle tire nodes
	$MotorCycleHandleBars/HingeOrigin/InteractableHinge/WheelBody/HandlebarsAndWheel/FrontWheelMeshOnly.rotation.y = $FVehicleWheel.rotation.x
	$BodyMesh/RearWheelMesh.rotation.y = $RVehicleWheel.rotation.x
	
	# remember where we are
	last_pos = translation

func get_shift_down():
	if player_is_seated == false:
		return false
	if player_is_seated == true:
		
	# Detect press of shift down button
		var old_shift_down_button = _shift_down_button
		_shift_down_button = _shift_down_controller.is_button_pressed(shift_down_button_id)
		if _shift_down_button and !old_shift_down_button:

			if !was_gear_down:
				was_gear_down = true
				return true
		else:
			was_gear_down = false
		return false

func get_shift_up():
	if player_is_seated == false:
		return false
	if player_is_seated == true:

		# Detect press of shift up button
		var old_shift_up_button = _shift_up_button
		_shift_up_button = _shift_up_controller.is_button_pressed(shift_up_button_id)
		if _shift_up_button and !old_shift_up_button:
			if !was_gear_up:
				was_gear_up = true
				return true
		else:
			was_gear_up = false
		return false
		
func get_steering_input():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
		
		if $MotorCycleHandleBars/HingeOrigin/InteractableHinge.hinge_position == 0:
			return 0
		else:
			#use 90 instead of 360 because no one turns handle bars more than degrees on a motorcycle, could also try 90
			return -$MotorCycleHandleBars/HingeOrigin/InteractableHinge.hinge_position/90

func get_throttle_input():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
		if _gas_controller.is_button_pressed(gas_button_id):
			return -1
		else:
			return 0
			
func get_brake_input():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
		if _brake_controller.is_button_pressed(brake_button_id):
			return 1
		else:
			return 0

func get_lean_input():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
#		return $Player/ARVRCamera.rotation.z
#		return $Player/ARVRCamera.transform.basis.z - $Player/ARVRCamera.global_transform.basis.z
#		return $Player/ARVRCamera.transform.basis.z - $Player.transform.basis.z
#		return $Player/ARVRCamera.transform.basis.z - $Player.global_transform.basis.z
		return $Player/ARVRCamera.rotation.z - $Player.rotation.z
	

func _on_EnemyKillZone_body_entered(body):
	
	if body.is_in_group("enemies"):
		body.enemy_alive = false
		body.queue_free()


func _on_CarExitArea_body_entered(body):
	if body.is_in_group("right_hand") or body.is_in_group("left_hand"):
		player_is_seated = false
		emit_signal("bike_exited", self)


func _on_CarEnterArea_body_entered(body):
	if body.is_in_group("right_hand") or body.is_in_group("left_hand"):
		player_is_seated = true
		emit_signal("bike_entered", self)
